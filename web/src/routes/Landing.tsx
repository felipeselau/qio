import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { LANGUAGES, LANGUAGE_LABELS, setLanguage, type Language } from '../i18n';
import { OWNER_APP_FALLBACK_URL, ownerAppUrl } from '../lib/landing';
import { PRIVACY_PATH } from '../lib/privacy';
import { useTheme } from '../lib/theme';
import { Phone } from './landing/Phone';
import { PanelScreen, TicketScreen } from './landing/screens';
import { Story } from './landing/Story';
import { useReveal } from './landing/useReveal';
import './landing/landing.css';

const appUrl =
  ownerAppUrl(import.meta.env.VITE_OWNER_APP_URL as string | undefined) ?? OWNER_APP_FALLBACK_URL;

type Item = { t: string; b: string };
type Column = { label: string; items: Item[] };
type Story = { eyebrow: string; title: string; steps: Item[] };

function Symbol() {
  return (
    <svg viewBox="46.5 46.5 433.5 433.5" aria-hidden="true" focusable="false">
      <circle cx="225" cy="225" r="123" fill="none" stroke="currentColor" strokeWidth="51" />
      <circle cx="368" cy="368" r="34" fill="currentColor" />
      <circle cx="428" cy="428" r="22" fill="currentColor" opacity="0.6" />
    </svg>
  );
}

function Reveal({ className = '', children }: { className?: string; children: React.ReactNode }) {
  const ref = useReveal<HTMLDivElement>();
  return (
    <div ref={ref} className={`rv ${className}`.trim()}>
      {children}
    </div>
  );
}

export default function Landing() {
  const { t, i18n } = useTranslation();
  const { theme, toggle } = useTheme();
  const current = (LANGUAGES as readonly string[]).includes(i18n.language)
    ? (i18n.language as Language)
    : 'pt';
  const documentTitle = t('landing.documentTitle');
  const metaDescription = t('landing.metaDescription');
  useEffect(() => {
    const previousTitle = document.title;
    let meta = document.head.querySelector<HTMLMetaElement>('meta[name="description"]');
    const created = !meta;
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'description';
      document.head.appendChild(meta);
    }
    const previousDescription = meta.content;
    document.title = documentTitle;
    meta.content = metaDescription;
    return () => {
      document.title = previousTitle;
      if (created) meta.remove();
      else meta.content = previousDescription;
    };
  }, [documentTitle, metaDescription, i18n.language]);

  const client = t('landing.stories.client', { returnObjects: true }) as Story;
  const owner = t('landing.stories.owner', { returnObjects: true }) as Story;
  const facts = t('landing.facts.items', { returnObjects: true }) as Item[];
  const columns = t('landing.index.columns', { returnObjects: true }) as Column[];
  const care = t('landing.care.items', { returnObjects: true }) as Item[];

  return (
    <div className="lp">
      <header className="lp-nav">
        <a className="lp-brand" href="/" aria-label={t('landing.title')}>
          <span className="lp-tile">
            <Symbol />
          </span>
          <span>{t('landing.title')}</span>
          <span className="lp-version">v1.6</span>
        </a>
        <div className="lp-nav-actions">
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
      </header>

      <main>
        <section className="lp-hero" aria-labelledby="lp-title">
          <div className="lp-hero-text">
            <h1 id="lp-title" className="lp-wordmark">
              {t('landing.title')}
            </h1>
            <h2 className="lp-tagline">
              {t('landing.hero.titleA')} <span>{t('landing.hero.titleB')}</span>
            </h2>
            <p className="lp-lede">{t('landing.hero.sub')}</p>
            <div className="lp-cta-row">
              <a className="lp-cta" href={appUrl} rel="noopener noreferrer">
                {t('landing.hero.cta')}
              </a>
              <a className="lp-cta lp-cta-ghost" href="#cliente">
                {t('landing.hero.how')}
              </a>
            </div>
            <p className="lp-note">{t('landing.hero.note')}</p>
          </div>
          <div className="lp-stage">
            <div className="lp-dots" />
            <Phone size={14} className="ph-back" label={t('landing.stories.client.steps.1.t')}>
              <TicketScreen />
            </Phone>
            <Phone size={16} className="ph-front" label={t('landing.stories.owner.steps.1.t')}>
              <PanelScreen />
            </Phone>
            <div className="lp-push" role="img" aria-label={t('landing.mock.push')}>
              <span className="lp-tile">
                <Symbol />
              </span>
              <div>
                <b>
                  {t('landing.title')} <i>{t('landing.mock.now')}</i>
                </b>
                <p>{t('landing.mock.push')}</p>
              </div>
            </div>
          </div>
        </section>

        <Story
          id="cliente"
          eyebrow={client.eyebrow}
          title={client.title}
          steps={client.steps}
          screens={['join', 'ticket', 'called']}
        />
        <Story
          id="dono"
          eyebrow={owner.eyebrow}
          title={owner.title}
          steps={owner.steps}
          screens={['qr', 'panel', 'metrics']}
          flip
        />

        <section className="lp-section" aria-labelledby="lp-facts">
          <Reveal className="lp-section-head">
            <h2 id="lp-facts" className="lp-h2">
              {t('landing.facts.title')}
            </h2>
          </Reveal>
          <ul className="lp-facts">
            {facts.map((f, i) => (
              <li key={f.t} className="lp-fact rv-li">
                <Reveal className={`rv-d${Math.min(i, 3)}`}>
                  <strong>{f.t}</strong> {f.b}
                </Reveal>
              </li>
            ))}
          </ul>
        </section>

        <section className="lp-section" aria-labelledby="lp-index">
          <Reveal className="lp-section-head">
            <h2 id="lp-index" className="lp-h2">
              {t('landing.index.title')}
            </h2>
          </Reveal>
          <div className="lp-index">
            {columns.map((c, i) => (
              <Reveal key={c.label} className={`lp-col rv-d${i + 1}`}>
                <h3 className="lp-col-label">{c.label}</h3>
                <ul>
                  {c.items.map((it) => (
                    <li key={it.t}>
                      <strong>{it.t}</strong> {it.b}
                    </li>
                  ))}
                </ul>
              </Reveal>
            ))}
          </div>
        </section>

        <section className="lp-section" aria-labelledby="lp-care">
          <Reveal className="lp-section-head">
            <h2 id="lp-care" className="lp-h2">
              {t('landing.care.title')}
            </h2>
          </Reveal>
          <div className="lp-cards">
            {care.map((c, i) => (
              <Reveal key={c.t} className={`lp-card rv-d${i % 3}`}>
                <h3>{c.t}</h3>
                <p>{c.b}</p>
              </Reveal>
            ))}
          </div>
          <p className="lp-fine">
            {t('landing.care.note')} <Link to={PRIVACY_PATH}>{t('queue.privacyLink')}</Link>
          </p>
        </section>

        <section className="lp-closing" aria-labelledby="lp-closing">
          <Reveal className="lp-closing-card">
            <div className="lp-dots" />
            <span className="lp-tile">
              <Symbol />
            </span>
            <h2 id="lp-closing" className="lp-h2">
              {t('landing.closing.title')}
            </h2>
            <p className="lp-lede">{t('landing.closing.sub')}</p>
            <a className="lp-cta" href={appUrl} rel="noopener noreferrer">
              {t('landing.closing.cta')}
            </a>
            <p className="lp-fine">{t('landing.closing.req')}</p>
            <p className="lp-fine">{t('landing.credit')}</p>
          </Reveal>
        </section>
      </main>
    </div>
  );
}
