import 'package:flutter/material.dart';

import '../app_state.dart';
import '../detection/models.dart';
import '../detection/normalizer.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Reports a scam number. Saved locally and queued for the future backend.
class ReportScreen extends StatefulWidget {
  const ReportScreen({
    super.key,
    this.number = '',
    this.category,
    this.message = '',
  });

  final String number;
  final ScamCategory? category;
  final String message;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final _number = TextEditingController(
    text: widget.number.isEmpty ? '' : formatPhone(widget.number),
  );
  late final _message = TextEditingController(text: widget.message);
  late ScamCategory _category = switch (widget.category) {
    null || ScamCategory.blockedByYou => ScamCategory.bisp,
    final c => c,
  };
  bool _sending = false;

  static const _choices = [
    ScamCategory.bisp,
    ScamCategory.bank,
    ScamCategory.prize,
    ScamCategory.official,
    ScamCategory.courier,
    ScamCategory.other,
  ];

  Future<void> _send() async {
    final l = L10n.of(context);
    final n = normalizePhone(_number.text);
    if (n.replaceAll('+', '').length < 4) {
      showToast(context, l.t('enterNumber'));
      return;
    }
    setState(() => _sending = true);
    await AppScope.read(
      context,
    ).report(number: _number.text, category: _category, message: _message.text);
    if (!mounted) return;
    showToast(context, l.t('reportSaved'));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _number.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.t('reportScam'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              l.t('number'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _number,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(hintText: '0300 1234567'),
            ),
            const SizedBox(height: 18),
            Text(
              l.t('pretendedTo'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.1,
              children: [
                for (final c in _choices)
                  _CategoryButton(
                    label: l.category(c),
                    selected: c == _category,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              l.t('messageOptional'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _message,
              minLines: 3,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              l.t('maskNote'),
              style: const TextStyle(fontSize: 12, color: KColors.muted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                l.t('reportPrivacy'),
                style: TextStyle(
                  fontSize: 13,
                  color: KColors.deep,
                  height: l.urdu ? 2 : 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KColors.scam),
              onPressed: _sending ? null : _send,
              child: Text(l.t('sendReport')),
            ),
            const SizedBox(height: 4),
            TextButton(
              // NCCIA complaint portal. Verify the URL before release.
              onPressed: () =>
                  state.bridge.openUrl('https://complaint.nccia.gov.pk/'),
              child: Text(
                l.t('lostMoney'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (state.pendingReports > 0)
              Text(
                l.t('pendingReports', {'n': state.pendingReports}),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: KColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? KColors.mint : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? KColors.green : KColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              color: selected ? KColors.deep : KColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
