import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_button.dart';
import '../qio_responsive_body.dart';

class CreateQueueKeepAlive extends StatefulWidget {
  const CreateQueueKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<CreateQueueKeepAlive> createState() => _CreateQueueKeepAliveState();
}

class _CreateQueueKeepAliveState extends State<CreateQueueKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class CreateQueueProgress extends StatelessWidget {
  const CreateQueueProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.cqStepOf(current, total),
      child: ExcludeSemantics(
        child: LinearProgressIndicator(
          value: current / total,
          minHeight: 4,
          color: QioColors.primary,
          backgroundColor: context.qio.gray200,
        ),
      ),
    );
  }
}

class CreateQueueStepPage extends StatelessWidget {
  const CreateQueueStepPage({
    super.key,
    required this.title,
    this.hint,
    required this.children,
  });

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: QioResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: context.qioText.heading2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.qio.textPrimary,
                ),
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(hint!, style: context.qioText.body),
            ],
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class CreateQueueFooter extends StatelessWidget {
  const CreateQueueFooter({
    super.key,
    required this.primaryKey,
    required this.primaryLabel,
    required this.onPrimary,
    this.isLoading = false,
    this.secondaryKey,
    this.secondaryLabel,
    this.onSecondary,
  });

  final Key primaryKey;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool isLoading;
  final Key? secondaryKey;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.qio.surface,
        border: Border(top: BorderSide(color: context.qio.gray200)),
      ),
      child: SafeArea(
        top: false,
        child: QioResponsiveBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QioButton(
                  key: primaryKey,
                  label: primaryLabel,
                  onPressed: onPrimary,
                  isLoading: isLoading,
                  isFullWidth: true,
                ),
                const SizedBox(height: 4),
                Visibility(
                  visible: secondaryLabel != null,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: QioButton(
                    key: secondaryKey,
                    label: secondaryLabel ?? ' ',
                    variant: QioButtonVariant.ghost,
                    onPressed: isLoading ? null : onSecondary,
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateQueueChoiceCard extends StatelessWidget {
  const CreateQueueChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title. $subtitle',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: context.qio.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? QioColors.primary : context.qio.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: context.qio.primaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.qioText.bodyMedium.copyWith(
                          color: context.qio.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: context.qioText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? QioColors.primary : context.qio.gray400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateQueueSummaryCard extends StatelessWidget {
  const CreateQueueSummaryCard({
    super.key,
    required this.title,
    required this.lines,
    this.leading,
    required this.editKey,
    required this.onEdit,
  });

  final String title;
  final List<String> lines;
  final Widget? leading;
  final Key editKey;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: context.qio.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.qio.gray200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.qioText.label),
                const SizedBox(height: 4),
                for (final line in lines)
                  Text(
                    line,
                    style: context.qioText.bodyMedium.copyWith(
                      color: context.qio.textPrimary,
                    ),
                  ),
                if (leading != null) ...[const SizedBox(height: 6), leading!],
              ],
            ),
          ),
          TextButton(
            key: editKey,
            onPressed: onEdit,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Semantics(
              label: '${l10n.cqEdit}: $title',
              excludeSemantics: true,
              child: Text(l10n.cqEdit),
            ),
          ),
        ],
      ),
    );
  }
}
