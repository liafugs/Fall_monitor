import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'models/fall_event.dart';
import 'models/imu_data.dart';
import 'services/bluetooth_service.dart';
import 'services/data_processing_service.dart';
import 'services/fall_detection_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/thresholds.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

enum SystemState { idle, normal, possibleFall, fallConfirmed }

/// Orquestra: Bluetooth → processamento → detector → alerta → armazenamento.
class AppController extends ChangeNotifier {
  final bt = BluetoothService();
  final dsp = DataProcessingService();
  final storage = StorageService();
  late Thresholds thresholds;
  late FallDetector detector; // trocável por um detector de ML

  List<FallEvent> events = [];
  bool monitoring = false;
  SystemState sysState = SystemState.idle;
  String? lastError;

  // Alerta
  PossibleFall? alert;
  UserResponse? response;
  int alertSecondsLeft = 0;
  bool alertRouteOpen = false;
  FallEvent? _analyzed;
  Timer? _uiTimer, _responseTimer;

  // Modo de testes
  bool testing = false;
  String testLabel = Constants.testActivities.first;
  final List<IMUData> testSamples = [];
  final List<String> _testLabels = [];
  final Map<int, int> _testFlags = {};

  Future<void> init() async {
    thresholds = await storage.loadThresholds();
    events = await storage.loadEvents();
    _buildDetector();
    bt.imuStream.listen(_onSample);
    bt.stateStream.listen((_) => notifyListeners());
    _uiTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => notifyListeners());
  }

  void _buildDetector() {
    detector = RuleBasedFallDetector(thresholds)
      ..onPossibleFall = _handlePossible
      ..onLog = _handleLog
      ..onEventAnalyzed = _handleAnalyzed;
  }

  void _onSample(IMUData d) {
    final p = dsp.process(d);
    if (testing) {
      testSamples.add(d);
      _testLabels.add(testLabel);
    }
    if (monitoring) detector.process(p);
  }

  // ---------- conexão ----------
  Future<void> connectSensor() async {
    lastError = null;
    try {
      await bt.connect();
    } catch (e) {
      lastError = e.toString();
    }
    notifyListeners();
  }

  Future<void> startSimulation() async {
    lastError = null;
    dsp.clear();
    await bt.startSimulation();
  }

  Future<void> disconnect() async {
    monitoring = false;
    sysState = SystemState.idle;
    await bt.disconnect();
    notifyListeners();
  }

  void toggleMonitoring() {
    detector.reset();
    monitoring = !monitoring;
    sysState = monitoring ? SystemState.normal : SystemState.idle;
    notifyListeners();
  }

  // ---------- detecção / alerta ----------
  void _handleLog(DetectionLog l) {
    if (l.accepted) {
      _testFlags[l.tMs] = 2;
    } else {
      _testFlags.putIfAbsent(l.tMs, () => 1);
    }
  }

  void _handlePossible(PossibleFall p) {
    if (alert != null && response == null) respond(UserResponse.noResponse);
    alert = p;
    response = null;
    _analyzed = null;
    sysState = SystemState.possibleFall;
    alertSecondsLeft = thresholds.responseTimeoutSec.round();
    _responseTimer?.cancel();
    _responseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      alertSecondsLeft--;
      if (alertSecondsLeft <= 0) respond(UserResponse.noResponse);
      notifyListeners();
    });
    if (!alertRouteOpen) {
      alertRouteOpen = true;
      navigatorKey.currentState?.pushNamed('/alert');
    }
    notifyListeners();
  }

  void _handleAnalyzed(FallEvent e) {
    _analyzed = e;
    _tryFinalize();
  }

  /// okay → evento sem escalonamento; needHelp → emergência;
  /// noResponse (timeout) → não confirmado, alerta de nível superior.
  void respond(UserResponse r) {
    if (response != null) return;
    response = r;
    _responseTimer?.cancel();
    sysState = r == UserResponse.okay ? SystemState.normal : SystemState.fallConfirmed;
    if (r != UserResponse.okay) {
      // TODO: envio a contatos externos (SMS/ligação/push) — fase posterior.
    }
    _tryFinalize();
    notifyListeners();
  }

  Future<void> _tryFinalize() async {
    final e = _analyzed;
    final r = response;
    if (e == null || r == null) return;
    _analyzed = null;
    e.response = r;
    events.insert(0, e);
    await storage.saveRaw(e);
    await storage.saveEvents(events);
    notifyListeners();
  }

  void dismissAlert() {
    alert = null;
    alertRouteOpen = false;
    notifyListeners();
  }

  void clearAlertState() {
    sysState = monitoring ? SystemState.normal : SystemState.idle;
    notifyListeners();
  }

  // ---------- ajustes ----------
  Future<void> updateThresholds(Thresholds t) async {
    thresholds = t;
    await storage.saveThresholds(t);
    final was = monitoring;
    _buildDetector();
    monitoring = was;
    notifyListeners();
  }

  // ---------- histórico ----------
  Future<void> shareRaw(FallEvent e) async {
    final path = await storage.rawPath(e.id);
    if (await File(path).exists()) await Share.shareXFiles([XFile(path)]);
  }

  // ---------- testes ----------
  void startTest() {
    testSamples.clear();
    _testLabels.clear();
    _testFlags.clear();
    testing = true;
    notifyListeners();
  }

  void stopTest() {
    testing = false;
    notifyListeners();
  }

  void setTestLabel(String l) {
    testLabel = l;
    notifyListeners();
  }

  void markEvent() {
    if (testSamples.isNotEmpty) _testFlags[testSamples.last.t] = 3;
  }

  Future<void> exportTest() async {
    if (testSamples.isEmpty) return;
    final f = await storage.saveTestSession(testSamples, _testLabels, _testFlags);
    await Share.shareXFiles([XFile(f.path)], text: 'Sessão de teste');
  }
}
