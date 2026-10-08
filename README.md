# Qio

Sistema de filas para atendimentos presenciais. Proprietários criam filas no app móvel e geram QR Codes; clientes escaneiam o QR e entram na fila pelo navegador — sem instalar app.

## Documentação

| Documento                        | Descrição                                        |
| -------------------------------- | ------------------------------------------------ |
| [`docs/INTRODUCAO.md`](docs/INTRODUCAO.md) | **Introdução** — contexto, problemas, impactos, solução e objetivos do trabalho |
| [`docs/RESUMO_TECNICO.md`](docs/RESUMO_TECNICO.md) | **Resumo técnico completo** — stack, bibliotecas, arquitetura, comunicação entre módulos, modelo de dados, segurança, custos |
| [`docs/SPEC.md`](docs/SPEC.md)           | Especificação original do MVP — personas, fluxos, escopo (o estado atual está no `CLAUDE.md` e no resumo técnico) |
| [`docs/FCM.md`](docs/FCM.md)             | Guia de ativação de push notifications (FCM)     |
| [`docs/APPCHECK.md`](docs/APPCHECK.md)   | App Check nas callables: escopo, rollout e rollback |
| [`docs/monitoring.md`](docs/monitoring.md) | Logging estruturado, analytics com opt-out e ações manuais no console |
| [`docs/qualidade.md`](docs/qualidade.md) | **Quadro de resultados** — testes, cobertura, CI e limitações conhecidas |
| [`docs/testes/`](docs/testes/)           | Casos de teste, ambiente de emulators e roteiro de demonstração |
| [`CHANGELOG.md`](CHANGELOG.md)           | Histórico de versões do app |
| [`CLAUDE.md`](CLAUDE.md)                 | Guia de módulos, comandos, modelo de dados e decisões de cada funcionalidade |

## Estrutura

```
qio/
├── app/          # Flutter — app do proprietário (Android/iOS)
├── web/          # React + Vite + TypeScript — página do cliente (navegador)
├── functions/    # Cloud Functions v2 (Node 22) — callables joinQueue/submitFeedback, espelho público, push (FCM), estimativa, horários e alertas
├── rules-tests/  # Testes das rules (Firestore, RTDB, Storage) e da callable joinQueue nos emulators
├── docs/         # Documentação do projeto
├── design/       # Identidade visual (SVGs, PNGs, generate.py)
├── firebase.json
├── firestore.rules
├── database.rules.json
└── storage.rules
```

## Stack

| Módulo       | Tecnologia                                              |
| ------------ | ------------------------------------------------------- |
| **App Owner**  | Flutter (CI com 3.44.3; versão do app em `app/pubspec.yaml`: 1.4.0+5) + Firebase (Auth, Firestore, RTDB, Messaging, Analytics, Crashlytics) + Provider |
| **Web Client** | React 19 + TypeScript + Vite + Firebase JS SDK (Auth, RTDB, Functions, FCM, App Check, Analytics) |
| **Backend**    | Firebase: Auth, Firestore, RTDB, Cloud Functions v2 (Node 22), Storage, Hosting, FCM |

## Funcionalidades

- **Cliente (web, sem instalar):** entrada pela callable `joinQueue` com nome e telefone opcional, senha e posição em tempo real, estimativa de espera, alerta na página (som e vibração) e push em segundo plano (pt/en/es), "Você é o próximo", sair da fila, avaliação de 1 a 5 estrelas, modo escuro, cor e logo da fila, PWA instalável, escolha de horário em filas por hora marcada.
- **Dono (app):** filas com QR e cartaz, chamar próximo/de novo/agora, mover para o fim, atendido/não compareceu, pausar/fechar com mensagem e previsão de retorno, limite de pessoas em espera, horário de funcionamento automático, filas por hora marcada (slots diários), grupos de filas, operadores por código de convite, push quando alguém entra, alertas operacionais (espera alta, não comparecimento alto, fila parada), histórico com filtros e avaliações, exportação CSV/PDF, tour de onboarding, i18n pt/en/es, modo escuro.
- **Métricas (app):** espera e atendimento médios, mediana e P90 de espera, faixas de espera, re-chamadas, métricas por atendente, demanda por dia da semana, heatmap dia×hora, tendência diária e comparação com o período anterior, escopo por grupo/fila, exportação em CSV/PDF.
- **Proteção e observabilidade:** rate limit e validação na `joinQueue`, App Check opcional nas callables (`joinQueue` e `submitFeedback`, flags por callable, enforcement desligado), logging estruturado sem PII e analytics com opt-out. Detalhes em `docs/APPCHECK.md` e `docs/monitoring.md`.
- **Qualidade:** testes de unidade e de widget com goldens no app, testes de lógica pura nas functions e testes das rules/callable nos emulators. Números em [`docs/qualidade.md`](docs/qualidade.md).

## Setup

### Flutter (proprietário)

```bash
cd app
flutter pub get
flutterfire configure --project=qio-app
flutter run
```

### Web (cliente)

```bash
cd web
npm ci
cp .env.example .env   # preencher VITE_VAPID_KEY e VITE_RECAPTCHA_SITE_KEY
npm run dev        # desenvolvimento
npm run build      # produção (dist/)
```

> App Check (`VITE_RECAPTCHA_SITE_KEY`) é opcional em dev — sem ele o app funciona
> normalmente, só sem a proteção contra bots/scripts na entrada da fila. Ver
> `web/.env.example`, [`docs/APPCHECK.md`](docs/APPCHECK.md) e a seção 6 de
> [`docs/RESUMO_TECNICO.md`](docs/RESUMO_TECNICO.md).

### Testes

Comandos de cada módulo (app, web, functions, rules-tests) estão no
[`CLAUDE.md`](CLAUDE.md); resultados e cobertura em [`docs/qualidade.md`](docs/qualidade.md).

### Firebase

```bash
# Regras
firebase deploy --only firestore:rules,database:rules
# a ordem entre functions, hosting e rules importa: ver "Ordem de deploy" no CLAUDE.md

# Hosting
firebase deploy --only hosting
```

## Release Android

- Keystore: `app/android/release.keystore` (alias `qio-key`) — **gitignored**
- Credenciais: `app/android/key.properties` — **gitignored**
- Backup: `~/.qio/keystore-credentials.txt` (chmod 600)

```bash
cd app
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ Se perder o keystore/credenciais, o APK não pode ser atualizado sem re-assinar.

## Referências técnicas

Ver [`docs/RESUMO_TECNICO.md`](docs/RESUMO_TECNICO.md) para visão técnica completa.
Ver [`docs/SPEC.md`](docs/SPEC.md) para a especificação original do MVP (personas, fluxos e escopo inicial).

## Licença

© 2026 Luiz Felipe Scheffer Selau. **Todos os direitos reservados.** O código está público apenas para consulta e avaliação acadêmica; não há licença para copiar, modificar, distribuir ou usar comercialmente sem autorização por escrito. Veja [`LICENSE`](LICENSE). Componentes de terceiros (como a fonte Inter, SIL OFL 1.1) mantêm suas próprias licenças.
