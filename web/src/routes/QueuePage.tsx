import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { onAuthStateChanged, signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';
import { getStoredEntryId, clearStoredEntryId } from '../lib/storage';
import { joinQueue, leaveQueue, saveFcmToken } from '../lib/join';
import { getFcmToken, listenForMessages } from '../lib/fcm';
import { useQueue } from '../lib/useQueue';
import { formatPhone, isValidPhone } from '../lib/format';
import { useInstallPrompt } from '../lib/useInstallPrompt';

type Phase = 'loading' | 'join' | 'ticket' | 'called' | 'left' | 'closed' | 'gone';

export default function QueuePage() {
  const { t } = useTranslation();
  const { queueId = '' } = useParams();
  const [authed, setAuthed] = useState(false);
  const [entryId, setEntryId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmLeave, setConfirmLeave] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [hasLeft, setHasLeft] = useState(false);
  const [fcmDone, setFcmDone] = useState(false);
  const installPrompt = useInstallPrompt();

  const {
    meta,
    myEntry,
    myEntryResolved,
    position,
    estimatedWaitMin,
    loading,
    exists,
    failed,
  } = useQueue(queueId, entryId, authed);

  const [authFailed, setAuthFailed] = useState(false);
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (user) => {
      if (user) {
        setAuthed(true);
        setAuthFailed(false);
        setEntryId(getStoredEntryId(queueId));
      } else {
        signInAnonymously(auth).catch(() => setAuthFailed(true));
      }
    });
    return unsub;
  }, [queueId]);

  // limpa entryId local se a entry sumiu do RTDB (served/no_show/left).
  // myEntryResolved garante que o listener já entregou o primeiro valor —
  // sem isso, o gap entre setEntryId e o primeiro onValue limparia a entry
  // recém-criada (bug: permitia re-entrar na fila infinitamente).
  useEffect(() => {
    if (entryId && myEntry === null && myEntryResolved && !loading && authed) {
      const had = getStoredEntryId(queueId);
      if (had === entryId) {
        clearStoredEntryId(queueId);
        setEntryId(null);
      }
    }
  }, [myEntry, myEntryResolved, entryId, loading, authed, queueId]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) {
      setError(t('errors.nameRequired'));
      return;
    }
    if (phone.trim() && !isValidPhone(phone.trim())) {
      setError(t('errors.phoneInvalid'));
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const result = await joinQueue(queueId, name.trim(), phone.trim());
      setEntryId(result.entryId);
    } catch (err: any) {
      setError(err?.message ?? t('errors.joinFailed'));
    } finally {
      setSubmitting(false);
    }
  }

  async function handleLeave() {
    if (!entryId) return;
    setLeaving(true);
    setError(null);
    try {
      await leaveQueue(queueId, entryId);
      setHasLeft(true);
      setConfirmLeave(false);
    } catch (err: any) {
      setError(err?.message ?? t('errors.leaveFailed'));
      setLeaving(false);
    }
  }

  function playAlert() {
    try {
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.frequency.value = 880;
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.2);
      osc.start();
      osc.stop(ctx.currentTime + 1.2);
    } catch {
      // ignore
    }
    if (navigator.vibrate) navigator.vibrate([400, 200, 400]);
  }

  const phase: Phase = (() => {
    if (loading || !authed || failed) return 'loading';
    if (!exists) return 'gone';
    if (hasLeft) return 'left';
    if (meta?.status === 'closed' && !myEntry) return 'closed';
    if (!myEntry) return 'join';
    if (myEntry.status === 'called') {
      // dispara alerta uma vez ao entrar no estado
      return 'called';
    }
    if (myEntry.status === 'left') return 'left';
    return 'ticket';
  })();

  // dispara som/vibração quando entra em 'called'
  const [alerted, setAlerted] = useState(false);
  useEffect(() => {
    if (phase === 'called' && !alerted) {
      playAlert();
      setAlerted(true);
    }
    if (phase !== 'called') setAlerted(false);
  }, [phase, alerted]);

  // salva o FCM token da entry na tela do ticket (uma vez por entry)
  useEffect(() => {
    if (phase === 'ticket' && myEntry && entryId && !fcmDone) {
      setFcmDone(true);
      getFcmToken().then((token) => {
        if (token) {
          saveFcmToken(queueId, entryId, token).catch(() => {});
        }
      });
    }
  }, [phase, myEntry, entryId, fcmDone, queueId]);

  // notificação foreground (page oculta) — RTDB já cuida do estado em tela
  useEffect(() => {
    return listenForMessages(() => {});
  }, []);

  if (phase === 'loading') {
    if (authFailed || failed) {
      return (
        <div className="center-col">
          <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.connectFailed')}</h1>
          <p className="muted">{t('queue.connectFailedHint')}</p>
        </div>
      );
    }
    return (
      <div className="center-col">
        <div className="spinner" />
      </div>
    );
  }

  if (phase === 'gone') {
    return (
      <div className="center-col">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.notFound')}</h1>
        <p className="muted">{t('queue.notFoundHint')}</p>
      </div>
    );
  }

  if (phase === 'closed') {
    return (
      <div className="center-col">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{meta?.name}</h1>
        <span className="badge badge-closed">{t('queue.closedBadge')}</span>
        <p className="muted">{t('queue.closedHint')}</p>
      </div>
    );
  }

  if (phase === 'called' && myEntry) {
    return (
      <div
        style={{
          background: 'var(--secondary)',
          minHeight: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 16,
          padding: 32,
          textAlign: 'center',
          color: 'var(--white)',
        }}
      >
        <div style={{ fontSize: 72 }}>✓</div>
        <h1 style={{ fontSize: 24, fontWeight: 700 }}>{t('queue.yourTurn')}</h1>
        <p style={{ fontSize: 18, fontWeight: 600 }}>
          {t('queue.ticketNumber', { ticket: myEntry.ticket })}
        </p>
        <p style={{ fontSize: 14, opacity: 0.9 }}>
          {t('queue.goToService')}
        </p>
      </div>
    );
  }

  if (phase === 'left') {
    return (
      <div className="center-col">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{t('queue.left')}</h1>
        <p className="muted">{t('queue.leftHint')}</p>
      </div>
    );
  }

  if (phase === 'ticket' && myEntry) {
    return (
      <div className="page">
        <div className="page-scroll">
          <div className="card" style={{ textAlign: 'center', padding: 24 }}>
            <p
              style={{
                fontSize: 12,
                fontWeight: 500,
                color: 'var(--gray-medium)',
                letterSpacing: 1,
              }}
            >
              {t('queue.yourTicket')}
            </p>
            <p style={{ fontSize: 48, fontWeight: 800, color: 'var(--primary)' }}>
              #{myEntry.ticket}
            </p>
            <p style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
              {meta?.name}
            </p>
          </div>

          <div className="card">
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                marginBottom: 8,
              }}
            >
              <span style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
                {t('queue.position')}
              </span>
              <span style={{ fontSize: 14, fontWeight: 600 }}>
                {position != null ? t('queue.positionValue', { position }) : '—'}
              </span>
            </div>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
              }}
            >
              <span style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
                {t('queue.estimatedWait')}
              </span>
              <span style={{ fontSize: 14, fontWeight: 600 }}>
                {estimatedWaitMin != null
                  ? t('queue.estimatedWaitValue', { minutes: estimatedWaitMin })
                  : '—'}
              </span>
            </div>
          </div>

          <div
            style={{
              background: 'rgba(37, 99, 235, 0.1)',
              borderRadius: 12,
              padding: 16,
              display: 'flex',
              gap: 12,
              alignItems: 'flex-start',
            }}
          >
            <span style={{ fontSize: 20 }}>ℹ️</span>
            <p style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
              {t('queue.keepOpen')}
            </p>
          </div>

          {(installPrompt.canInstall || installPrompt.hint) && (
            <section className="install-banner" role="region" aria-label={t('queue.installAria')}>
              {installPrompt.canInstall ? (
                <>
                  <p>{t('queue.installText')}</p>
                  <div className="install-banner-actions">
                    <button
                      type="button"
                      className="btn btn-primary"
                      onClick={installPrompt.install}
                    >
                      {t('queue.install')}
                    </button>
                    <button
                      type="button"
                      className="btn btn-secondary"
                      onClick={installPrompt.dismiss}
                    >
                      {t('queue.notNow')}
                    </button>
                  </div>
                </>
              ) : (
                <>
                  <p>
                    {installPrompt.hint === 'ios'
                      ? t('queue.installIos')
                      : t('queue.installAndroid')}
                  </p>
                  <div className="install-banner-actions">
                    <button
                      type="button"
                      className="btn btn-secondary"
                      onClick={installPrompt.dismiss}
                    >
                      {t('queue.gotIt')}
                    </button>
                  </div>
                </>
              )}
            </section>
          )}

          {confirmLeave ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <p
                style={{
                  fontSize: 14,
                  color: 'var(--gray-dark)',
                  textAlign: 'center',
                }}
              >
                {t('queue.confirmLeaveText')}
              </p>
              <button
                type="button"
                className="btn btn-danger"
                disabled={leaving}
                onClick={handleLeave}
              >
                {leaving ? t('queue.leaving') : t('queue.confirmLeave')}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                disabled={leaving}
                onClick={() => setConfirmLeave(false)}
              >
                {t('queue.cancel')}
              </button>
            </div>
          ) : (
            <button
              type="button"
              className="btn btn-danger-ghost"
              onClick={() => setConfirmLeave(true)}
            >
              {t('queue.leave')}
            </button>
          )}
          {error && <p className="error-text">{error}</p>}
        </div>
      </div>
    );
  }

  // phase === 'join'
  return (
    <div className="page">
      <div className="page-scroll">
        <div style={{ textAlign: 'center', marginBottom: 8 }}>
          <h1 style={{ fontSize: 24, fontWeight: 700 }}>{meta?.name}</h1>
          <span
            className={`badge badge-${meta?.status ?? 'open'}`}
            style={{ marginTop: 8 }}
          >
            {meta?.status === 'paused'
              ? t('queue.statusPaused')
              : meta?.status === 'closed'
                ? t('queue.statusClosed')
                : t('queue.statusOpen')}
          </span>
        </div>

        {meta?.description && (
          <p style={{ fontSize: 14, color: 'var(--gray-dark)', textAlign: 'center' }}>
            {meta.description}
          </p>
        )}

        <form
          onSubmit={handleSubmit}
          style={{ display: 'flex', flexDirection: 'column', gap: 16 }}
        >
          <div className="field">
            <label htmlFor="name">{t('queue.nameLabel')}</label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder={t('queue.namePlaceholder')}
              autoComplete="name"
              maxLength={60}
            />
          </div>
          <div className="field">
            <label htmlFor="phone">{t('queue.phoneLabel')}</label>
            <input
              id="phone"
              type="tel"
              value={phone}
              onChange={(e) => setPhone(formatPhone(e.target.value))}
              placeholder="(00) 00000-0000"
              autoComplete="tel"
            />
          </div>
          {error && <p className="error-text">{error}</p>}
          <button
            type="submit"
            className="btn btn-primary"
            disabled={submitting || meta?.status !== 'open'}
          >
            {submitting ? t('queue.joining') : t('queue.join')}
          </button>
        </form>
      </div>
    </div>
  );
}