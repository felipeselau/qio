import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/controllers/create_queue_controller.dart';
import 'package:qio_app/controllers/create_queue_draft.dart';
import 'package:qio_app/models/expiry_config.dart';
import 'package:qio_app/models/queue_info.dart';
import 'package:qio_app/models/queue_schedule.dart';
import 'package:qio_app/models/queue_slot.dart';

const _s = CreateQueueStep.values;

List<QueueSlot> _slots(int n) => [
  for (var i = 0; i < n; i++)
    QueueSlot(
      id: 's$i',
      start:
          '${(i ~/ 2 + 8).toString().padLeft(2, '0')}:${i.isEven ? '00' : '30'}',
      capacity: 5,
    ),
];

const _window = ScheduleWindow(days: [1, 2], open: '08:00', close: '18:00');

CreateQueueController _named([String name = 'Fila A']) =>
    CreateQueueController()..update((d) => d.copyWith(name: name));

void main() {
  group('passo name', () {
    test('vazio e só espaços exigem nome', () {
      final c = CreateQueueController();
      expect(c.errorFor(CreateQueueStep.name), QueueInfoError.nameRequired);
      expect(c.canContinue(CreateQueueStep.name), isFalse);
      c.update((d) => d.copyWith(name: '   '));
      expect(c.canContinue(CreateQueueStep.name), isFalse);
      expect(c.next(), isFalse);
      expect(c.step, CreateQueueStep.name);
    });

    test('limites de nome 60/61', () {
      final c = _named('a' * 60);
      expect(c.canContinue(CreateQueueStep.name), isTrue);
      c.update((d) => d.copyWith(name: 'a' * 61));
      expect(c.errorFor(CreateQueueStep.name), QueueInfoError.nameTooLong);
      c.update((d) => d.copyWith(name: ' ${'a' * 60} '));
      expect(c.canContinue(CreateQueueStep.name), isTrue);
    });

    test('limites de descrição 300/301', () {
      final c = _named()..update((d) => d.copyWith(description: 'x' * 300));
      expect(c.canContinue(CreateQueueStep.name), isTrue);
      c.update((d) => d.copyWith(description: 'x' * 301));
      expect(
        c.errorsFor(CreateQueueStep.name)[CreateQueueField.description],
        QueueInfoError.descriptionTooLong,
      );
    });
  });

  group('passo mode', () {
    test('queue ignora slots inválidos', () {
      final c = _named()..update((d) => d.copyWith(slots: _slots(21)));
      expect(c.canContinue(CreateQueueStep.mode), isTrue);
    });

    test('schedule sem slots exige ao menos um', () {
      final c = _named()..update((d) => d.copyWith(mode: QueueMode.schedule));
      expect(c.errorFor(CreateQueueStep.mode), SlotsError.required);
    });

    test('20 slots passam, 21 falham', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(mode: QueueMode.schedule, slots: _slots(20)),
        );
      expect(c.canContinue(CreateQueueStep.mode), isTrue);
      c.update((d) => d.copyWith(slots: _slots(21)));
      expect(c.errorFor(CreateQueueStep.mode), SlotsError.tooMany);
    });

    test('horário duplicado e capacidade fora do limite', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(
            mode: QueueMode.schedule,
            slots: const [
              QueueSlot(id: 'a', start: '09:00', capacity: 1),
              QueueSlot(id: 'b', start: '09:00', capacity: 1),
            ],
          ),
        );
      expect(c.errorFor(CreateQueueStep.mode), SlotsError.duplicate);
      c.update(
        (d) => d.copyWith(
          slots: const [QueueSlot(id: 'a', start: '09:00', capacity: 51)],
        ),
      );
      expect(c.errorFor(CreateQueueStep.mode), SlotsError.invalid);
      c.update(
        (d) => d.copyWith(
          slots: const [QueueSlot(id: 'a', start: '09:00', capacity: 50)],
        ),
      );
      expect(c.canContinue(CreateQueueStep.mode), isTrue);
    });
  });

  group('passo capacity', () {
    test('vazios são válidos', () {
      expect(
        CreateQueueController().canContinue(CreateQueueStep.capacity),
        isTrue,
      );
    });

    test('tempo médio 1..240', () {
      final c = CreateQueueController();
      for (final ok in ['1', '240', ' 10 ']) {
        c.update((d) => d.copyWith(avgServiceMin: ok));
        expect(c.canContinue(CreateQueueStep.capacity), isTrue, reason: ok);
      }
      for (final bad in ['0', '241', 'abc', '-1', '1.5']) {
        c.update((d) => d.copyWith(avgServiceMin: bad));
        expect(
          c.errorFor(CreateQueueStep.capacity),
          QueueInfoError.avgServiceInvalid,
          reason: bad,
        );
      }
    });

    test('limite de espera 1..1000', () {
      final c = CreateQueueController();
      for (final ok in ['1', '1000']) {
        c.update((d) => d.copyWith(maxWaiting: ok));
        expect(c.canContinue(CreateQueueStep.capacity), isTrue, reason: ok);
      }
      for (final bad in ['0', '1001', 'x', '-5']) {
        c.update((d) => d.copyWith(maxWaiting: bad));
        expect(
          c.errorFor(CreateQueueStep.capacity),
          MaxWaitingError.invalid,
          reason: bad,
        );
      }
    });
  });

  group('passo schedule', () {
    test('sem horário ou desativado é válido', () {
      final c = CreateQueueController();
      expect(c.canContinue(CreateQueueStep.schedule), isTrue);
      c.update(
        (d) => d.copyWith(schedule: const QueueSchedule(enabled: false)),
      );
      expect(c.canContinue(CreateQueueStep.schedule), isTrue);
    });

    test('ativado exige janelas válidas', () {
      final c = CreateQueueController();
      void set(List<ScheduleWindow> w) => c.update(
        (d) => d.copyWith(schedule: QueueSchedule(enabled: true, windows: w)),
      );
      set(const []);
      expect(c.errorFor(CreateQueueStep.schedule), ScheduleError.noWindows);
      set(const [ScheduleWindow(days: [], open: '08:00', close: '18:00')]);
      expect(c.errorFor(CreateQueueStep.schedule), ScheduleError.days);
      set(const [
        ScheduleWindow(days: [1], open: '08:00', close: '08:00'),
      ]);
      expect(c.errorFor(CreateQueueStep.schedule), ScheduleError.time);
      set(const [
        ScheduleWindow(days: [1], open: '8h', close: '18:00'),
      ]);
      expect(c.errorFor(CreateQueueStep.schedule), ScheduleError.invalidTime);
      set(const [
        ScheduleWindow(days: [8], open: '08:00', close: '18:00'),
      ]);
      expect(c.errorFor(CreateQueueStep.schedule), ScheduleError.invalidDay);
      set(const [
        ScheduleWindow(days: [1], open: '22:00', close: '02:00'),
      ]);
      expect(c.canContinue(CreateQueueStep.schedule), isTrue);
    });
  });

  group('appearance e review', () {
    test('appearance sempre válido', () {
      expect(
        CreateQueueController().canContinue(CreateQueueStep.appearance),
        isTrue,
      );
    });

    test('review agrega erros dos passos anteriores', () {
      final c = CreateQueueController();
      expect(c.canContinue(CreateQueueStep.review), isFalse);
      expect(c.errorFor(CreateQueueStep.review), QueueInfoError.nameRequired);
      c.update((d) => d.copyWith(name: 'ok', maxWaiting: '0'));
      expect(c.errorFor(CreateQueueStep.review), MaxWaitingError.invalid);
      c.update((d) => d.copyWith(maxWaiting: '5'));
      expect(c.canContinue(CreateQueueStep.review), isTrue);
      expect(c.firstInvalidStep, isNull);
    });
  });

  group('navegação', () {
    test('totalSteps e índice', () {
      final c = _named();
      expect(c.totalSteps, 6);
      expect(c.stepIndex, 0);
      expect(c.isFirst, isTrue);
      c.next();
      expect(c.stepIndex, 1);
    });

    test('percorre todos os passos até review e para', () {
      final c = _named();
      for (var i = 0; i < 5; i++) {
        expect(c.next(), isTrue);
      }
      expect(c.step, CreateQueueStep.review);
      expect(c.isReview, isTrue);
      expect(c.next(), isFalse);
    });

    test('next notifica; falha não notifica', () {
      final c = CreateQueueController();
      var n = 0;
      c.addListener(() => n++);
      c.next();
      expect(n, 0);
      c.update((d) => d.copyWith(name: 'x'));
      expect(n, 1);
      c.update((d) => d.copyWith(name: 'x'));
      expect(n, 1);
      c.next();
      expect(n, 2);
    });

    test('back preserva todos os valores', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(
            description: 'desc',
            mode: QueueMode.schedule,
            slots: _slots(3),
          ),
        );
      c.next();
      c.next();
      c.update((d) => d.copyWith(avgServiceMin: '15', maxWaiting: '30'));
      final before = c.draft;
      expect(c.back(), isTrue);
      expect(c.back(), isTrue);
      expect(c.back(), isFalse);
      expect(c.step, CreateQueueStep.name);
      expect(c.draft, before);
      expect(c.draft.slots, hasLength(3));
    });

    test('back funciona mesmo com passo atual inválido', () {
      final c = _named();
      c.next();
      c.update((d) => d.copyWith(mode: QueueMode.schedule));
      expect(c.canContinue(CreateQueueStep.mode), isFalse);
      expect(c.back(), isTrue);
    });

    test('skip em passo opcional zera os campos e avança', () {
      final c = _named();
      c.next();
      c.next();
      c.update((d) => d.copyWith(avgServiceMin: '999', maxWaiting: '5000'));
      expect(c.canContinue(CreateQueueStep.capacity), isFalse);
      expect(c.skip(), isTrue);
      expect(c.step, CreateQueueStep.appearance);
      expect(c.draft.avgServiceMin, '');
      expect(c.draft.maxWaiting, '');
      c.update((d) => d.copyWith(brandColor: '#2563EB', groupId: 'g1'));
      expect(c.skip(), isTrue);
      expect(c.draft.brandColor, isNull);
      expect(c.draft.groupId, isNull);
      c.update(
        (d) => d.copyWith(
          schedule: const QueueSchedule(enabled: true),
          expiry: const ExpiryConfig(enabled: true),
        ),
      );
      expect(c.skip(), isTrue);
      expect(c.step, CreateQueueStep.review);
      expect(c.draft.schedule, isNull);
      expect(c.draft.expiry?.enabled, isTrue);
    });

    test('skip em passo obrigatório é recusado', () {
      final c = _named();
      expect(c.skip(), isFalse);
      c.next();
      expect(c.skip(), isFalse);
      expect(c.step, CreateQueueStep.mode);
    });

    test('jumpTo só para passos já alcançados e válidos', () {
      final c = _named();
      expect(c.jumpTo(CreateQueueStep.review), isFalse);
      for (var i = 0; i < 5; i++) {
        c.next();
      }
      expect(c.jumpTo(CreateQueueStep.name), isTrue);
      expect(c.step, CreateQueueStep.name);
      c.update((d) => d.copyWith(name: ''));
      expect(c.jumpTo(CreateQueueStep.review), isFalse);
      expect(c.jumpTo(CreateQueueStep.name), isFalse);
    });

    test('editar na revisão volta direto à revisão', () {
      final c = _named();
      for (var i = 0; i < 5; i++) {
        c.next();
      }
      expect(c.jumpTo(CreateQueueStep.capacity), isTrue);
      expect(c.returningToReview, isTrue);
      c.update((d) => d.copyWith(maxWaiting: '10'));
      expect(c.next(), isTrue);
      expect(c.step, CreateQueueStep.review);
      expect(c.returningToReview, isFalse);
      expect(c.draft.maxWaiting, '10');
    });

    test(
      'editar na revisão bloqueia next se inválido e back cancela retorno',
      () {
        final c = _named();
        for (var i = 0; i < 5; i++) {
          c.next();
        }
        c.jumpTo(CreateQueueStep.capacity);
        c.update((d) => d.copyWith(maxWaiting: '0'));
        expect(c.next(), isFalse);
        expect(c.step, CreateQueueStep.capacity);
        c.back();
        expect(c.returningToReview, isFalse);
        expect(c.step, CreateQueueStep.mode);
      },
    );
  });

  group('isDirty', () {
    test('limpo no início', () {
      expect(CreateQueueController().isDirty, isFalse);
    });

    test('espaços não sujam', () {
      final c = CreateQueueController()
        ..update(
          (d) => d.copyWith(
            name: '  ',
            description: ' ',
            avgServiceMin: ' ',
            maxWaiting: '  ',
          ),
        );
      expect(c.isDirty, isFalse);
    });

    test('edição suja e reverter limpa', () {
      final c = CreateQueueController()..update((d) => d.copyWith(name: ' a '));
      expect(c.isDirty, isTrue);
      c.update((d) => d.copyWith(name: ''));
      expect(c.isDirty, isFalse);
    });

    test('baseline inicial customizada', () {
      const base = CreateQueueDraft(name: 'Base');
      final c = CreateQueueController(initial: base);
      expect(c.isDirty, isFalse);
      c.update((d) => d.copyWith(name: ' Base '));
      expect(c.isDirty, isFalse);
      c.update((d) => d.copyWith(mode: QueueMode.schedule));
      expect(c.isDirty, isTrue);
    });
  });

  group('draft', () {
    test('igualdade e hashCode por valor', () {
      final a = CreateQueueDraft(name: 'x', slots: _slots(2));
      final b = CreateQueueDraft(name: 'x', slots: _slots(2));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.copyWith(name: 'y'), isFalse);
    });

    test('copyWith limpa campos anuláveis', () {
      final d =
          const CreateQueueDraft(
            groupId: 'g',
            brandColor: '#2563EB',
            schedule: QueueSchedule(enabled: true),
            expiry: ExpiryConfig(),
          ).copyWith(
            clearGroupId: true,
            clearBrandColor: true,
            clearSchedule: true,
            clearExpiry: true,
          );
      expect(d, const CreateQueueDraft());
    });
  });

  group('toCreateArgs', () {
    test('lança enquanto inválido', () {
      expect(
        () => CreateQueueController().toCreateArgs(),
        throwsA(isA<FormatException>()),
      );
    });

    test('defaults: nome trim, avg vazio vira default, limite 0', () {
      final a = _named('  Fila  ').toCreateArgs();
      expect(a.name, 'Fila');
      expect(a.description, isNull);
      expect(a.avgServiceMin, defaultAvgServiceMin);
      expect(a.maxWaiting, 0);
      expect(a.mode, QueueMode.queue);
      expect(a.slots, isEmpty);
      expect(a.schedule, isNull);
      expect(a.groupId, isNull);
      expect(a.brandColor, isNull);
      expect(a.expiry, isNull);
    });

    test('valores preenchidos', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(
            description: ' d ',
            avgServiceMin: ' 20 ',
            maxWaiting: '50',
            groupId: ' g1 ',
            brandColor: '#0F766E',
            schedule: const QueueSchedule(enabled: true, windows: [_window]),
            expiry: const ExpiryConfig(enabled: true, hours: 6),
          ),
        );
      final a = c.toCreateArgs();
      expect(a.description, 'd');
      expect(a.avgServiceMin, 20);
      expect(a.maxWaiting, 50);
      expect(a.groupId, 'g1');
      expect(a.brandColor, '#0F766E');
      expect(a.schedule?.windows, hasLength(1));
      expect(a.expiry?.hours, 6);
    });

    test('slots ignorados em modo queue', () {
      final c = _named()..update((d) => d.copyWith(slots: _slots(3)));
      expect(c.toCreateArgs().slots, isEmpty);
    });

    test('modo schedule leva slots ordenados', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(
            mode: QueueMode.schedule,
            slots: const [
              QueueSlot(id: 'b', start: '10:00', capacity: 2),
              QueueSlot(id: 'a', start: '09:00', capacity: 2),
            ],
          ),
        );
      expect(c.toCreateArgs().slots.map((s) => s.id), ['a', 'b']);
    });

    test('schedule desativado vira null', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(schedule: const QueueSchedule(enabled: false)),
        );
      expect(c.toCreateArgs().schedule, isNull);
    });

    test('20 slots em schedule passam', () {
      final c = _named()
        ..update(
          (d) => d.copyWith(mode: QueueMode.schedule, slots: _slots(20)),
        );
      expect(c.toCreateArgs().slots, hasLength(20));
    });
  });

  group('json', () {
    CreateQueueDraft full() => CreateQueueDraft(
      name: 'Fila',
      description: 'd',
      groupId: 'g1',
      avgServiceMin: '12',
      maxWaiting: '7',
      mode: QueueMode.schedule,
      slots: _slots(3),
      brandColor: '#2563EB',
      schedule: const QueueSchedule(enabled: true, windows: [_window]),
      expiry: const ExpiryConfig(enabled: true, hours: 8),
    );

    test('round trip do draft via string json', () {
      final d = full();
      final back = CreateQueueDraft.fromJson(
        jsonDecode(jsonEncode(d.toJson())),
        validGroupIds: {'g1'},
      );
      expect(back, d);
      expect(d.toJson()['version'], createQueueDraftVersion);
    });

    test('round trip do controller preserva passo', () {
      final c = CreateQueueController(
        draft: full(),
        step: CreateQueueStep.capacity,
      );
      final back = CreateQueueController.fromJson(
        jsonDecode(jsonEncode(c.toJson())),
        validGroupIds: {'g1'},
      )!;
      expect(back.draft, c.draft);
      expect(back.step, CreateQueueStep.capacity);
      expect(back.isDirty, isTrue);
    });

    test('rascunho sem version, versão futura ou não-mapa é descartado', () {
      expect(CreateQueueDraft.fromJson(null), isNull);
      expect(CreateQueueDraft.fromJson('x'), isNull);
      expect(CreateQueueDraft.fromJson({'name': 'a'}), isNull);
      expect(CreateQueueDraft.fromJson({'version': 99, 'name': 'a'}), isNull);
      expect(CreateQueueDraft.fromJson({'version': '1'}), isNull);
      expect(CreateQueueController.fromJson({'name': 'a'}), isNull);
    });

    test('descarta slots inválidos', () {
      final json = full().toJson()
        ..['slots'] = [for (final s in _slots(21)) s.toMap()];
      expect(CreateQueueDraft.fromJson(json)!.slots, isEmpty);
      json['slots'] = [
        {'id': 'a', 'start': '09:00', 'capacity': 1},
        {'id': 'b', 'start': '09:00', 'capacity': 1},
      ];
      expect(CreateQueueDraft.fromJson(json)!.slots, isEmpty);
      json['slots'] = [
        {'id': 'a', 'start': '25:00', 'capacity': 1},
        'lixo',
      ];
      expect(CreateQueueDraft.fromJson(json)!.slots, isEmpty);
      json['slots'] = 'x';
      expect(CreateQueueDraft.fromJson(json)!.slots, isEmpty);
    });

    test('20 slots sobrevivem', () {
      final d = CreateQueueDraft(mode: QueueMode.schedule, slots: _slots(20));
      expect(CreateQueueDraft.fromJson(d.toJson())!.slots, hasLength(20));
    });

    test('descarta schedule inválido', () {
      final json = full().toJson()
        ..['schedule'] = {
          'enabled': true,
          'windows': [
            {'days': <int>[], 'open': '08:00', 'close': '18:00'},
          ],
        };
      expect(CreateQueueDraft.fromJson(json)!.schedule, isNull);
      json['schedule'] = 'x';
      expect(CreateQueueDraft.fromJson(json)!.schedule, isNull);
    });

    test('descarta groupId inexistente ou vazio', () {
      final json = full().toJson();
      expect(
        CreateQueueDraft.fromJson(json, validGroupIds: {'g2'})!.groupId,
        isNull,
      );
      expect(
        CreateQueueDraft.fromJson(json, validGroupIds: {'g1'})!.groupId,
        'g1',
      );
      json['groupId'] = ' ';
      expect(CreateQueueDraft.fromJson(json)!.groupId, isNull);
      json['groupId'] = 5;
      expect(CreateQueueDraft.fromJson(json)!.groupId, isNull);
    });

    test('descarta cor fora da paleta e tipos errados', () {
      final json = <String, Object?>{
        'version': 1,
        'name': 5,
        'description': null,
        'avgServiceMin': 10,
        'maxWaiting': [],
        'mode': 'xyz',
        'brandColor': '#123456',
        'expiry': 'x',
      };
      final d = CreateQueueDraft.fromJson(json)!;
      expect(d.brandColor, isNull);
      expect(d.name, '');
      expect(d.avgServiceMin, '');
      expect(d.maxWaiting, '');
      expect(d.mode, QueueMode.queue);
      expect(d.expiry, isNull);
    });

    test('controller volta ao primeiro passo inválido', () {
      final json = full().toJson()
        ..['name'] = ''
        ..['step'] = 'review';
      final c = CreateQueueController.fromJson(json)!;
      expect(c.step, CreateQueueStep.name);
    });

    test('step desconhecido cai em name', () {
      final json = full().toJson()..['step'] = 'foo';
      expect(CreateQueueController.fromJson(json)!.step, CreateQueueStep.name);
    });

    test('slots descartados em modo schedule seguram o passo mode', () {
      final json = full().toJson()
        ..['slots'] = <Object?>[]
        ..['step'] = 'review';
      expect(CreateQueueController.fromJson(json)!.step, CreateQueueStep.mode);
    });
  });

  test('ordem dos passos', () {
    expect(_s.map((e) => e.name), [
      'name',
      'mode',
      'capacity',
      'appearance',
      'schedule',
      'review',
    ]);
  });
}
