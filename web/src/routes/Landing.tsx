import { useTranslation } from 'react-i18next';
import { ownerAppUrl } from '../lib/landing';

const appUrl = ownerAppUrl(import.meta.env.VITE_OWNER_APP_URL as string | undefined);

export default function Landing() {
  const { t } = useTranslation();
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
