import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { pushSupport, requestPushPermission, type PushSupport } from '../lib/fcm';
import { isWatchingOpen, unwatchOpen, watchOpen } from '../lib/openWatch';

type Status = 'idle' | 'busy' | 'on' | 'denied' | 'error';

export default function NotifyOpen({ queueId }: { queueId: string }) {
  const { t } = useTranslation();
  const [support, setSupport] = useState<PushSupport | null>(null);
  const [status, setStatus] = useState<Status>('idle');

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const state = await pushSupport();
      if (cancelled) return;
      setSupport(state);
      if (state === 'denied') setStatus('denied');
      if (state !== 'granted') return;
      try {
        if (await isWatchingOpen(queueId)) {
          if (!cancelled) setStatus('on');
        }
      } catch {
        return;
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [queueId]);

  if (support === null || support === 'unsupported') return null;

  async function enable() {
    setStatus('busy');
    try {
      if (Notification.permission !== 'granted') {
        const result = await requestPushPermission();
        if (result === 'denied') {
          setStatus('denied');
          return;
        }
      }
      setStatus((await watchOpen(queueId)) ? 'on' : 'error');
    } catch {
      setStatus('error');
    }
  }

  async function disable() {
    setStatus('busy');
    try {
      await unwatchOpen(queueId);
      setStatus('idle');
    } catch {
      setStatus('on');
    }
  }

  if (status === 'denied') {
    return <p className="muted" style={{ textAlign: 'center' }}>{t('queue.notifyOpenDenied')}</p>;
  }

  if (status === 'on') {
    return (
      <div className="notice" role="status">
        <span>{t('queue.notifyOpenOn')}</span>
        <button type="button" className="btn btn-secondary" onClick={disable}>
          {t('queue.notifyOpenCancel')}
        </button>
      </div>
    );
  }

  return (
    <div className="notice" role="group" aria-label={t('queue.notifyOpen')}>
      <span>{t('queue.notifyOpenHint')}</span>
      <button
        type="button"
        className="btn btn-secondary"
        onClick={enable}
        disabled={status === 'busy'}
      >
        {t('queue.notifyOpen')}
      </button>
      {status === 'error' && (
        <span className="error-text" role="alert">{t('queue.notifyOpenFailed')}</span>
      )}
    </div>
  );
}
