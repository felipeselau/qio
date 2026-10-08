# Goldens

Protegem layout, cores e tema (claro/escuro, pt, 320/390), não glifos: o texto usa a fonte Ahem do `flutter_test` (caixas), igual em macOS e Linux. Tag `golden`, roda no `flutter test` padrão e no CI.

- Atualizar: `cd app && flutter test --update-goldens --tags golden` (gerados no macOS) e commitar os PNGs junto da mudança visual.
- Comparação com tolerância de 0,5% dos pixels (`goldenTolerance` em `test/helpers/golden.dart`) para absorver antialiasing entre plataformas.
- Se o CI Linux divergir: baixe o artifact `golden-failures` do job `flutter` (`*_masterImage/testImage/isolatedDiff/maskedDiff.png`), confira o diff e, se for só ruído de plataforma, regenere localmente ou suba `goldenTolerance`.
