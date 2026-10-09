import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { loadLegal, type LegalBundle } from '../i18n/legal';
import { LANGUAGES, type Language } from '../i18n/resolveLanguage';
import { contactHref, privacyContact } from '../lib/privacy';

const contact = privacyContact(import.meta.env.VITE_PRIVACY_CONTACT as string | undefined);

export default function LegalPage({ kind }: { kind: 'privacy' | 'terms' }) {
  const { i18n } = useTranslation();
  const lang: Language = (LANGUAGES as readonly string[]).includes(i18n.language)
    ? (i18n.language as Language)
    : 'pt';
  const [bundle, setBundle] = useState<LegalBundle | null>(null);

  useEffect(() => {
    let active = true;
    void loadLegal(lang).then((b) => {
      if (active) setBundle(b);
    });
    return () => {
      active = false;
    };
  }, [lang]);

  const title = bundle?.[kind].title;
  useEffect(() => {
    if (!title) return;
    const previous = document.title;
    document.title = `${title} · Qio`;
    return () => {
      document.title = previous;
    };
  }, [title]);

  if (!bundle) {
    return (
      <main className="legal" aria-busy="true">
        <div className="spinner" role="status" />
      </main>
    );
  }

  const doc = bundle[kind];
  const href = contactHref(contact);
  return (
    <main className="legal">
      <p className="legal-draft" role="note">
        {bundle.draftBanner}
      </p>
      <h1 className="legal-title">{doc.title}</h1>
      <p className="muted">
        {bundle.effectiveLabel}: {bundle.effectivePlaceholder}
      </p>
      {doc.sections.map((s) => (
        <section key={s.heading} aria-labelledby={`legal-${s.heading}`}>
          <h2 id={`legal-${s.heading}`} className="legal-h2">
            {s.heading}
          </h2>
          {s.paragraphs?.map((p) => <p key={p}>{p}</p>)}
          {s.items && (
            <ul>
              {s.items.map((i) => (
                <li key={i}>{i}</li>
              ))}
            </ul>
          )}
        </section>
      ))}
      {kind === 'privacy' && (
        <section aria-labelledby="legal-contact">
          <h2 id="legal-contact" className="legal-h2">
            {bundle.contactHeading}
          </h2>
          {contact ? (
            <p>
              {bundle.contactIntro}{' '}
              {href ? (
                <a href={href} rel="noopener noreferrer">
                  {contact}
                </a>
              ) : (
                contact
              )}
            </p>
          ) : (
            <p className="legal-warning">{bundle.contactMissing}</p>
          )}
        </section>
      )}
    </main>
  );
}
