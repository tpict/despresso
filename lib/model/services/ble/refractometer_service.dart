import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../service_locator.dart';
import 'ble_service.dart';

enum RefractometerState {
  /// Currently establishing a connection.
  connecting,

  /// Connection is established.
  connected,

  /// Terminating the connection.
  disconnecting,

  /// Device is disconnected.
  disconnected
}

class TempMeassurement {
  double temp1;
  double temp2;
  RefractometerState state;
  double time = 0;
  TempMeassurement(this.temp1, this.temp2, this.state);
}

class RefractometerService extends ChangeNotifier {
  final log = Logger('TRefractometerService');

  // double _temp1 = 0.0;
  // double _temp2 = 0.0;
  int _battery = 0;
  DateTime last = DateTime.now();

  RefractometerState _state = RefractometerState.disconnected;

  DateTime t1 = DateTime.now();

  Stream<TempMeassurement> get stream => _stream;
  Stream<int> get streamBattery => _streamBattery;

  // double get temp1 => _temp1;
  // double get temp2 => _temp2;
  int get battery => _battery;

  RefractometerState get state => _state;

  late StreamController<TempMeassurement> _controller;
  late Stream<TempMeassurement> _stream;

  // AbstractThermometer? tempProbe;

  late StreamController<int> _controllerBattery;
  late Stream<int> _streamBattery;

  RefractometerService() {}

  setState(RefractometerState state) {
    if (state == RefractometerState.connected) {
    } else if (state == RefractometerState.disconnected) {
      setBattery(0);
    }
    _state = state;
    log.info('Refractometer State: $_state');
    // _controller.add(TempMeassurement(_temp1, _temp2, _state));
    notifyListeners();
  }
  // TempService() {
  //   _controller = StreamController<TempMeassurement>();
  //   _stream = _controller.stream.asBroadcastStream();

  //   _controllerBattery = StreamController<int>();
  //   _streamBattery = _controllerBattery.stream.asBroadcastStream();
  // }

  // void setTemp(double temp1, double temp2) {
  //   _temp1 = temp1;
  //   _temp2 = temp2;

  //   // calc flow, cap on 10g/s
  //   var m = TempMeassurement(temp1, temp2, _state);
  //   m.time = DateTime.now().millisecondsSinceEpoch / 1000.0 - _baseTime;
  //   history.add(m);
  //   if (history.length > 200) {
  //     history.removeAt(0);
  //   }
  //   _controller.add(m);
  //   notifyListeners();

  //   _count++;
  //   if (_count % 10 == 0) {
  //     var t = DateTime.now();
  //     var ms = t.difference(t1).inMilliseconds;
  //     var hz = 10 / ms * 1000.0;
  //     log.finer("Temp Hz: $ms $hz");
  //     t1 = t;
  //   }
  // }

  void connect() {
    var bleService = getIt<BLEService>();
    bleService.startScan();
  }

  void setBattery(int batteryLevel) {
    if (batteryLevel == _battery) return;
    _battery = batteryLevel;
    _controllerBattery.add(_battery);
    log.fine("Refractometer battery $_battery");
  }
}
