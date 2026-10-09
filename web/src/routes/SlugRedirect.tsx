import { useCallback, useEffect, useState } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { signInAnonymously } from 'firebase/auth';
import { httpsCallable } from 'firebase/functions';
import { auth, functions } from '../firebase';
import { parseSlug, queuePathFor, slugErrorKind } from '../lib/slug';

type Resolution =
  | { kind: 'loading' }
  | { kind: 'found'; queueId: string }
  | { kind: 'notFound' }
  | { kind: 'retry' };

async function resolve(slug: string): Promise<string> {
  await auth.authStateReady();
  if (!auth.currentUser) await signInAnonymously(auth);
  const call = httpsCallable<{ slug: string }, { queueId: string }>(functions, 'resolveSlug');
  return (await call({ slug })).data.queueId;
}

export default function SlugRedirect() {
  const { t } = useTranslation();
  const { slug: raw } = useParams();
  const slug = parseSlug(raw);
  const [state, setState] = useState<Resolution>(
    slug ? { kind: 'loading' } : { kind: 'notFound' },
  );
  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    if (!slug) {
      setState({ kind: 'notFound' });
      return;
    }
    let active = true;
    setState({ kind: 'loading' });
    resolve(slug)
      .then((queueId) => {
        if (active) setState({ kind: 'found', queueId });
      })
      .catch((err) => {
        if (active) setState({ kind: slugErrorKind(err) });
      });
    return () => {
      active = false;
    };
  }, [slug, attempt]);

  const retry = useCallback(() => setAttempt((n) => n + 1), []);

  if (state.kind === 'found') {
    return <Navigate to={queuePathFor(state.queueId)} replace />;
  }

  if (state.kind === 'notFound') {
    return (
      <div className="center-col fade-in">
        <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700 }}>
          {t('queue.notFound')}
        </h1>
        <p className="muted">{t('queue.notFoundHint')}</p>
      </div>
    );
  }

  if (state.kind === 'retry') {
    return (
      <div className="center-col fade-in" role="alert">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('slug.failed')}</h1>
        <p className="muted">{t('slug.failedHint')}</p>
        <button type="button" className="btn btn-primary" onClick={retry}>
          {t('slug.retry')}
        </button>
      </div>
    );
  }

  return (
    <div className="center-col" role="status" aria-live="polite">
      <p className="muted">{t('slug.opening')}</p>
    </div>
  );
}
