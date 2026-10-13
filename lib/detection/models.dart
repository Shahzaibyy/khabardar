/// Shared types for the on-device detection engine.
library;

enum RiskLevel { safe, suspicious, scam }

enum ScamCategory { bisp, bank, prize, official, courier, other, blockedByYou }

ScamCategory categoryFromId(String? id) {
  switch (id) {
    case 'bisp':
      return ScamCategory.bisp;
    case 'bank':
      return ScamCategory.bank;
    case 'prize':
      return ScamCategory.prize;
    case 'official':
      return ScamCategory.official;
    case 'courier':
      return ScamCategory.courier;
    case 'blocked_by_you':
      return ScamCategory.blockedByYou;
    default:
      return ScamCategory.other;
  }
}

String categoryToId(ScamCategory c) {
  switch (c) {
    case ScamCategory.blockedByYou:
      return 'blocked_by_you';
    default:
      return c.name;
  }
}

RiskLevel riskFromId(String? id) {
  switch (id) {
    case 'scam':
      return RiskLevel.scam;
    case 'suspicious':
      return RiskLevel.suspicious;
    default:
      return RiskLevel.safe;
  }
}

/// The result of checking a number, a message, or both.
class Verdict {
  const Verdict({
    required this.level,
    required this.score,
    this.category,
    this.reasons = const [],
    this.reports = 0,
    this.numberListed = false,
  });

  final RiskLevel level;
  final int score;
  final ScamCategory? category;

  /// Rule ids that matched, used to show "Why Khabardar flagged this".
  final List<String> reasons;

  /// Community reports for a listed number (0 if unknown).
  final int reports;
  final bool numberListed;

  static const safe = Verdict(level: RiskLevel.safe, score: 0);
}

/// One thing the shield caught, as stored on the device by the native side.
class ShieldEvent {
  const ShieldEvent({
    required this.id,
    required this.type,
    required this.number,
    required this.level,
    required this.category,
    required this.timestamp,
    this.preview = '',
    this.reasons = const [],
    this.blocked = false,
  });

  final String id;

  /// `call`, `sms` or `bank_alert`.
  final String type;
  final String number;
  final RiskLevel level;
  final ScamCategory category;
  final DateTime timestamp;

  /// Masked SMS text (OTPs, CNICs and account numbers removed).
  final String preview;
  final List<String> reasons;
  final bool blocked;

  factory ShieldEvent.fromMap(Map<dynamic, dynamic> m) => ShieldEvent(
    id: '${m['id']}',
    type: '${m['type']}',
    number: '${m['number'] ?? ''}',
    level: riskFromId(m['level'] as String?),
    category: categoryFromId(m['category'] as String?),
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      (m['timestamp'] as num?)?.toInt() ?? 0,
    ),
    preview: '${m['preview'] ?? ''}',
    reasons: ((m['reasons'] as List?) ?? const []).map((e) => '$e').toList(),
    blocked: m['blocked'] == true,
  );
}
