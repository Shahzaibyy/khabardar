import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for the Kotlin `NativeApi` used by widget tests.
class FakeNative {
  final Map<String, Object?> settings = {};
  final List<Map<String, Object?>> events = [];
  final Set<String> blocked = {};
  final List<Object?> reports = [];
  final List<String> calls = [];

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('pk.khabardar/native'),
      _handle,
    );
    messenger.setMockStreamHandler(
      const EventChannel('pk.khabardar/events'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call.method);
    final args = call.arguments;
    switch (call.method) {
      case 'getPermissionStatus':
        return {
          'callScreening': true,
          'sms': true,
          'notifications': true,
          'overlay': false,
          'usageAccess': false,
          'callScreeningSupported': true,
        };
      case 'getSettings':
        return settings;
      case 'saveSettings':
        settings
          ..clear()
          ..addAll((args as Map).cast<String, Object?>());
        return null;
      case 'getEvents':
        return events;
      case 'getBlockedHashes':
        return blocked.toList();
      case 'blockHash':
        blocked.add((args as Map)['hash'] as String);
        return null;
      case 'unblockHash':
        blocked.remove((args as Map)['hash'] as String);
        return null;
      case 'queueReport':
        reports.add(args);
        return null;
      case 'pendingReportCount':
        return reports.length;
      default:
        return null;
    }
  }
}
