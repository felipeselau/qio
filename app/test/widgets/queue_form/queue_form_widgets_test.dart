import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/expiry_config.dart';
import 'package:qio_app/models/queue_schedule.dart';
import 'package:qio_app/services/brand_palette.dart';
import 'package:qio_app/widgets/queue_form/brand_color_picker.dart';
import 'package:qio_app/widgets/queue_form/expiry_form.dart';
import 'package:qio_app/widgets/queue_form/schedule_form.dart';

import '../../helpers/pump_app.dart';

void _noop(ScheduleFormValue _) {}

void main() {
  group('BrandColorPicker', () {
    testWidgets('marks the initial value and reports taps', (tester) async {
      String? picked;
      final first = brandPalette.first.hex;
      final second = brandPalette[1].hex;
      await pumpApp(
        tester,
        Scaffold(
          body: BrandColorPicker(value: first, onChanged: (v) => picked = v),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(second));
      expect(picked, second);
    });

    testWidgets('disabled ignores taps', (tester) async {
      String? picked;
      await pumpApp(
        tester,
        Scaffold(
          body: BrandColorPicker(
            value: null,
            enabled: false,
            onChanged: (v) => picked = v,
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsNothing);
      await tester.tap(find.bySemanticsLabel(brandPalette.first.hex));
      expect(picked, isNull);
    });
  });

  group('ExpiryForm', () {
    testWidgets('shows the initial value and reports changes', (tester) async {
      ExpiryConfig? changed;
      await pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ExpiryForm(
              value: const ExpiryConfig(enabled: true, hours: 24),
              onChanged: (v) => changed = v,
            ),
          ),
        ),
      );
      expect(find.text('Expirar após 24 h'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('expiry-clear')));
      expect(changed?.clearOnClose, isTrue);
      expect(changed?.hours, 24);
      await tester.tap(find.byKey(const ValueKey('expiry-reset')));
      expect(changed?.resetTicketDaily, isTrue);
    });

    testWidgets('disabled config hides options and enabled=false blocks', (
      tester,
    ) async {
      ExpiryConfig? changed;
      await pumpApp(
        tester,
        Scaffold(
          body: ExpiryForm(
            value: const ExpiryConfig(),
            enabled: false,
            onChanged: (v) => changed = v,
          ),
        ),
      );
      expect(find.byKey(const ValueKey('expiry-hours')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('expiry-enabled')));
      expect(changed, isNull);
    });
  });

  group('ScheduleForm', () {
    testWidgets('shows initial window and reports toggles', (tester) async {
      ScheduleFormValue? changed;
      final value = ScheduleFormValue.fromSchedule(
        const QueueSchedule(
          enabled: true,
          windows: [
            ScheduleWindow(days: [1, 2], open: '09:30', close: '17:00'),
          ],
        ),
      );
      await pumpApp(
        tester,
        Scaffold(
          body: SingleChildScrollView(
            child: ScheduleForm(value: value, onChanged: (v) => changed = v),
          ),
        ),
      );
      expect(find.textContaining('09:30'), findsOneWidget);
      expect(find.textContaining('17:00'), findsOneWidget);
      await tester.tap(find.byType(FilterChip).at(2));
      expect(changed?.days, {1, 2, 3});
      await tester.tap(find.byType(SwitchListTile));
      expect(changed?.enabled, isFalse);
    });

    testWidgets('renders errorText', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            child: ScheduleForm(
              value: ScheduleFormValue(enabled: true),
              onChanged: _noop,
              errorText: 'bad window',
            ),
          ),
        ),
      );
      expect(find.text('bad window'), findsOneWidget);
    });

    test('invalid windows report a problem', () {
      expect(const ScheduleFormValue().problem, isNull);
      expect(const ScheduleFormValue(enabled: true).problem, isNull);
      expect(const ScheduleFormValue(enabled: true, days: {}).problem, 'days');
      expect(
        const ScheduleFormValue(
          enabled: true,
          open: TimeOfDay(hour: 8, minute: 0),
          close: TimeOfDay(hour: 8, minute: 0),
        ).problem,
        'time',
      );
    });

    test('toSchedule maps enabled and disabled', () {
      expect(const ScheduleFormValue().toSchedule(), isNull);
      final s = const ScheduleFormValue(
        enabled: true,
        days: {3, 1},
      ).toSchedule()!;
      expect(s.windows.single.days, [1, 3]);
      expect(s.windows.single.open, '08:00');
      expect(s.windows.single.close, '18:00');
    });
  });
}
