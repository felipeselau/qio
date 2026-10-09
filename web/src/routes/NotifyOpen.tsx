import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { pushSupport, requestPushPermission, type PushSupport } from '../lib/fcm';
import { isWatchingOpen, unwatchOpen, watchOpen } from '../lib/openWatch';

type Status = 'idle' | 'busy' | 'on' | 'denied' | 'error';

export default function NotifyOpen({ queueId }: { queueId: string }) {
  const { t } = useTranslation();
  const [support, setSupport] = useState<PushSupport | null>(null);
  const [status, setStatus] = useState<Status>('idle');
  const [canceling, setCanceling] = useState(false);

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
    setCanceling(true);
    try {
      await unwatchOpen(queueId);
      setStatus('idle');
    } catch {
      setStatus('on');
    } finally {
      setCanceling(false);
    }
  }

  let content = null;
  if (support === null || support === 'unsupported') {
    content = null;
  } else if (status === 'denied') {
    content = (
      <p className="muted" role="status" style={{ textAlign: 'center' }}>
        {t('queue.notifyOpenDenied')}
      </p>
    );
  } else if (status === 'on') {
    content = (
      <div className="notice">
        <span>{t('queue.notifyOpenOn')}</span>
        <button
          type="button"
          className="btn btn-secondary"
          onClick={disable}
          disabled={canceling}
          aria-busy={canceling}
        >
          {t('queue.notifyOpenCancel')}
        </button>
      </div>
    );
  } else {
    content = (
      <div className="notice" role="group" aria-label={t('queue.notifyOpen')}>
        <span>{t('queue.notifyOpenHint')}</span>
        <button
          type="button"
          className="btn btn-secondary"
          onClick={enable}
          disabled={status === 'busy'}
          aria-busy={status === 'busy'}
        >
          {t('queue.notifyOpen')}
        </button>
        {status === 'error' && (
          <span className="error-text" role="alert">{t('queue.notifyOpenFailed')}</span>
        )}
      </div>
    );
  }

  return (
    <div aria-live="polite" aria-atomic="true">
      {content}
    </div>
  );
}
