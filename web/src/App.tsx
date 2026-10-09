import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import QueuePage from './routes/QueuePage';
import Landing from './routes/Landing';
import { useTranslation } from 'react-i18next';
import { useTheme } from './lib/theme';
import { lazy, Suspense, useState } from 'react';
import { PRIVACY_PATH, TERMS_PATH } from './lib/privacy';
import {
  analyticsConfigured,
  isAnalyticsOptedOut,
  setAnalyticsOptOut,
} from './lib/analytics';
import { LANGUAGES, LANGUAGE_LABELS, setLanguage, type Language } from './i18n';

const Privacy = lazy(() => import('./routes/Privacy'));
const Terms = lazy(() => import('./routes/Terms'));

function NotFound() {
  const { t } = useTranslation();
  return (
    <main className="center-col">
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('app.invalidLink')}</h1>
      <p className="muted">{t('app.invalidLinkHint')}</p>
    </main>
  );
}

function AppFooter() {
  const { t } = useTranslation();
  const [optedOut, setOptedOut] = useState(isAnalyticsOptedOut);
  return (
    <footer className="analytics-footer">
      <nav className="footer-links" aria-label={t('app.legalNav')}>
        <Link className="analytics-link" to={PRIVACY_PATH}>
          {t('app.privacy')}
        </Link>
        <Link className="analytics-link" to={TERMS_PATH}>
          {t('app.terms')}
        </Link>
        {analyticsConfigured() && (
          <button
            type="button"
            className="analytics-link"
            onClick={() => {
              setAnalyticsOptOut(!optedOut);
              setOptedOut(!optedOut);
            }}
          >
            {optedOut ? t('app.analyticsOptIn') : t('app.analyticsOptOut')}
          </button>
        )}
      </nav>
    </footer>
  );
}

export default function App() {
  const { theme, toggle } = useTheme();
  const { t, i18n } = useTranslation();
  const current = (LANGUAGES as readonly string[]).includes(i18n.language)
    ? (i18n.language as Language)
    : 'pt';
  return (
    <div className="app-shell">
      <div className="top-bar">
        <button
          type="button"
          className="theme-toggle"
          onClick={toggle}
          aria-label={theme === 'dark' ? t('app.themeLight') : t('app.themeDark')}
        >
          {theme === 'dark' ? '☀️' : '🌙'}
        </button>
        <select
          className="lang-select"
          value={current}
          aria-label={t('app.language')}
          onChange={(e) => setLanguage(e.target.value as Language)}
        >
          {LANGUAGES.map((l) => (
            <option key={l} value={l}>
              {LANGUAGE_LABELS[l]}
            </option>
          ))}
        </select>
      </div>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/q/:queueId" element={<QueuePage />} />
          <Route path="/c/:queueId" element={<QueuePage />} />
          <Route
            path={PRIVACY_PATH}
            element={
              <Suspense fallback={null}>
                <Privacy />
              </Suspense>
            }
          />
          <Route
            path={TERMS_PATH}
            element={
              <Suspense fallback={null}>
                <Terms />
              </Suspense>
            }
          />
          <Route path="*" element={<NotFound />} />
        </Routes>
        <AppFooter />
      </BrowserRouter>
    </div>
  );
}
