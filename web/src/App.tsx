import { BrowserRouter, Routes, Route } from 'react-router-dom';
import QueuePage from './routes/QueuePage';
import { useTranslation } from 'react-i18next';
import { useTheme } from './lib/theme';
import { LANGUAGES, LANGUAGE_LABELS, setLanguage, type Language } from './i18n';

function NotFound() {
  const { t } = useTranslation();
  return (
    <div className="center-col">
      <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('app.invalidLink')}</h1>
      <p className="muted">{t('app.invalidLinkHint')}</p>
    </div>
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
      <BrowserRouter>
        <Routes>
          <Route path="/q/:queueId" element={<QueuePage />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}
