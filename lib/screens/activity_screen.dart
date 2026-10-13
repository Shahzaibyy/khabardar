import 'package:flutter/material.dart';

import '../app_state.dart';
import '../detection/models.dart';
import '../detection/normalizer.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'report_screen.dart';

/// Flagged SMS, warned or blocked calls and banking alerts.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

enum _Filter { sms, calls, all }

class _ActivityScreenState extends State<ActivityScreen> {
  _Filter _filter = _Filter.sms;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final items = state.events.where((e) {
      switch (_filter) {
        case _Filter.sms:
          return e.type == 'sms';
        case _Filter.calls:
          return e.type == 'call' || e.type == 'bank_alert';
        case _Filter.all:
          return true;
      }
    }).toList();

    Widget chip(_Filter f, String label, int count) {
      final selected = _filter == f;
      return ChoiceChip(
        label: Text(count > 0 && f != _Filter.all ? '$label · $count' : label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = f),
        selectedColor: KColors.ink,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? KColors.ink : KColors.line),
        labelStyle: TextStyle(
          color: selected ? Colors.white : KColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        shape: const StadiumBorder(),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.refreshHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              l.t('activity'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                chip(_Filter.sms, l.t('filterSms'), state.countOf('sms')),
                chip(
                  _Filter.calls,
                  l.t('filterCalls'),
                  state.countOf('call') + state.countOf('bank_alert'),
                ),
                chip(_Filter.all, l.t('filterAll'), 0),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              KCard(
                child: Text(
                  l.t('noFlagged'),
                  style: const TextStyle(fontSize: 13, color: KColors.muted),
                ),
              )
            else
              for (final e in items) ...[
                e.type == 'sms' ? _SmsCard(event: e) : _CompactCard(event: e),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.event});

  final ShieldEvent event;

  @override
  Widget build(BuildContext context) => KCard(
    padding: EdgeInsets.zero,
    child: EventTile(
      event: event,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
    ),
  );
}

class _SmsCard extends StatelessWidget {
  const _SmsCard({required this.event});

  final ShieldEvent event;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final scam = event.level == RiskLevel.scam;
    return KCard(
      borderColor: scam ? KColors.scam : KColors.line,
      borderWidth: scam ? 2 : 1,
      radius: 20,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiskBadge(event.level),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatPhone(event.number),
                  textDirection: TextDirection.ltr,
                  textAlign: l.urdu ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                l.ago(event.timestamp),
                style: const TextStyle(fontSize: 12, color: KColors.muted),
              ),
            ],
          ),
          if (event.preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KColors.ground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.preview,
                style: const TextStyle(
                  fontSize: 14,
                  color: KColors.ink2,
                  height: 1.55,
                ),
              ),
            ),
          ],
          if (event.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l.t('whyFlagged'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            for (final r in event.reasons.take(4))
              BulletLine(l.reason(r), color: KColors.forRisk(event.level)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: KColors.scam,
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
                    if (event.number.isNotEmpty) {
                      await state.block(event.number);
                    }
                    await state.deleteEvent(event.id);
                    if (context.mounted) showToast(context, l.t('blocked'));
                  },
                  child: Text(l.t('deleteBlock')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 46),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportScreen(
                        number: event.number,
                        category: event.category,
                        message: event.preview,
                      ),
                    ),
                  ),
                  child: Text(l.t('report')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
