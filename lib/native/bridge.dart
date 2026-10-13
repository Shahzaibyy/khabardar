import 'dart:async';

import 'package:flutter/services.dart';

import '../detection/models.dart';

/// Which shield permissions the user has granted on this phone.
class PermissionStatus {
  const PermissionStatus({
    this.callScreening = false,
    this.sms = false,
    this.notifications = false,
    this.overlay = false,
    this.usageAccess = false,
    this.callScreeningSupported = true,
  });

  final bool callScreening;
  final bool sms;
  final bool notifications;
  final bool overlay;
  final bool usageAccess;

  /// Call screening needs Android 10 or newer.
  final bool callScreeningSupported;

  bool get bankingAlerts => overlay && usageAccess;
  bool get allCore => callScreening && sms && notifications;

  factory PermissionStatus.fromMap(Map<dynamic, dynamic> m) => PermissionStatus(
    callScreening: m['callScreening'] == true,
    sms: m['sms'] == true,
    notifications: m['notifications'] == true,
    overlay: m['overlay'] == true,
    usageAccess: m['usageAccess'] == true,
    callScreeningSupported: m['callScreeningSupported'] != false,
  );
}

/// User settings. Stored natively so background services can read them.
class ShieldSettings {
  const ShieldSettings({
    this.blockScamCalls = true,
    this.warnSuspiciousCalls = true,
    this.smsShield = true,
    this.bankingAlerts = true,
    this.wifiOnlyUpdates = false,
    this.language = 'en',
    this.onboarded = false,
  });

  final bool blockScamCalls;
  final bool warnSuspiciousCalls;
  final bool smsShield;
  final bool bankingAlerts;
  final bool wifiOnlyUpdates;
  final String language;
  final bool onboarded;

  ShieldSettings copyWith({
    bool? blockScamCalls,
    bool? warnSuspiciousCalls,
    bool? smsShield,
    bool? bankingAlerts,
    bool? wifiOnlyUpdates,
    String? language,
    bool? onboarded,
  }) => ShieldSettings(
    blockScamCalls: blockScamCalls ?? this.blockScamCalls,
    warnSuspiciousCalls: warnSuspiciousCalls ?? this.warnSuspiciousCalls,
    smsShield: smsShield ?? this.smsShield,
    bankingAlerts: bankingAlerts ?? this.bankingAlerts,
    wifiOnlyUpdates: wifiOnlyUpdates ?? this.wifiOnlyUpdates,
    language: language ?? this.language,
    onboarded: onboarded ?? this.onboarded,
  );

  Map<String, Object> toMap() => {
    'blockScamCalls': blockScamCalls,
    'warnSuspiciousCalls': warnSuspiciousCalls,
    'smsShield': smsShield,
    'bankingAlerts': bankingAlerts,
    'wifiOnlyUpdates': wifiOnlyUpdates,
    'language': language,
    'onboarded': onboarded,
  };

  factory ShieldSettings.fromMap(Map<dynamic, dynamic> m) => ShieldSettings(
    blockScamCalls: m['blockScamCalls'] != false,
    warnSuspiciousCalls: m['warnSuspiciousCalls'] != false,
    smsShield: m['smsShield'] != false,
    bankingAlerts: m['bankingAlerts'] != false,
    wifiOnlyUpdates: m['wifiOnlyUpdates'] == true,
    language: (m['language'] as String?) ?? 'en',
    onboarded: m['onboarded'] == true,
  );
}

/// A scam report waiting for the backend (sync is not built yet).
class PendingReport {
  const PendingReport({
    required this.numberHash,
    required this.category,
    required this.maskedMessage,
    required this.createdAt,
  });

  final String numberHash;
  final String category;
  final String maskedMessage;
  final DateTime createdAt;

  Map<String, Object> toMap() => {
    'numberHash': numberHash,
    'category': category,
    'maskedMessage': maskedMessage,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}

/// Talks to the Kotlin side (`NativeApi.kt`) over platform channels.
///
/// Every call is wrapped so the UI still works (with defaults) when the
/// native side is missing, for example in widget tests.
class NativeBridge {
  NativeBridge({MethodChannel? channel, EventChannel? events})
    : _channel = channel ?? const MethodChannel('pk.khabardar/native'),
      _events = events ?? const EventChannel('pk.khabardar/events');

  final MethodChannel _channel;
  final EventChannel _events;

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// New shield events pushed live from the native side.
  Stream<ShieldEvent> get eventStream {
    try {
      return _events.receiveBroadcastStream().map(
        (e) => ShieldEvent.fromMap(e as Map<dynamic, dynamic>),
      );
    } on MissingPluginException {
      return const Stream.empty();
    }
  }

  Future<PermissionStatus> permissions() async {
    final m = await _call<Map<dynamic, dynamic>>('getPermissionStatus');
    return m == null ? const PermissionStatus() : PermissionStatus.fromMap(m);
  }

  Future<void> requestCallScreening() => _call('requestCallScreeningRole');
  Future<void> requestSms() => _call('requestSmsPermission');
  Future<void> requestNotifications() => _call('requestNotificationPermission');
  Future<void> requestOverlay() => _call('openOverlaySettings');
  Future<void> requestUsageAccess() => _call('openUsageAccessSettings');

  Future<ShieldSettings> settings() async {
    final m = await _call<Map<dynamic, dynamic>>('getSettings');
    return m == null ? const ShieldSettings() : ShieldSettings.fromMap(m);
  }

  Future<void> saveSettings(ShieldSettings s) =>
      _call('saveSettings', s.toMap());

  Future<List<ShieldEvent>> events() async {
    final list = await _call<List<dynamic>>('getEvents');
    if (list == null) return const [];
    return list
        .map((e) => ShieldEvent.fromMap(e as Map<dynamic, dynamic>))
        .toList();
  }

  Future<void> deleteEvent(String id) => _call('deleteEvent', {'id': id});

  Future<Set<String>> blockedHashes() async {
    final list = await _call<List<dynamic>>('getBlockedHashes');
    return list == null ? <String>{} : list.map((e) => '$e').toSet();
  }

  Future<void> blockHash(String hash) => _call('blockHash', {'hash': hash});
  Future<void> unblockHash(String hash) => _call('unblockHash', {'hash': hash});

  Future<void> queueReport(PendingReport r) => _call('queueReport', r.toMap());
  Future<int> pendingReportCount() async =>
      await _call<int>('pendingReportCount') ?? 0;

  /// Deletes events, blocks, reports and settings stored on this phone.
  Future<void> deleteAllData() => _call('deleteAllData');

  /// The event that opened the app from a notification, if any.
  Future<ShieldEvent?> launchEvent() async {
    final m = await _call<Map<dynamic, dynamic>>('consumeLaunchEvent');
    return m == null ? null : ShieldEvent.fromMap(m);
  }

  Future<void> showTestBankingAlert() => _call('showTestBankingAlert');
  Future<void> showTestCallAlert() => _call('showTestCallAlert');
  Future<void> dial(String number) => _call('dial', {'number': number});
  Future<void> shareText(String text) => _call('shareText', {'text': text});
  Future<void> openUrl(String url) => _call('openUrl', {'url': url});
}
