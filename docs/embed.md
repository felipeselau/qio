# Widget público de espera (embed)

Página somente leitura com "N na fila · ~X min" e o estado da fila (aberta, em pausa ou
fechada). Serve para site, Instagram (link) e TV da loja. Não mostra nome, telefone nem
senha de ninguém e não tem botão de entrar.

## URL

```
https://qio.web.app/w/{queueId}
https://qio.web.app/w/{slug}
```

- `{queueId}` é o mesmo id do QR (`/q/{queueId}`).
- `{slug}` é o link curto da fila (o mesmo de `/n/{slug}`). A página resolve o slug pela
  callable `resolveSlug` e troca a URL (`replace`) para `/w/{queueId}`. Se o slug não existir
  e o valor também não for um queueId, aparece "Fila não encontrada".

## Iframe

```html
<iframe
  src="https://qio.web.app/w/SEU_ID_OU_SLUG"
  title="Fila ao vivo"
  width="320"
  height="260"
  style="border:0"
  loading="lazy"
></iframe>
```

Tamanho sugerido: 320 x 260 px (cabe em 280 x 220 sem rolagem). A página ocupa a altura
disponível e centraliza o conteúdo.

## Comportamento

- Tempo real: lê só `queues/{id}/meta` e `queues/{id}/public` no RTDB (auth anônima). Nunca
  lê `entries`.
- Contagem: "N na fila" = entries `waiting` em `public/`; "N em atendimento" = `called`.
- Estimativa: `(N + 1) × (avgServiceMinAuto ?? avgServiceMin ?? 10)` minutos, a mesma
  conta da página da senha para quem entraria agora. Sem fila, ou em fila por horário
  (`mode == 'schedule'`), não mostra estimativa.
- Fila em pausa ou fechada mostra `statusMessage`, previsão de retorno (`resumeAt`) e horário de
  abertura (`opensAt`), só quando estão no futuro.
- Tema: cor e logo da fila (`safeBrandColor`/`safeLogoUrl`); claro/escuro segue o sistema ou
  a escolha salva no navegador. Textos em pt/en/es pelo idioma do navegador.
- Sem som, vibração nem push. Região `aria-live="polite"` anuncia as mudanças.

## Hosting

- `firebase.json` reescreve `/w/**` para `/widget.html`, uma entrada Vite separada
  (`web/widget.html` → `src/widgetMain.tsx`) que não carrega a página da senha, o Messaging nem o
  Functions (este só é baixado quando o valor é um slug).
- Nenhuma rota do site envia `X-Frame-Options` nem `frame-ancestors` restritivo hoje. O header
  `Content-Security-Policy: frame-ancestors *` em `/w/**` deixa o embed explícito: se um dia
  uma proteção global contra framing for adicionada, ela precisa **excluir** `/w/**`
  (a ordem dos `headers` no `firebase.json` importa) e continuar valendo para o resto.

## Limites

- `public/` e `meta/` são legíveis por qualquer autenticado; o widget não expõe nada além do
  que a página da senha já mostra.
- App Check: se `ENFORCE_APP_CHECK` for ligado para `resolveSlug`, o embed por slug também
  precisa do token (`VITE_RECAPTCHA_SITE_KEY`); em iframe de terceiros o reCAPTCHA pode
  falhar. Em dúvida, use o `queueId` no embed, que não chama função alguma.
