import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { LANGUAGES, LANGUAGE_LABELS, setLanguage, type Language } from '../i18n';
import { OWNER_APP_FALLBACK_URL, ownerAppUrl } from '../lib/landing';
import { PRIVACY_PATH } from '../lib/privacy';
import { useTheme } from '../lib/theme';

const appUrl =
  ownerAppUrl(import.meta.env.VITE_OWNER_APP_URL as string | undefined) ?? OWNER_APP_FALLBACK_URL;

type Item = { t: string; b: string };
type Highlight = Item & { alt: string };
type Column = { label: string; items: Item[] };

const HIGHLIGHT_IMAGES = ['join', 'ticket', 'called', 'panel', 'metrics'] as const;

function Phone({ src, alt, className = '' }: { src: string; alt: string; className?: string }) {
  return (
    <div className={`lp-phone ${className}`.trim()}>
      <img src={src} alt={alt} width={560} height={1064} loading="lazy" decoding="async" />
    </div>
  );
}

function Symbol() {
  return (
    <svg viewBox="46.5 46.5 433.5 433.5" aria-hidden="true" focusable="false" className="lp-symbol">
      <circle cx="225" cy="225" r="123" fill="none" stroke="currentColor" strokeWidth="51" />
      <circle cx="368" cy="368" r="34" fill="currentColor" />
      <circle cx="428" cy="428" r="22" fill="currentColor" opacity="0.6" />
    </svg>
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

  const facts = t('landing.facts.items', { returnObjects: true }) as Item[];
  const highlights = t('landing.highlights.items', { returnObjects: true }) as Highlight[];
  const columns = t('landing.index.columns', { returnObjects: true }) as Column[];
  const care = t('landing.care.items', { returnObjects: true }) as Item[];

  return (
    <div className="lp">
      <header className="lp-nav">
        <a className="lp-brand" href="/" aria-label={t('landing.title')}>
          <Symbol />
          <span>{t('landing.title')}</span>
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
          <a className="btn btn-primary lp-nav-cta" href={appUrl} rel="noopener noreferrer">
            {t('landing.navCta')}
          </a>
        </div>
      </header>

      <main className="lp-main">
        <section className="lp-hero" aria-labelledby="lp-hero-title">
          <h1 id="lp-hero-title" className="lp-h1">
            {t('landing.hero.titleA')} <em>{t('landing.hero.titleB')}</em>
          </h1>
          <p className="lp-sub">{t('landing.hero.sub')}</p>
          <div className="lp-cta-row">
            <a className="btn btn-primary lp-btn" href={appUrl} rel="noopener noreferrer">
              {t('landing.hero.cta')}
            </a>
            <a className="btn btn-secondary lp-btn" href="#destaques">
              {t('landing.hero.how')}
            </a>
          </div>
          <p className="lp-note">{t('landing.hero.note')}</p>
          <div className="lp-hero-visual" aria-hidden={false}>
            <Phone
              src="/landing/ticket.png"
              alt={highlights[1]?.alt ?? ''}
              className="lp-phone-side lp-phone-left lp-phone-crop"
            />
            <Phone src="/landing/panel.png" alt={highlights[3]?.alt ?? ''} className="lp-phone-main" />
            <Phone
              src="/landing/called.png"
              alt={highlights[2]?.alt ?? ''}
              className="lp-phone-side lp-phone-right"
            />
          </div>
        </section>

        <section className="lp-section" aria-labelledby="lp-facts">
          <h2 id="lp-facts" className="lp-eyebrow">
            {t('landing.facts.title')}
          </h2>
          <ul className="lp-facts">
            {facts.map((f) => (
              <li key={f.t} className="lp-fact">
                <strong>{f.t}</strong> {f.b}
              </li>
            ))}
          </ul>
        </section>

        <section id="destaques" className="lp-section lp-band" aria-labelledby="lp-highlights">
          <h2 id="lp-highlights" className="lp-eyebrow">
            {t('landing.highlights.title')}
          </h2>
          <div className="lp-features">
            {highlights.map((h, i) => (
              <article key={h.t} className={`lp-feature${i % 2 ? ' lp-feature-flip' : ''}`}>
                <div className="lp-feature-text">
                  <h3 className="lp-h3">{h.t}</h3>
                  <p className="lp-p">{h.b}</p>
                </div>
                <Phone
                  src={`/landing/${HIGHLIGHT_IMAGES[i]}.png`}
                  alt={h.alt}
                  className={i < 2 ? 'lp-phone-crop' : ''}
                />
              </article>
            ))}
          </div>
        </section>

        <section className="lp-section" aria-labelledby="lp-index">
          <h2 id="lp-index" className="lp-eyebrow">
            {t('landing.index.title')}
          </h2>
          <div className="lp-index">
            {columns.map((c) => (
              <div key={c.label} className="lp-col">
                <h3 className="lp-col-label">{c.label}</h3>
                <ul>
                  {c.items.map((it) => (
                    <li key={it.t}>
                      <strong>{it.t}</strong> {it.b}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </section>

        <section className="lp-section lp-band" aria-labelledby="lp-care">
          <h2 id="lp-care" className="lp-eyebrow">
            {t('landing.care.title')}
          </h2>
          <div className="lp-cards">
            {care.map((c) => (
              <div key={c.t} className="lp-card">
                <h3>{c.t}</h3>
                <p>{c.b}</p>
              </div>
            ))}
          </div>
          <p className="lp-fine">
            {t('landing.care.note')} <Link to={PRIVACY_PATH}>{t('queue.privacyLink')}</Link>
          </p>
        </section>

        <section className="lp-closing" aria-labelledby="lp-closing">
          <Symbol />
          <h2 id="lp-closing" className="lp-h2">
            {t('landing.closing.title')}
          </h2>
          <p className="lp-sub">{t('landing.closing.sub')}</p>
          <a className="btn btn-primary lp-btn" href={appUrl} rel="noopener noreferrer">
            {t('landing.closing.cta')}
          </a>
          <p className="lp-fine">{t('landing.closing.req')}</p>
          <p className="lp-fine">{t('landing.credit')}</p>
        </section>
      </main>
    </div>
  );
}
