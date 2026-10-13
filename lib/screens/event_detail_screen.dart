import 'package:flutter/material.dart';

import '../app_state.dart';
import '../detection/models.dart';
import '../detection/normalizer.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'report_screen.dart';

/// Full warning for one caught call, SMS or banking alert.
///
/// Opened from the alert notification or from the activity list.
class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final ShieldEvent event;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final e = event;
    final blocked = e.number.isNotEmpty && state.isBlocked(e.number);
    final reports = state.engine?.checkNumber(e.number).reports ?? 0;

    final kind = switch (e.type) {
      'call' => l.t('callAlert'),
      'bank_alert' => l.t('bankAlertTitle'),
      _ => l.t('smsAlert'),
    };
    final headline = switch (e.type) {
      'call' => l.t('likelyScamCall'),
      'bank_alert' => l.t('bankAlertTitle'),
      _ => l.t('likelyScamSms'),
    };
    final body = e.type == 'bank_alert'
        ? l.t('bankAlertBody')
        : e.category == ScamCategory.blockedByYou
        ? l.t('callBodyBlocked')
        : l.t('callBody', {'category': l.category(e.category), 'n': reports});

    return Scaffold(
      backgroundColor: KColors.callDark,
      appBar: AppBar(
        backgroundColor: KColors.callDark,
        foregroundColor: Colors.white,
        title: Text(kind, style: const TextStyle(fontSize: 15)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Center(
              child: Text(
                e.number.isEmpty ? '' : formatPhone(e.number),
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Center(
              child: Text(
                l.ago(e.timestamp),
                style: const TextStyle(color: KColors.callMuted, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KColors.forRisk(e.level),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      KhabardarLogo.onColor(
                        size: 44,
                        mark: KColors.forRisk(e.level),
                        dot: KColors.forRisk(e.level),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          headline,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: l.urdu ? 2 : 1.5,
                    ),
                  ),
                  if (e.blocked) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.t('callBlockedNote'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'ہوشیار! کسی کو بھی اپنا او ٹی پی یا پن نہ بتائیں۔',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: kUrduFont,
                        color: Colors.white,
                        fontSize: 17,
                        height: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (e.preview.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1C18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  e.preview,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              e.reasons.isEmpty ? l.t('remember') : l.t('whyFlagged'),
              style: const TextStyle(
                color: KColors.callMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (final r in e.reasons)
              BulletLine(
                l.reason(r),
                color: const Color(0xFFF59E62),
                textColor: Colors.white,
              ),
            BulletLine(
              l.t('bankNeverOtp'),
              color: const Color(0xFFF59E62),
              textColor: Colors.white,
            ),
            BulletLine(
              l.t('bispNoFee'),
              color: const Color(0xFFF59E62),
              textColor: Colors.white,
            ),
            const SizedBox(height: 28),
            if (e.number.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: blocked
                            ? const Color(0xFF2A1C18)
                            : const Color(0xFFDC2626),
                      ),
                      onPressed: () async {
                        if (blocked) {
                          await state.unblock(e.number);
                        } else {
                          await state.block(e.number);
                          if (context.mounted) {
                            showToast(context, l.t('blocked'));
                          }
                        }
                      },
                      icon: Icon(blocked ? Icons.undo : Icons.block),
                      label: Text(
                        blocked ? l.t('unblock') : l.t('blockNumber'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF5A4740)),
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportScreen(
                            number: e.number,
                            category: e.category,
                            message: e.preview,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(l.t('report')),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(
                l.t('done'),
                style: const TextStyle(
                  color: KColors.callMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
