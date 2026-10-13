import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'detection/engine.dart';
import 'detection/masking.dart';
import 'detection/models.dart';
import 'native/bridge.dart';

/// App-wide state: the detection engine, settings, permissions and history.
class AppState extends ChangeNotifier {
  AppState({NativeBridge? bridge, AssetBundle? bundle})
    : bridge = bridge ?? NativeBridge(),
      _bundle = bundle ?? rootBundle;

  final NativeBridge bridge;
  final AssetBundle _bundle;

  DetectionEngine? engine;
  ShieldSettings settings = const ShieldSettings();
  PermissionStatus permissions = const PermissionStatus();
  List<ShieldEvent> events = const [];
  Set<String> blockedHashes = {};
  int pendingReports = 0;
  bool ready = false;

  /// Set when the app was opened from an alert notification.
  ShieldEvent? launchEvent;

  StreamSubscription<ShieldEvent>? _sub;

  Future<void> init() async {
    final json = await _bundle.loadString(
      'assets/threat/threat_set.json',
      cache: false,
    );
    engine = DetectionEngine.fromJson(json);
    settings = await bridge.settings();
    await Future.wait([refreshPermissions(), refreshHistory()]);
    launchEvent = await bridge.launchEvent();
    _sub = bridge.eventStream.listen((e) {
      events = [e, ...events.where((x) => x.id != e.id)];
      notifyListeners();
    }, onError: (_) {});
    ready = true;
    notifyListeners();
  }

  Future<void> refreshPermissions() async {
    permissions = await bridge.permissions();
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    events = await bridge.events();
    blockedHashes = await bridge.blockedHashes();
    pendingReports = await bridge.pendingReportCount();
    notifyListeners();
  }

  Future<void> updateSettings(ShieldSettings s) async {
    settings = s;
    notifyListeners();
    await bridge.saveSettings(s);
  }

  int countOf(String type, {bool? blocked}) => events
      .where((e) => e.type == type && (blocked == null || e.blocked == blocked))
      .length;

  bool isBlocked(String number) =>
      engine != null && blockedHashes.contains(engine!.hashNumber(number));

  Future<void> block(String number) async {
    final h = engine!.hashNumber(number);
    blockedHashes = {...blockedHashes, h};
    notifyListeners();
    await bridge.blockHash(h);
  }

  Future<void> unblock(String number) async {
    final h = engine!.hashNumber(number);
    blockedHashes = {...blockedHashes}..remove(h);
    notifyListeners();
    await bridge.unblockHash(h);
  }

  Future<void> deleteEvent(String id) async {
    events = events.where((e) => e.id != id).toList();
    notifyListeners();
    await bridge.deleteEvent(id);
  }

  /// Saves a report locally (masked, hashed) and blocks the number.
  Future<void> report({
    required String number,
    required ScamCategory category,
    String message = '',
  }) async {
    await block(number);
    await bridge.queueReport(
      PendingReport(
        numberHash: engine!.hashNumber(number),
        category: categoryToId(category),
        maskedMessage: maskSensitive(message),
        createdAt: DateTime.now(),
      ),
    );
    pendingReports = await bridge.pendingReportCount();
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    await bridge.deleteAllData();
    events = const [];
    blockedHashes = {};
    pendingReports = 0;
    settings = settings.copyWith(onboarded: true);
    await bridge.saveSettings(settings);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Makes [AppState] available to the widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
