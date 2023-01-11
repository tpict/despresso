import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:despresso/ui/theme.dart' as theme;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:reactive_flutter_rating_bar/reactive_flutter_rating_bar.dart';

import 'package:reactive_forms/reactive_forms.dart';

import '../../model/coffee.dart';
import '../../model/services/ble/machine_service.dart';

class CoffeeSelection {
  Widget getTabContent() {
    return CoffeeSelectionTab();
  }
}

class CoffeeSelectionTab extends StatefulWidget {
  @override
  _CoffeeSelectionTabState createState() => _CoffeeSelectionTabState();
}

enum EditModes { show, add, edit }

class _CoffeeSelectionTabState extends State<CoffeeSelectionTab> {
  final _formKeyRoaster = GlobalKey<FormState>();
  final TextEditingController _typeAheadRoasterController = TextEditingController();
  final TextEditingController _typeAheadCoffeeController = TextEditingController();

  Roaster newRoaster = Roaster();
  Coffee newCoffee = Coffee();
  late Roaster _selectedRoaster;
  late Coffee _selectedCoffee;
  //String _selectedCoffee;

  late CoffeeService coffeeService;
  late EspressoMachineService machineService;

  EditModes _editRosterMode = EditModes.show;
  EditModes _editCoffeeMode = EditModes.show;

  List<DropdownMenuItem<Roaster>> roasters = [];
  List<DropdownMenuItem<Coffee>> coffees = [];

  Roaster _editedRoaster = Roaster();
  Coffee _editedCoffee = Coffee();

  FormGroup get form => fb.group(<String, Object>{
        'name': ['', Validators.required],
        'description': [''],
        'address': [''],
        'homepage': [''],
        'id': [''],
        'intensityRating': [0.1],
        'acidRating': [0],
        'grinderSettings': [0],
      });

  _CoffeeSelectionTabState() {
    newRoaster.name = "<new roaster>";
    newRoaster.id = "new";
    _selectedRoaster = newRoaster;
    newCoffee.name = "<new Coffee>";
    newCoffee.id = "new";
    _selectedCoffee = newCoffee;
  }

  @override
  void initState() {
    super.initState();
    coffeeService = getIt<CoffeeService>();
    machineService = getIt<EspressoMachineService>();
    coffeeService.addListener(updateCoffee);
    updateCoffee();
  }

