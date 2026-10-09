import { initializeApp } from 'firebase/app';
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from 'firebase/app-check';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectDatabaseEmulator, getDatabase } from 'firebase/database';

import { firebaseConfig } from './firebaseConfig';

const config = {
  ...firebaseConfig,
  measurementId: (import.meta.env.VITE_MEASUREMENT_ID as string | undefined) || undefined,
};

export const app = initializeApp(config);

// App Check (reCAPTCHA Enterprise / Fraud Defense) — mitiga entradas falsas/automatizadas na fila,
// rejeitando no backend do Firebase requisições que não venham do site legítimo
// (ex.: scripts chamando a REST API do Firebase diretamente, fora do navegador).
// Só ativa se VITE_RECAPTCHA_SITE_KEY estiver configurada (ver web/.env.example);
// sem a chave, o app funciona normalmente sem essa proteção — não quebra o dev local.
const recaptchaSiteKey = import.meta.env.VITE_RECAPTCHA_SITE_KEY as string | undefined;
if (recaptchaSiteKey && import.meta.env.VITE_USE_EMULATORS !== 'true') {
  const debugToken = import.meta.env.VITE_APPCHECK_DEBUG_TOKEN as string | undefined;
  if (import.meta.env.DEV && debugToken) {
    (self as unknown as { FIREBASE_APPCHECK_DEBUG_TOKEN: string | boolean }).FIREBASE_APPCHECK_DEBUG_TOKEN =
      debugToken === 'true' ? true : debugToken;
  }
  initializeAppCheck(app, {
    provider: new ReCaptchaEnterpriseProvider(recaptchaSiteKey),
    isTokenAutoRefreshEnabled: true,
  });
}

export const auth = getAuth(app);
export const db = getDatabase(app);

if (import.meta.env.VITE_USE_EMULATORS === 'true') {
  connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true });
  connectDatabaseEmulator(db, 'localhost', 9000);
}
