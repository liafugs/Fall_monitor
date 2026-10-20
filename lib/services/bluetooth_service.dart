import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/imu_data.dart';
import '../utils/constants.dart';

enum ConnState { disconnected, scanning, connecting, connected, simulating }

/// Protocolo esperado do ESP32: notificações BLE em texto UTF-8, uma amostra por
/// notificação: "ax,ay,az,gx,gy,gz" (g e °/s), '\n' opcional.
class BluetoothService {
  final _imuCtrl = StreamController<IMUData>.broadcast();
  final _stateCtrl = StreamController<ConnState>.broadcast();
  Stream<IMUData> get imuStream => _imuCtrl.stream;
  Stream<ConnState> get stateStream => _stateCtrl.stream;

  ConnState state = ConnState.disconnected;
  String deviceName = '—';

  fbp.BluetoothDevice? _device;
  StreamSubscription? _scanSub, _notifySub, _connSub;
  Timer? _simTimer;

  void _setState(ConnState s) {
    state = s;
    _stateCtrl.add(s);
  }

  Future<void> connect() async {
    await disconnect();
    try {
      await fbp.FlutterBluePlus.adapterState
          .where((s) => s == fbp.BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      throw 'Bluetooth desligado ou indisponível.';
    }
    _setState(ConnState.scanning);
    final found = Completer<fbp.BluetoothDevice?>();
    _scanSub = fbp.FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName;
        if (name.startsWith(Constants.deviceNamePrefix) && !found.isCompleted) {
          found.complete(r.device);
        }
      }
    });
    fbp.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    final dev = await found.future
        .timeout(const Duration(seconds: 11), onTimeout: () => null);
    await fbp.FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    if (dev == null) {
      _setState(ConnState.disconnected);
      throw 'Sensor "${Constants.deviceNamePrefix}*" não encontrado.';
    }
    try {
      _setState(ConnState.connecting);
      await dev.connect(timeout: const Duration(seconds: 15));
      if (Platform.isAndroid) await dev.requestMtu(185);
      _device = dev;
      deviceName = dev.platformName.isEmpty ? dev.remoteId.str : dev.platformName;
      _connSub = dev.connectionState.listen((s) {
        if (s == fbp.BluetoothConnectionState.disconnected &&
            state == ConnState.connected) {
          _setState(ConnState.disconnected);
        }
      });
      bool ok = false;
      for (final svc in await dev.discoverServices()) {
        if (svc.uuid.str128.toLowerCase() != Constants.serviceUuid) continue;
        for (final c in svc.characteristics) {
          if (c.uuid.str128.toLowerCase() == Constants.characteristicUuid) {
            await c.setNotifyValue(true);
            _notifySub = c.onValueReceived.listen(_onBytes);
            ok = true;
          }
        }
      }
      if (!ok) throw 'Característica de dados não encontrada no sensor.';
      _setState(ConnState.connected);
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  void _onBytes(List<int> bytes) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final line in utf8.decode(bytes, allowMalformed: true).split('\n')) {
      if (line.trim().isEmpty) continue;
      final d = IMUData.tryParse(line, now);
      if (d != null) _imuCtrl.add(d);
    }
  }

  Future<void> disconnect() async {
    _simTimer?.cancel();
    _simTimer = null;
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _scanSub?.cancel();
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    deviceName = '—';
    _setState(ConnState.disconnected);
  }

  /// Simulador (sem hardware): caminha, cai aos 8 s do ciclo de 40 s,
  /// fica ~19 s imóvel deitado e volta a caminhar.
  Future<void> startSimulation() async {
    await disconnect();
    deviceName = 'Simulador';
    _setState(ConnState.simulating);
    final rnd = Random();
    int n = 0;
    double noise() => (rnd.nextDouble() - 0.5) * 0.04;
    _simTimer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ Constants.simulationHz), (_) {
      final ph = (n++ / Constants.simulationHz) % 40;
      double ax = 0, ay = 0, az = 1, gx = 0, gy = 0, gz = 0;
      if (ph < 8 || ph >= 28) {
        final w = 2 * pi * 1.8 * ph;
        az = 1 + 0.35 * sin(w);
        ax = 0.15 * sin(w / 2);
        ay = 0.1 * cos(w);
        gx = 40 * sin(w);
        gy = 30 * cos(w);
        gz = 10 * sin(w / 2);
      } else if (ph < 8.3) {
        az = 0.2; // queda livre
      } else if (ph < 8.4) {
        ax = 2; az = 4.5; gx = 500; gy = 300; gz = 200; // impacto
      } else if (ph < 9) {
        ax = 0.8; ay = 0.3; az = 0.5; gx = 150; gy = 100; // rolamento
      } else {
        ax = 1; az = 0; // deitado
      }
      final t = DateTime.now().millisecondsSinceEpoch;
      _imuCtrl.add(IMUData(
          t: t,
          ax: ax + noise(), ay: ay + noise(), az: az + noise(),
          gx: gx + noise() * 50, gy: gy + noise() * 50, gz: gz + noise() * 50));
    });
  }
}
