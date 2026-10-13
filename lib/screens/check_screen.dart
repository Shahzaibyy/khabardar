import 'package:flutter/material.dart';

import '../app_state.dart';
import '../detection/models.dart';
import '../detection/normalizer.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Checks a number, a link or a pasted message against the offline engine.
class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  final _input = TextEditingController();
  Verdict? _verdict;
  String _checked = '';
  bool _isNumber = false;

  static final _phoneLike = RegExp(r'^[+\d\s\-()]{4,20}$');

  void _check() {
    final state = AppScope.read(context);
    final text = _input.text.trim();
    if (text.isEmpty || state.engine == null) return;
    FocusScope.of(context).unfocus();
    final isNumber = _phoneLike.hasMatch(text);
    setState(() {
      _checked = text;
      _isNumber = isNumber;
      _verdict = isNumber
          ? state.engine!.checkNumber(text, userBlocked: state.blockedHashes)
          : state.engine!.checkMessage(text, userBlocked: state.blockedHashes);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l.t('checkTitle'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: l.urdu ? 1.9 : 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.t('checkBody'),
            style: TextStyle(
              fontSize: 14,
              color: KColors.ink2,
              height: l.urdu ? 2 : 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.t('checkLabel'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _input,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _check(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(hintText: '0300 1234567'),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _check, child: Text(l.t('check'))),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 14, color: KColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.t('checkPrivacy'),
                  style: const TextStyle(fontSize: 12, color: KColors.muted),
                ),
              ),
            ],
          ),
          if (_verdict != null) ...[
            const SizedBox(height: 16),
            _ResultCard(
              verdict: _verdict!,
              input: _checked,
              isNumber: _isNumber,
            ),
          ],
          const SizedBox(height: 20),
          Text(
            l.t('officialNumbers'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _OfficialRow(l.t('bispSms'), '8171', highlight: true),
                const Divider(height: 1, color: KColors.lineSoft),
                _OfficialRow(l.t('bankHelpline'), l.t('backOfCard')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficialRow extends StatelessWidget {
  const _OfficialRow(this.label, this.value, {this.highlight = false});

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
            color: highlight ? KColors.green : KColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.verdict,
    required this.input,
    required this.isNumber,
  });

  final Verdict verdict;
  final String input;
  final bool isNumber;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final v = verdict;
    final color = KColors.forRisk(v.level);
    final title = switch (v.level) {
      RiskLevel.scam => isNumber ? l.t('scamNumber') : l.t('likelyScam'),
      RiskLevel.suspicious => l.t('beCareful'),
      RiskLevel.safe => l.t('noRisk'),
    };
    final subtitle = v.numberListed
        ? l.t('highConfidence')
        : l.t('riskScore', {'s': v.score});
    final blocked = isNumber && state.isBlocked(input);

    return KCard(
      padding: EdgeInsets.zero,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  v.level == RiskLevel.safe
                      ? Icons.verified_outlined
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (v.level == RiskLevel.safe)
                  Text(
                    l.t('noRiskBody'),
                    style: TextStyle(
                      fontSize: 14,
                      color: KColors.ink2,
                      height: l.urdu ? 2 : 1.5,
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _Fact(l.t('scamType'), l.category(v.category)),
                      ),
                      if (v.reports > 0) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Fact(
                            l.t('reports'),
                            l.t('peopleN', {'n': v.reports}),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.t('whyFlagged'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final r in v.reasons)
                    BulletLine(l.reason(r), color: color),
                ],
                if (isNumber && normalizePhone(input).isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: KColors.ink,
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onPressed: () async {
                            if (blocked) {
                              await state.unblock(input);
                            } else {
                              await state.block(input);
                              if (context.mounted) {
                                showToast(context, l.t('blocked'));
                              }
                            }
                          },
                          child: Text(
                            blocked ? l.t('unblock') : l.t('blockNumber'),
                          ),
                        ),
                      ),
                      if (v.level != RiskLevel.safe) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 46),
                            ),
                            onPressed: () => state.bridge.shareText(
                              l.t('shareText', {
                                'number': formatPhone(input),
                                'category': l.category(v.category),
                              }),
                            ),
                            child: Text(l.t('shareWarning')),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: KColors.ground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: KColors.muted)),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
