import 'package:flutter/material.dart';

import '../detection/models.dart';
import '../detection/normalizer.dart';
import '../l10n.dart';
import '../theme.dart';

/// White rounded card with the brand border.
class KCard extends StatelessWidget {
  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = KColors.card,
    this.borderColor = KColors.line,
    this.borderWidth = 1,
    this.radius = 18,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor, width: borderWidth),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small rounded square holding an icon.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.size = 44,
    this.background = KColors.mint,
    this.color = KColors.green,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Icon(icon, color: color, size: size * 0.5),
  );
}

/// SCAM / CHECK pill.
class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key, this.small = false});

  final RiskLevel level;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: KColors.forRisk(level),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level == RiskLevel.scam ? l.t('scamBadge') : l.t('checkBadge'),
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          height: l.urdu ? 1.6 : 1.2,
        ),
      ),
    );
  }
}

/// Section heading.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      ?trailing,
    ],
  );
}

/// One line in the activity list.
class EventTile extends StatelessWidget {
  const EventTile({super.key, required this.event, this.onTap});

  final ShieldEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final color = KColors.forRisk(event.level);
    final IconData icon = switch (event.type) {
      'call' => event.blocked ? Icons.block : Icons.phone_in_talk_outlined,
      'bank_alert' => Icons.account_balance_wallet_outlined,
      _ => Icons.sms_outlined,
    };
    final String title = switch (event.type) {
      'call' => event.blocked ? l.t('evCallBlocked') : l.t('evCallWarned'),
      'bank_alert' => l.t('evBank'),
      _ => l.t('evSms'),
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.number.isEmpty ? title : formatPhone(event.number),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  Text(
                    '$title · ${l.category(event.category)}',
                    style: const TextStyle(fontSize: 12, color: KColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l.ago(event.timestamp),
              style: const TextStyle(fontSize: 12, color: KColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bullet with an icon, used for "Remember" and reasons lists.
class BulletLine extends StatelessWidget {
  const BulletLine(
    this.text, {
    super.key,
    this.color = KColors.scam,
    this.textColor = KColors.ink2,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 7),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: textColor, height: 1.45),
          ),
        ),
      ],
    ),
  );
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
