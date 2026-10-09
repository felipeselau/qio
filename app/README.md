# Qio — app do proprietário

App Flutter (Android/iOS) para donos e operadores de fila. Versão atual em
`pubspec.yaml`: 1.5.0+6. Visão geral e comandos do monorepo: [`../README.md`](../README.md) e
[`../CLAUDE.md`](../CLAUDE.md).

## Comandos

```bash
flutter pub get
flutter analyze lib test
flutter test                                   # unidade, widget e goldens
flutter test --coverage                        # gera coverage/lcov.info
flutter test --update-goldens --tags golden    # regenera test/goldens
flutter run
```

Goldens (fonte Ahem, tolerância 0,5%) estão descritos em
[`test/goldens/README.md`](test/goldens/README.md). Resultados de testes e
cobertura: [`../docs/qualidade.md`](../docs/qualidade.md).

## Estrutura de `lib/`

- `screens/` — telas (home, painel da fila, histórico, métricas, grupos, alertas, operadores, conta).
- `services/` — acesso ao Firebase e lógica pura (métricas, exportação, analytics, push).
- `models/`, `widgets/`, `controllers/`, `theme/` (`QioPalette`, `ThemeExtension`) e `l10n/` (pt, en, es).

## Release

`flutter build apk --release` exige `android/key.properties`; ver "Release do app"
no [`../CLAUDE.md`](../CLAUDE.md).
