import { initializeApp } from 'firebase/app';
import { initializeAppCheck, ReCaptchaV3Provider } from 'firebase/app-check';
import { getAuth } from 'firebase/auth';
import { getDatabase } from 'firebase/database';
import { getMessaging, type Messaging } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: 'AIzaSyAY29R07GlubY5lFmUriQ8qiVuiiWv7W6Y',
  authDomain: 'qio-app.firebaseapp.com',
  databaseURL: 'https://qio-app-default-rtdb.firebaseio.com',
  projectId: 'qio-app',
  storageBucket: 'qio-app.firebasestorage.app',
  messagingSenderId: '981965097928',
  appId: '1:981965097928:web:b08d7d1bfce182d3d4cefd',
};

const app = initializeApp(firebaseConfig);

// App Check (reCAPTCHA v3) — mitiga entradas falsas/automatizadas na fila,
// rejeitando no backend do Firebase requisições que não venham do site legítimo
// (ex.: scripts chamando a REST API do Firebase diretamente, fora do navegador).
// Só ativa se VITE_RECAPTCHA_SITE_KEY estiver configurada (ver web/.env.example);
// sem a chave, o app funciona normalmente sem essa proteção — não quebra o dev local.
const recaptchaSiteKey = import.meta.env.VITE_RECAPTCHA_SITE_KEY as string | undefined;
if (recaptchaSiteKey) {
  initializeAppCheck(app, {
    provider: new ReCaptchaV3Provider(recaptchaSiteKey),
    isTokenAutoRefreshEnabled: true,
  });
}

export const auth = getAuth(app);
export const db = getDatabase(app);

// getMessaging() lança sincronamente em navegadores sem suporte a FCM
// (muitos webviews de apps, Safari iOS antigo). Como firebase.ts é importado
// por toda a aplicação, chamá-lo no topo do módulo derrubaria a página inteira.
// Resolvido de forma preguiçosa: retorna null quando não há suporte.
let _messaging: Messaging | null | undefined;
export function getMessagingSafe(): Messaging | null {
  if (_messaging !== undefined) return _messaging;
  try {
    _messaging = getMessaging(app);
  } catch {
    _messaging = null;
  }
  return _messaging;
}