  @override
  void dispose() {
    super.dispose();
    coffeeService.removeListener(updateCoffee);
    log('Disposed coffeeselection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addCoffee();
        },
        // backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: ReactiveFormBuilder(
        form: () => form,
        builder: (context, form, child) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text("Select Roaster"),
              DropdownButton(
                isExpanded: true,
                alignment: Alignment.centerLeft,
                value: _selectedRoaster,
                items: roasters,
                onChanged: (value) {
                  setState(() {
                    log("Form ${form.value}");
                    _selectedRoaster = value!;
                    if (value!.id == "new") {
                      _editedRoaster = Roaster();

                      form.value = _editedRoaster.toJson();
                      _editRosterMode = EditModes.add;
                    } else {}
                    // form.value = {"name": _selectedRoaster.name};
                    // form.control('name').value = 'John';
                    log("Form ${form.value}");
                  });
                },
              ),
              _editRosterMode != EditModes.show ? roasterForm(form) : roasterData(form),
              const Text("Select Coffee"),
              DropdownButton(
                isExpanded: true,
                alignment: Alignment.centerLeft,
                value: _selectedCoffee,
                items: coffees,
                onChanged: (value) {
                  setState(() {
                    _selectedCoffee = value!;
                    if (value!.id == "new") {
                      _editedCoffee = Coffee();

                      form.value = _editedCoffee.toJson();
                      _editCoffeeMode = EditModes.add;
                    } else {
                      if (_selectedRoaster.id != _selectedCoffee.roasterId) {
                        var found = roasters.where((element) => element.value!.id == _selectedCoffee.roasterId);
                        if (found.isNotEmpty) {
                          _selectedRoaster = found.first.value!;
                        }
                      }
                    }
                    // form.value = {"name": _selectedRoaster.name};
                    // form.control('name').value = 'John';
                    log("Form ${form.value}");
                  });
                },
              ),
              _editCoffeeMode != EditModes.show ? coffeeForm(form) : coffeeData(form),
              Container(
                  color: theme.Colors.backgroundColor,
                  width: 24.0,
                  height: 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0)),
              Row(
                children: <Widget>[
                  const Icon(Icons.location_on, size: 14.0, color: theme.Colors.goodColor),
                  Text(
                    "${_selectedCoffee?.origin ?? 'unknown'}",
                    style: theme.TextStyles.tabTertiary,
                  ),
                  Container(width: 24.0),
                  const Icon(Icons.flight_land, size: 14.0, color: theme.Colors.goodColor),
                  Text("${_selectedCoffee?.price}", style: theme.TextStyles.tabTertiary),
                ],
              ),
            ],
          ),
        ),
      )!,
    );
  }

  List<DropdownMenuItem<Roaster>> loadRoasters() {
    var roasters = coffeeService.knownRoasters
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.name}"),
            ))
        .toList();
    roasters.insert(0, DropdownMenuItem(value: newRoaster, child: Text("${newRoaster.name}")));
    return roasters;
  }

  List<DropdownMenuItem<Coffee>> loadCoffees() {
    var coffees = coffeeService.knownCoffees
        .map((p) => DropdownMenuItem(
              value: p,
              child: Text("${p.name}"),
            ))
        .toList();
    coffees.insert(0, DropdownMenuItem(value: newCoffee, child: Text("${newCoffee.name}")));
    return coffees;
  }

  Future<void> addCoffee() async {
    var r = Roaster();
    r.name = "Bärista";
    r.description = "Small little company in the middle of Berlin";
    r.address = "Franklinstr. 21, Berlin";
    r.homepage = "https://www.google.com";
    await coffeeService.addRoaster(r);
    var c = Coffee();
    c.roasterId = r.id;
    c.name = "Bärige Mischung";
    c.acidRating = 5;
    c.arabica = 50;
    c.robusta = 50;
    c.grinderSettings = 10;
    c.description = "Cheap supermarket coffee";
    c.intensityRating = 5;
    c.roastLevel = 5;
    c.price = "20€";
    c.origin = "Columbia";
    await coffeeService.addCoffee(c);
  }

  roasterData(FormGroup form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        createKeyValue("Name", _selectedRoaster.name),
        if (_selectedRoaster.description.isNotEmpty) createKeyValue("Description", _selectedRoaster.description),
        if (_selectedRoaster.homepage.isNotEmpty) createKeyValue("Homepage", _selectedRoaster.homepage),
        if (_selectedRoaster.address.isNotEmpty) createKeyValue("Address", _selectedRoaster.address),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _editRosterMode = EditModes.edit;
              _editedRoaster = _selectedRoaster;
              form.value = _editedRoaster.toJson();
            });
          },
          child: const Text('EDIT'),
        ),
      ],
    );
  }

  coffeeData(FormGroup form) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        createKeyValue("Name", _selectedCoffee.name),
        if (_selectedCoffee.description.isNotEmpty) createKeyValue("Description", _selectedCoffee.description),
        createKeyValue("Grinder", _selectedCoffee.grinderSettings.toString()),
        createKeyValue("Acidity", _selectedCoffee.acidRating.toString()),
        createKeyValue("Intensity", _selectedCoffee.intensityRating.toString()),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _editCoffeeMode = EditModes.edit;
              _editedCoffee = _selectedCoffee;
              form.value = _editedCoffee.toJson();
            });
          },
          child: const Text('EDIT'),
        ),
      ],
    );
  }

  Widget createKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(key, style: theme.TextStyles.tabHeading),
          Text(value, style: theme.TextStyles.tabPrimary),
        ],
      ),
    );
  }

  roasterForm(FormGroup form) {
    return Column(
      children: [
        ReactiveTextField<String>(
          formControlName: 'name',
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          validationMessages: {
            ValidationMessage.required: (_) => 'Name must not be empty',
          },
        ),
        ReactiveTextField<String>(
          formControlName: 'description',
          decoration: const InputDecoration(
            labelText: 'Description',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'address',
          decoration: const InputDecoration(
            labelText: 'Address',
          ),
        ),
        ReactiveTextField<String>(
          formControlName: 'homepage',
          decoration: const InputDecoration(
            labelText: 'Homepage',
          ),
        ),
        ReactiveFormConsumer(
          builder: (context, form, child) {
            return ElevatedButton(
              onPressed: form.valid
                  ? () {
                      log("${form.value}");
                      _editedRoaster = Roaster.fromJson(form.value);
                      if (_editRosterMode == EditModes.add) {
                        coffeeService.addRoaster(_editedRoaster);
                      } else {
                        coffeeService.updateRoaster(_editedRoaster);
                      }
                      _selectedRoaster = _editedRoaster;
                      _editRosterMode = EditModes.show;
                    }
                  : null,
              child: const Text('SAVE'),
            );
          },
        ),
        ElevatedButton(
          onPressed: () {
            form.reset();
            setState(() {
              _editRosterMode = EditModes.show;
            });
          },
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  coffeeForm(FormGroup form) {
    return Column(
      children: [
        ReactiveTextField<String>(
          formControlName: 'name',
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          validationMessages: {
            ValidationMessage.required: (_) => 'Name must not be empty',
          },
        ),
        ReactiveTextField<String>(
          formControlName: 'description',
          decoration: const InputDecoration(
            labelText: 'Description',
          ),
        ),
        ReactiveTextField<int>(
          formControlName: 'grinderSettings',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Grinder',
          ),
        ),
        ReactiveTextField<int>(
          formControlName: 'acidRating',
          decoration: const InputDecoration(
            labelText: 'Acidity',
          ),
        ),
        ReactiveRatingBarBuilder<double>(
          formControlName: 'intensityRating',
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: true,
          itemCount: 5,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
        ),
        ReactiveTextField<int>(
          formControlName: 'intensityRating',
          decoration: const InputDecoration(
            labelText: 'Intensity',
          ),
        ),
        ReactiveFormConsumer(
          builder: (context, form, child) {
            return ElevatedButton(
              onPressed: form.valid
                  ? () {
                      log("${form.value}");
                      _editedCoffee = Coffee.fromJson(form.value);
                      if (_editCoffeeMode == EditModes.add) {
                        coffeeService.addCoffee(_editedCoffee);
                      } else {
                        coffeeService.updateCoffee(_editedCoffee);
                      }
                      _editedCoffee.roasterId = _selectedRoaster.id;
                      _selectedCoffee = _editedCoffee;
                      _editCoffeeMode = EditModes.show;
                    }
                  : null,
              child: const Text('SAVE'),
            );
          },
        ),
        ElevatedButton(
          onPressed: () {
            form.reset();
            setState(() {
              _editCoffeeMode = EditModes.show;
            });
          },
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  void updateCoffee() {
    setState(
      () {
        roasters = loadRoasters();
        coffees = loadCoffees();
      },
    );
  }
}
