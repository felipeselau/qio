import { useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { ownerAppUrl } from '../lib/landing';
import { PRIVACY_PATH } from '../lib/privacy';

const appUrl = ownerAppUrl(import.meta.env.VITE_OWNER_APP_URL as string | undefined);

export default function Landing() {
  const { t, i18n } = useTranslation();
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
  return (
    <main className="center-col landing">
      <h1 className="landing-title">{t('landing.title')}</h1>
      <p className="landing-tagline">{t('landing.tagline')}</p>
      <p className="muted">{t('landing.about')}</p>
      <section className="card landing-card" aria-labelledby="landing-how">
        <h2 id="landing-how" className="landing-h2">
          {t('landing.howTitle')}
        </h2>
        <p className="muted">{t('landing.how')}</p>
      </section>
      <p className="muted">
        <Link to={PRIVACY_PATH}>{t('queue.privacyLink')}</Link>
      </p>
      {appUrl && (
        <section className="landing-owner" aria-labelledby="landing-owner">
          <h2 id="landing-owner" className="landing-h2">
            {t('landing.ownerTitle')}
          </h2>
          <a className="btn btn-secondary" href={appUrl} rel="noopener noreferrer">
            {t('landing.ownerLink')}
          </a>
        </section>
      )}
    </main>
  );
}
