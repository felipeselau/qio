# Goldens

Protegem layout, cores e tema (claro/escuro, pt, 320/390), não glifos: o texto usa a fonte Ahem do `flutter_test` (caixas). Tag `golden`, rodam no `flutter test` padrão do CI.

- **Os PNGs são o render do CI Linux** (a fonte da verdade). Em macOS/Windows o teste apenas renderiza a tela (smoke) e não compara, porque o antialiasing difere ~2% do Linux.
- Comparação com tolerância de 0,5% dos pixels (`goldenTolerance` em `test/helpers/golden.dart`).
- Atualizar após uma mudança visual intencional: abra o PR, deixe o job `flutter` falhar, baixe o artifact `golden-failures` (`gh run download <run> -n golden-failures`) e copie cada `<nome>_testImage.png` para `test/goldens/<nome>.png`; commite junto da mudança.
