# Marca do Qio

Símbolo: um **Q** em anel cuja cauda são pontos esperando a vez. O primeiro ponto é a
próxima pessoa a ser chamada; o segundo, mais claro, é quem vem depois.

## Arquivos

| Arquivo | Uso |
| --- | --- |
| `symbol.svg` | Símbolo azul sobre fundo claro |
| `symbol-dark.svg` | Símbolo azul claro sobre fundo escuro |
| `symbol-white.svg` | Símbolo branco sobre azul ou foto |
| `symbol-mono.svg` | Símbolo em um tom só (impressão, carimbo) |
| `logo.svg`, `logo-dark.svg` | Logotipo: o símbolo como "Q" + "io" (Inter Bold, em curvas) |
| `icon.svg` | Ícone do app (tile azul, canto arredondado) |
| `icon-small.svg` | Ícone para 32 px ou menos (favicon): um ponto só, mais grosso |
| `icon-foreground.svg`, `icon-monochrome.svg` | Camadas do ícone adaptativo do Android (zona segura de 66%) |
| `png/` | Exportações: `icon-1024`, `icon-small-512`, `symbol-1024`, `icon-foreground-1024`, `icon-monochrome-1024`, `logo`, `logo-dark` e `preview` |

O fundo do ícone adaptativo é a cor sólida `#2563EB`.

## Cores

| Papel | Valor | Observação |
| --- | --- | --- |
| Azul Qio | `#2563EB` | Cor da marca; 5,2:1 com texto branco |
| Azul no escuro | `#60A5FA` | Símbolo e links sobre `#0B1220`/`#111827` |
| Tinta | `#111827` | Texto do logotipo no claro |
| Papel | `#F9FAFB` | Texto do logotipo no escuro |

## Regras de uso

- Área de respiro: pelo menos a espessura do anel (cerca de 1/6 da altura do "Q") em volta.
- Tamanho mínimo do símbolo completo: 32 px de altura. Abaixo disso use `icon-small.svg`.
- Em 16 a 24 px o "Q" pode lembrar uma lupa; por isso a versão pequena tem um ponto só.
- Não girar, não esticar, não trocar as cores do anel e dos pontos entre si, não aplicar sombra.
- O ponto claro tem 60% de opacidade; em versões de uma cor mantenha essa transparência.

## Regenerar

Os SVGs e as curvas do logotipo saem de `generate.py`. Precisa de Python com `fonttools` e do
arquivo `Inter-Variable.ttf` (em `app/assets/fonts/` depois do PR da fonte):

```bash
cd design/brand
python3 generate.py ../../app/assets/fonts/Inter-Variable.ttf
```

Os PNGs foram exportados com o Chrome em modo headless, por exemplo:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
  --default-background-color=00000000 --window-size=1024,1024 \
  --screenshot="$PWD/png/icon-1024.png" "file://$PWD/icon.svg"
```
