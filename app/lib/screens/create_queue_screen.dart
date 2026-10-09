import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../controllers/create_queue_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/expiry_config.dart';
import '../models/queue_group.dart';
import '../models/queue_info.dart';
import '../models/queue_schedule.dart';
import '../models/queue_slot.dart';
import '../services/brand_palette.dart';
import '../services/group_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/create_queue/create_queue_parts.dart';
import '../widgets/create_queue/queue_limit_gate.dart';
import '../widgets/group_picker.dart';
import '../widgets/qio_input.dart';
import '../widgets/queue_form/brand_color_picker.dart';
import '../widgets/queue_form/expiry_form.dart';
import '../widgets/queue_form/schedule_form.dart';
import '../widgets/queue_info_fields.dart';
import '../widgets/queue_panel/panel_notices.dart';
import '../widgets/queue_panel/queue_limit_tile.dart';
import '../widgets/queue_panel/slots_editor.dart';
import 'queue_created_screen.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key, this.queues, this.groups});

  final QueueService? queues;
  final GroupService? groups;

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  static const createTimeout = Duration(seconds: 20);
  static const _pageDuration = Duration(milliseconds: 250);

  final _c = CreateQueueController();
  final _pages = PageController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _avgCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _moreCtrl = ExpansibleController();
  final _nameForm = GlobalKey<FormState>();
  final _capacityForm = GlobalKey<FormState>();
  final _attempted = <CreateQueueStep>{};
  ScheduleFormValue _scheduleValue = const ScheduleFormValue();
  int _shown = 0;
  bool _loading = false;
  bool _checkingLimit = true;
  bool _atLimit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onController);
    _nameCtrl.addListener(
      () => _c.update((d) => d.copyWith(name: _nameCtrl.text)),
    );
    _descCtrl.addListener(
      () => _c.update((d) => d.copyWith(description: _descCtrl.text)),
    );
    _avgCtrl.addListener(
      () => _c.update((d) => d.copyWith(avgServiceMin: _avgCtrl.text)),
    );
    _limitCtrl.addListener(
      () => _c.update((d) => d.copyWith(maxWaiting: _limitCtrl.text)),
    );
    _checkLimit();
  }

  Future<void> _checkLimit() async {
    final service = widget.queues ?? QueueService.instance;
    var atLimit = false;
    try {
      atLimit = await service.isAtQueueLimit(service.currentUid);
    } on Exception {
      atLimit = false;
    }
    if (!mounted) return;
    setState(() {
      _atLimit = atLimit;
      _checkingLimit = false;
    });
  }

  @override
  void dispose() {
    _c.removeListener(_onController);
    _c.dispose();
    _pages.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _avgCtrl.dispose();
    _limitCtrl.dispose();
    _moreCtrl.dispose();
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    setState(() => _error = null);
    if (_c.stepIndex == _shown) return;
    _shown = _c.stepIndex;
    FocusManager.instance.primaryFocus?.unfocus();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(_shown);
    } else {
      _pages.animateToPage(
        _shown,
        duration: _pageDuration,
        curve: Curves.easeOutCubic,
      );
    }
    final l10n = AppLocalizations.of(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      '${l10n.cqStepOf(_shown + 1, _c.totalSteps)}. ${_title(_c.step, l10n)}',
      Directionality.of(context),
    );
  }

  String _title(CreateQueueStep step, AppLocalizations l10n) => switch (step) {
    CreateQueueStep.name => l10n.cqNameTitle,
    CreateQueueStep.mode => l10n.cqModeTitle,
    CreateQueueStep.capacity => l10n.cqCapacityTitle,
    CreateQueueStep.appearance => l10n.cqAppearanceTitle,
    CreateQueueStep.schedule => l10n.cqScheduleTitle,
    CreateQueueStep.review => l10n.cqReviewTitle,
  };

  void _reveal(CreateQueueStep step) {
    setState(() => _attempted.add(step));
    _nameForm.currentState?.validate();
    _capacityForm.currentState?.validate();
    final errors = _c.errorsFor(step);
    if (errors.containsKey(CreateQueueField.description)) _moreCtrl.expand();
  }

  void _next() {
    if (_loading) return;
    final step = _c.step;
    if (!_c.canContinue(step)) {
      _reveal(step);
      return;
    }
    _c.next();
  }

  void _skip() {
    if (_loading || !_c.isOptional(_c.step)) return;
    final step = _c.step;
    if (_c.skip()) {
      if (step == CreateQueueStep.capacity) {
        _avgCtrl.clear();
        _limitCtrl.clear();
      }
      if (step == CreateQueueStep.schedule) {
        _scheduleValue = const ScheduleFormValue();
      }
    }
  }

  void _back() {
    if (_loading) return;
    _c.back();
  }

  void _edit(CreateQueueStep step) {
    if (_loading) return;
    _c.jumpTo(step);
  }

  void _quickCreate() {
    if (_c.isFirst && !_c.canContinue(CreateQueueStep.name)) {
      _reveal(CreateQueueStep.name);
      return;
    }
    _submit();
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardTitle),
        content: Text(l10n.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    final invalid = _c.firstInvalidStep;
    if (invalid != null) {
      if (_c.jumpTo(invalid)) _reveal(invalid);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final args = _c.toCreateArgs();
      final queue = await (widget.queues ?? QueueService.instance)
          .createQueue(
            name: args.name,
            description: args.description,
            avgServiceMin: args.avgServiceMin,
            maxWaiting: args.maxWaiting,
            groupId: args.groupId,
            mode: args.mode,
            slots: args.slots,
            schedule: args.schedule,
            brandColor: args.brandColor,
            expiry: args.expiry,
          )
          .timeout(createTimeout);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                QueueCreatedScreen(queue: queue, queues: widget.queues),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = queueErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = _c.step;
    if (_checkingLimit || _atLimit) {
      return QueueLimitGate(checking: _checkingLimit);
    }
    return PopScope(
      canPop: !_loading && _c.isFirst && !_c.isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _loading) return;
        if (_c.isFirst) {
          _confirmDiscard();
        } else {
          _back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.qio.surface,
          leading: const QueueBackButton(key: ValueKey('create-back')),
          title: Text(
            l10n.newQueue,
            style: context.qioText.heading2.copyWith(
              fontWeight: FontWeight.w700,
              color: context.qio.textPrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            CreateQueueProgress(
              key: const ValueKey('create-progress'),
              current: _c.stepIndex + 1,
              total: _c.totalSteps,
            ),
            if (_error != null) _ErrorBanner(message: _error!),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  CreateQueueKeepAlive(child: _nameStep(l10n)),
                  _modeStep(l10n),
                  _capacityStep(l10n),
                  _appearanceStep(l10n),
                  _scheduleStep(l10n),
                  _reviewStep(l10n),
                ],
              ),
            ),
            _footer(step, l10n),
          ],
        ),
      ),
    );
  }

  Widget _footer(CreateQueueStep step, AppLocalizations l10n) {
    if (step == CreateQueueStep.review) {
      return CreateQueueFooter(
        primaryKey: const ValueKey('create-submit'),
        primaryLabel: l10n.createQueue,
        onPrimary: _loading ? null : _submit,
        isLoading: _loading,
      );
    }
    final isFirst = step == CreateQueueStep.name;
    final optional = _c.isOptional(step);
    return CreateQueueFooter(
      primaryKey: const ValueKey('create-continue'),
      primaryLabel: l10n.cqContinue,
      onPrimary: _loading ? null : _next,
      secondaryKey: ValueKey(isFirst ? 'create-quick' : 'create-skip'),
      secondaryLabel: isFirst
          ? l10n.cqQuickCreate
          : optional
          ? l10n.cqSkip
          : null,
      onSecondary: isFirst ? _quickCreate : _skip,
      isLoading: _loading,
    );
  }

  bool _showing(CreateQueueStep step) => _attempted.contains(step);

  Widget _nameStep(AppLocalizations l10n) {
    return CreateQueueStepPage(
      title: l10n.cqNameTitle,
      hint: l10n.cqNameHint,
      children: [
        Form(
          key: _nameForm,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QueueNameField(
                key: const ValueKey('create-name'),
                controller: _nameCtrl,
                enabled: !_loading,
                autofocus: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _next(),
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: const ValueKey('create-more-details'),
                  controller: _moreCtrl,
                  maintainState: true,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    l10n.cqMoreDetails,
                    style: context.qioText.bodyMedium.copyWith(
                      color: context.qio.textPrimary,
                    ),
                  ),
                  children: [
                    QueueDescriptionField(
                      key: const ValueKey('create-description'),
                      controller: _descCtrl,
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),
                    GroupPicker(
                      key: const ValueKey('create-group'),
                      value: _c.draft.groupId,
                      groups: widget.groups,
                      enabled: !_loading,
                      onChanged: (id) => _c.update(
                        (d) => id == null
                            ? d.copyWith(clearGroupId: true)
                            : d.copyWith(groupId: id),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setMode(QueueMode mode) => _c.update((d) => d.copyWith(mode: mode));

  void _applySuggestion(int step) {
    _c.update(
      (d) => d.copyWith(
        mode: QueueMode.schedule,
        slots: suggestSlots(
          fromMinutes: 9 * 60,
          toMinutes: 17 * 60,
          stepMinutes: step,
          existing: d.slots,
        ),
      ),
    );
  }

  Widget _modeStep(AppLocalizations l10n) {
    final d = _c.draft;
    final isSchedule = d.mode == QueueMode.schedule;
    final slotsError = _showing(CreateQueueStep.mode)
        ? _c.errorsFor(CreateQueueStep.mode)[CreateQueueField.slots]
              as SlotsError?
        : null;
    return CreateQueueStepPage(
      title: l10n.cqModeTitle,
      children: [
        CreateQueueChoiceCard(
          key: const ValueKey('create-mode-queue'),
          icon: Icons.people_alt_outlined,
          title: l10n.modeQueue,
          subtitle: l10n.cqModeQueueHint,
          selected: !isSchedule,
          onTap: _loading ? null : () => _setMode(QueueMode.queue),
        ),
        const SizedBox(height: 12),
        CreateQueueChoiceCard(
          key: const ValueKey('create-mode-schedule'),
          icon: Icons.event_available_outlined,
          title: l10n.modeSchedule,
          subtitle: l10n.cqModeScheduleHint,
          selected: isSchedule,
          onTap: _loading ? null : () => _setMode(QueueMode.schedule),
        ),
        if (isSchedule) ...[
          const SizedBox(height: 24),
          Text(l10n.cqSuggestionsTitle, style: context.qioText.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const ValueKey('create-suggest-30'),
                label: Text(l10n.cqSuggestEvery30),
                onPressed: _loading ? null : () => _applySuggestion(30),
              ),
              ActionChip(
                key: const ValueKey('create-suggest-60'),
                label: Text(l10n.cqSuggestEveryHour),
                onPressed: _loading ? null : () => _applySuggestion(60),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SlotsEditor(
            key: const ValueKey('create-slots'),
            mode: d.mode,
            slots: d.slots,
            error: slotsError,
            enabled: !_loading,
            showModeSelector: false,
            onChanged: (mode, slots) =>
                _c.update((d) => d.copyWith(mode: mode, slots: slots)),
          ),
        ],
      ],
    );
  }

  Widget _capacityStep(AppLocalizations l10n) {
    return CreateQueueStepPage(
      title: l10n.cqCapacityTitle,
      hint: l10n.cqCapacityHint(defaultAvgServiceMin),
      children: [
        Form(
          key: _capacityForm,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              QueueAvgServiceField(
                key: const ValueKey('create-avg'),
                controller: _avgCtrl,
                enabled: !_loading,
              ),
              const SizedBox(height: 16),
              QioInput(
                key: const ValueKey('create-limit'),
                label: l10n.maxWaitingLabel,
                hint: l10n.maxWaitingHint,
                controller: _limitCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _next(),
                validator: (v) => validateMaxWaiting(v, l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appearanceStep(AppLocalizations l10n) {
    return CreateQueueStepPage(
      title: l10n.cqAppearanceTitle,
      hint: l10n.cqAppearanceHint,
      children: [
        BrandColorPicker(
          key: const ValueKey('create-color'),
          value: _c.draft.brandColor,
          enabled: !_loading,
          onChanged: (hex) => _c.update((d) => d.copyWith(brandColor: hex)),
        ),
      ],
    );
  }

  String? _scheduleErrorText(AppLocalizations l10n) {
    if (!_showing(CreateQueueStep.schedule)) return null;
    final error = _c.errorsFor(
      CreateQueueStep.schedule,
    )[CreateQueueField.schedule];
    if (error == null) return null;
    return error == ScheduleError.days || error == ScheduleError.noWindows
        ? l10n.scheduleInvalidDays
        : l10n.scheduleInvalidTime;
  }

  Widget _scheduleStep(AppLocalizations l10n) {
    return CreateQueueStepPage(
      title: l10n.cqScheduleTitle,
      hint: l10n.cqScheduleHint,
      children: [
        IgnorePointer(
          ignoring: _loading,
          child: ScheduleForm(
            key: const ValueKey('create-schedule'),
            value: _scheduleValue,
            errorText: _scheduleErrorText(l10n),
            onChanged: (value) {
              _scheduleValue = value;
              _c.update(
                (d) => value.enabled
                    ? d.copyWith(schedule: value.toSchedule())
                    : d.copyWith(clearSchedule: true),
              );
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 24),
        ExpiryForm(
          key: const ValueKey('create-expiry'),
          value: _c.draft.expiry ?? const ExpiryConfig(),
          enabled: !_loading,
          showExtras: false,
          onChanged: (value) => _c.update(
            (d) => value.enabled
                ? d.copyWith(expiry: value)
                : d.copyWith(clearExpiry: true),
          ),
        ),
      ],
    );
  }

  Widget _reviewStep(AppLocalizations l10n) {
    final d = _c.draft.trimmed();
    final locale = Localizations.localeOf(context).toString();
    final avg = QueueInfo.parseAvgServiceMin(d.avgServiceMin);
    final limit = int.tryParse(d.maxWaiting);
    final schedule = d.schedule;
    final windows = schedule != null && schedule.enabled
        ? schedule.windows
        : const <ScheduleWindow>[];
    final expiry = d.expiry;
    final color = brandPalette.where((c) => c.hex == d.brandColor).firstOrNull;
    return CreateQueueStepPage(
      title: l10n.cqReviewTitle,
      hint: l10n.cqReviewHint,
      children: [
        StreamBuilder<List<QueueGroup>>(
          stream: d.groupId == null
              ? null
              : (widget.groups ?? GroupService.instance).watchGroups(),
          builder: (context, snap) {
            final group = (snap.data ?? const <QueueGroup>[])
                .where((g) => g.id == d.groupId)
                .firstOrNull;
            return CreateQueueSummaryCard(
              title: l10n.cqSummaryName,
              editKey: const ValueKey('create-edit-name'),
              onEdit: _loading ? null : () => _edit(CreateQueueStep.name),
              lines: [d.name, if (d.description.isNotEmpty) d.description],
              leading: d.groupId == null
                  ? null
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        key: const ValueKey('create-review-group'),
                        avatar: const Icon(Icons.folder_outlined, size: 18),
                        label: Text(group?.name ?? l10n.cqGroupChosen),
                      ),
                    ),
            );
          },
        ),
        const SizedBox(height: 12),
        CreateQueueSummaryCard(
          title: l10n.cqSummaryEntry,
          editKey: const ValueKey('create-edit-mode'),
          onEdit: _loading ? null : () => _edit(CreateQueueStep.mode),
          lines: d.mode == QueueMode.schedule
              ? [
                  l10n.modeSchedule,
                  l10n.slotsTileSummary(d.slots.length),
                  sortedSlots(d.slots).map((s) => s.start).join(', '),
                ]
              : [l10n.modeQueue],
        ),
        const SizedBox(height: 12),
        CreateQueueSummaryCard(
          title: l10n.cqSummaryCapacity,
          editKey: const ValueKey('create-edit-capacity'),
          onEdit: _loading ? null : () => _edit(CreateQueueStep.capacity),
          lines: [
            l10n.cqAverageTime(
              l10n.durationMinutes(avg ?? defaultAvgServiceMin),
            ),
            l10n.cqWaitingLimit(
              limit == null || limit <= 0
                  ? l10n.maxWaitingHint
                  : l10n.cqLimitPeople(limit),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CreateQueueSummaryCard(
          title: l10n.brandColorLabel,
          editKey: const ValueKey('create-edit-appearance'),
          onEdit: _loading ? null : () => _edit(CreateQueueStep.appearance),
          lines: [if (color == null) l10n.cqDefaultColor else color.hex],
          leading: color == null
              ? null
              : Container(
                  key: const ValueKey('create-review-color'),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.color,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        CreateQueueSummaryCard(
          title: l10n.cqSummarySchedule,
          editKey: const ValueKey('create-edit-schedule'),
          onEdit: _loading ? null : () => _edit(CreateQueueStep.schedule),
          lines: [
            if (windows.isEmpty)
              l10n.cqAlwaysOpen
            else
              for (final w in windows)
                l10n.scheduleHours(
                  daysSummary(w.days, locale),
                  w.open,
                  w.close,
                ),
            expiry != null && expiry.enabled
                ? l10n.expiryAfterHours(expiry.hours)
                : l10n.cqNoExpiry,
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('create-error'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: QioColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: context.qioText.bodyMedium.copyWith(
            color: context.qio.statusClosedText,
          ),
        ),
      ),
    );
  }
}
