import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models.dart';
import 'normalizer.dart';

/// A compiled text rule from the threat set.
class ScamRule {
  ScamRule({
    required this.id,
    required this.category,
    required this.weight,
    required String pattern,
  }) : regex = RegExp(pattern, caseSensitive: false, unicode: true);

  final String id;
  final ScamCategory category;
  final int weight;
  final RegExp regex;
}

class _ListedNumber {
  const _ListedNumber(this.category, this.reports);
  final ScamCategory category;
  final int reports;
}

/// Offline detection: keyed-hash number lookup plus weighted text rules.
///
/// The Kotlin side (`ThreatEngine.kt`) loads the same asset and applies the
/// same logic, so calls and SMS are screened even when Flutter is not running.
class DetectionEngine {
  DetectionEngine._({
    required this.version,
    required List<int> hmacKey,
    required this.scamThreshold,
    required this.suspiciousThreshold,
    required this.trustedSenders,
    required this.trustedDomains,
    required this._numbers,
    required this.rules,
    required this.bankingPackages,
  }) : _hmac = Hmac(sha256, hmacKey);

  factory DetectionEngine.fromJson(String source) {
    final m = jsonDecode(source) as Map<String, dynamic>;
    final numbers = <String, _ListedNumber>{
      for (final n in (m['numbers'] as List).cast<Map<String, dynamic>>())
        n['h'] as String: _ListedNumber(
          categoryFromId(n['category'] as String?),
          (n['reports'] as num?)?.toInt() ?? 0,
        ),
    };
    return DetectionEngine._(
      version: (m['version'] as num).toInt(),
      hmacKey: utf8.encode(m['hmacKey'] as String),
      scamThreshold: (m['scamThreshold'] as num).toInt(),
      suspiciousThreshold: (m['suspiciousThreshold'] as num).toInt(),
      trustedSenders: (m['trustedSenders'] as List).cast<String>().toSet(),
      trustedDomains: (m['trustedDomains'] as List).cast<String>(),
      numbers: numbers,
      rules: [
        for (final r in (m['rules'] as List).cast<Map<String, dynamic>>())
          ScamRule(
            id: r['id'] as String,
            category: categoryFromId(r['category'] as String?),
            weight: (r['weight'] as num).toInt(),
            pattern: r['pattern'] as String,
          ),
      ],
      bankingPackages: (m['bankingPackages'] as List).cast<String>(),
    );
  }

  final int version;
  final int scamThreshold;
  final int suspiciousThreshold;
  final Set<String> trustedSenders;
  final List<String> trustedDomains;
  final List<ScamRule> rules;
  final List<String> bankingPackages;
  final Hmac _hmac;
  final Map<String, _ListedNumber> _numbers;

  static final _urlHost = RegExp(
    r'(?:https?://)?(?:www\.)?([a-z0-9-]+(?:(?:\.|\[\.\])[a-z0-9-]+)+)',
    caseSensitive: false,
  );

  /// HMAC-SHA-256 of the normalised number, as hex.
  String hashNumber(String raw) =>
      _hmac.convert(utf8.encode(normalizePhone(raw))).toString();

  /// Looks up a number. [userBlocked] holds hashes the user blocked.
  Verdict checkNumber(String raw, {Set<String> userBlocked = const {}}) {
    final normalized = normalizePhone(raw);
    // Only the exact official code is trusted; "8171-BISP" is a look-alike.
    if (normalized.isEmpty || trustedSenders.contains(raw.trim())) {
      return Verdict.safe;
    }
    final h = hashNumber(raw);
    if (userBlocked.contains(h)) {
      return Verdict(
        level: RiskLevel.scam,
        score: 100,
        category: ScamCategory.blockedByYou,
        reasons: const ['blocked_by_you'],
        numberListed: true,
      );
    }
    final listed = _numbers[h];
    if (listed == null) return Verdict.safe;
    return Verdict(
      level: RiskLevel.scam,
      score: 100,
      category: listed.category,
      reasons: const ['listed_number'],
      reports: listed.reports,
      numberListed: true,
    );
  }

  /// Scores message text, optionally with its sender.
  Verdict checkMessage(
    String text, {
    String sender = '',
    Set<String> userBlocked = const {},
  }) {
    final byNumber = sender.isEmpty
        ? Verdict.safe
        : checkNumber(sender, userBlocked: userBlocked);
    if (byNumber.level == RiskLevel.scam) return byNumber;

    var score = 0;
    final reasons = <String>[];
    final weightByCategory = <ScamCategory, int>{};
    void hit(String id, ScamCategory c, int w) {
      score += w;
      reasons.add(id);
      weightByCategory[c] = (weightByCategory[c] ?? 0) + w;
    }

    final senderDigits = sender.replaceAll(RegExp(r'[^0-9]'), '');
    for (final code in trustedSenders) {
      if (senderDigits.contains(code) && sender.trim() != code) {
        hit('lookalike_sender', ScamCategory.bisp, 40);
      }
    }

    final linksTrusted = _allLinksTrusted(text);
    for (final rule in rules) {
      if (linksTrusted && (rule.id == 'link' || rule.id == 'risky_domain')) {
        continue;
      }
      if (rule.regex.hasMatch(text)) hit(rule.id, rule.category, rule.weight);
    }

    final level = score >= scamThreshold
        ? RiskLevel.scam
        : score >= suspiciousThreshold
        ? RiskLevel.suspicious
        : RiskLevel.safe;
    ScamCategory? top;
    weightByCategory.remove(ScamCategory.other);
    if (weightByCategory.isNotEmpty) {
      top = weightByCategory.entries
          .reduce((a, b) => b.value > a.value ? b : a)
          .key;
    } else if (score > 0) {
      top = ScamCategory.other;
    }
    return Verdict(
      level: level,
      score: score > 100 ? 100 : score,
      category: level == RiskLevel.safe ? null : top,
      reasons: reasons,
    );
  }

  bool _allLinksTrusted(String text) {
    final hosts = _urlHost
        .allMatches(text)
        .map((m) => m[1]!.toLowerCase().replaceAll('[.]', '.'))
        .where((h) => h.contains('.') && RegExp(r'[a-z]').hasMatch(h))
        .toList();
    if (hosts.isEmpty) return false;
    return hosts.every(
      (h) => trustedDomains.any((d) => h == d || h.endsWith('.$d')),
    );
  }
}
