import { useCallback, useEffect, useRef, useState } from 'react';
import { useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { onAuthStateChanged, signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';
import {
  getStoredEntryId,
  clearStoredEntryId,
  getPendingFeedback,
  storePendingFeedback,
  clearPendingFeedback,
} from '../lib/storage';
import { derivePhase, shouldClearStoredEntry, type Phase } from '../lib/phase';
import { joinQueue, leaveQueue, saveFcmToken, submitFeedback } from '../lib/join';
import {
  getFcmToken,
  listenForMessages,
  pushSupport,
  requestPushPermission,
  type PushSupport,
} from '../lib/fcm';
import { useQueue } from '../lib/useQueue';
import { isValidPhone, waitRange } from '../lib/format';
import { playAlertSound, unlockAudio } from '../lib/alert';
import { holdWakeLock } from '../lib/wakeLock';
import { useInstallPrompt } from '../lib/useInstallPrompt';
import { buildSlotOptions } from '../lib/slots';
import CalledView from './queue/CalledView';
import FeedbackView from './queue/FeedbackView';
import JoinForm from './queue/JoinForm';
import TicketView from './queue/TicketView';
import {
  ClosedView,
  ErrorView,
  GoneView,
  LeftView,
  LoadingView,
  ThanksView,
} from './queue/StateViews';

export default function QueuePage() {
  const { t } = useTranslation();
  const { queueId = '' } = useParams();
  const [slotId, setSlotId] = useState<string | null>(null);
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30000);
    return () => window.clearInterval(timer);
  }, []);
  const [authed, setAuthed] = useState(false);
  const [entryId, setEntryId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmLeave, setConfirmLeave] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [hasLeft, setHasLeft] = useState(false);
  const [claimed, setClaimed] = useState(false);
  const [fcmDone, setFcmDone] = useState(false);
  const installPrompt = useInstallPrompt();
  const [feedbackId, setFeedbackId] = useState<string | null>(() => getPendingFeedback(queueId));
  const [rating, setRating] = useState(0);
  const [comment, setComment] = useState('');
  const [sendingFeedback, setSendingFeedback] = useState(false);
  const [thanked, setThanked] = useState(false);

  const {
    meta,
    myEntry,
    myEntryResolved,
    position,
    estimatedWaitMin,
    waitingCount,
    avgServiceMin,
    publicReady,
    publicTickets,
    full,
    loading,
    exists,
    failed,
    retry,
  } = useQueue(queueId, entryId, authed);

  const scheduled = meta?.mode === 'schedule';
  const slotOptions = buildSlotOptions(meta?.slots ?? [], publicTickets, now);
  const selectedOption = slotOptions.find((o) => o.slot.id === slotId);
  const selectedUnavailable = !!selectedOption && (selectedOption.past || selectedOption.slotFull);

  const brandColor = meta?.brandColor ?? null;
  useEffect(() => {
    const root = document.documentElement;
    if (brandColor) root.style.setProperty('--brand', brandColor);
    else root.style.removeProperty('--brand');
    return () => {
      root.style.removeProperty('--brand');
    };
  }, [brandColor]);

  const queueName = meta?.name ?? null;
  useEffect(() => {
    if (!queueName) return;
    const previous = document.title;
    document.title = `${queueName} · Qio`;
    return () => {
      document.title = previous;
    };
  }, [queueName]);

  const range = waitRange(waitingCount + 1, avgServiceMin);
  const waitSummary =
    waitingCount === 0
      ? t('queue.noQueueNow')
      : range
        ? t('queue.aheadSummary', { count: waitingCount, min: range.min, max: range.max })
        : t('queue.aheadCount', { count: waitingCount });

  const [authFailed, setAuthFailed] = useState(false);
  const [focusTick, setFocusTick] = useState(0);
  const [authAttempt, setAuthAttempt] = useState(0);
  function handleRetry() {
    setAuthFailed(false);
    setAuthAttempt((n) => n + 1);
    setFocusTick((n) => n + 1);
    retry();
  }
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
  }, [queueId, authAttempt]);

  // limpa entryId local se a entry sumiu do RTDB (served/no_show/left).
  // myEntryResolved garante que o listener já entregou o primeiro valor —
  // sem isso, o gap entre setEntryId e o primeiro onValue limparia a entry
  // recém-criada (bug: permitia re-entrar na fila infinitamente).
  useEffect(() => {
    if (
      shouldClearStoredEntry({
        entryId,
        hasEntry: myEntry !== null,
        resolved: myEntryResolved,
        loading,
        authed,
        storedEntryId: getStoredEntryId(queueId),
      })
    ) {
      clearStoredEntryId(queueId);
      setEntryId(null);
    }
  }, [myEntry, myEntryResolved, entryId, loading, authed, queueId]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    unlockAudio();
    if (!name.trim()) {
      setError(t('errors.nameRequired'));
      return;
    }
    if (phone.trim() && !isValidPhone(phone.trim())) {
      setError(t('errors.phoneInvalid'));
      return;
    }
    if (scheduled && (!slotId || selectedUnavailable)) {
      setError(t('queue.slotRequired'));
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const result = await joinQueue(
        queueId,
        name.trim(),
        phone.trim(),
        scheduled ? slotId : null,
      );
      setClaimed(result.claimed === true);
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

  function handleRejoin() {
    clearStoredEntryId(queueId);
    setEntryId(null);
    setClaimed(false);
    setHasLeft(false);
    setLeaving(false);
    setConfirmLeave(false);
    setError(null);
    setFcmDone(false);
    setPush('unsupported');
    setPushBusy(false);
    setThanked(false);
    setRating(0);
    setComment('');
    setFeedbackId(null);
    clearPendingFeedback(queueId);
    setFocusTick((n) => n + 1);
  }

  function playAlert() {
    playAlertSound();
    if (navigator.vibrate) navigator.vibrate([400, 200, 400]);
  }

  const phase: Phase = derivePhase({
    loading,
    authed,
    failed,
    exists,
    hasLeft,
    metaStatus: meta?.status,
    myEntryStatus: myEntry?.status,
    hasEntry: !!myEntry,
    thanked,
    feedbackId,
  });

  const recalledAt = myEntry?.recalledAt ?? null;
  const lastRecall = useRef<number | null>(null);
  useEffect(() => {
    if (phase !== 'called') {
      lastRecall.current = recalledAt;
      return;
    }
    if (recalledAt && lastRecall.current !== recalledAt) {
      playAlert();
    }
    lastRecall.current = recalledAt;
  }, [phase, recalledAt]);

  // dispara som/vibração quando entra em 'called'
  const [alerted, setAlerted] = useState(false);
  useEffect(() => {
    if (phase === 'called' && !alerted) {
      playAlert();
      setAlerted(true);
    }
    if (phase !== 'called') setAlerted(false);
  }, [phase, alerted]);

  useEffect(() => {
    if (phase === 'called' && entryId) {
      storePendingFeedback(queueId, entryId);
      setFeedbackId(entryId);
    }
  }, [phase, entryId, queueId]);

  async function handleFeedbackSend() {
    if (!feedbackId || rating < 1) return;
    setSendingFeedback(true);
    setError(null);
    try {
      await submitFeedback(queueId, feedbackId, rating, comment.trim());
      clearPendingFeedback(queueId);
      setFeedbackId(null);
      setThanked(true);
    } catch (err: any) {
      setError(err?.message ?? t('errors.feedbackFailed'));
    } finally {
      setSendingFeedback(false);
    }
  }

  function handleFeedbackSkip() {
    clearPendingFeedback(queueId);
    setFeedbackId(null);
    setError(null);
  }

  const [push, setPush] = useState<PushSupport>('unsupported');
  const [pushBusy, setPushBusy] = useState(false);

  const [calledAnnounce, setCalledAnnounce] = useState('');
  const calledTicket = myEntry?.ticket;
  useEffect(() => {
    if (phase !== 'called') {
      setCalledAnnounce('');
      return;
    }
    const timer = window.setTimeout(
      () =>
        setCalledAnnounce(
          `${t('queue.yourTurn')} ${t('queue.ticketNumber', { ticket: calledTicket })}`,
        ),
      150,
    );
    return () => window.clearTimeout(timer);
  }, [phase, calledTicket, t]);

  const screenKey = phase === 'loading' ? (authFailed || failed ? 'error' : 'loading') : phase;
  useEffect(() => {
    if (screenKey === 'loading') return;
    document
      .querySelector<HTMLElement>('[data-autofocus]')
      ?.focus({ preventScroll: true });
  }, [screenKey, focusTick]);

  const registerToken = useCallback(() => {
    if (!entryId) return;
    getFcmToken()
      .then((token) => {
        if (token) saveFcmToken(queueId, entryId, token).catch(() => {});
      })
      .catch(() => setPush('unavailable'));
  }, [entryId, queueId]);

  useEffect(() => {
    if (phase !== 'ticket' || !myEntry || !entryId || fcmDone) return;
    setFcmDone(true);
    pushSupport().then((state) => {
      setPush(state);
      if (state === 'granted') registerToken();
    });
  }, [phase, myEntry, entryId, fcmDone, registerToken]);

  useEffect(() => {
    if (phase !== 'ticket' && phase !== 'called') return;
    const release = holdWakeLock();
    const unlock = () => unlockAudio();
    window.addEventListener('pointerdown', unlock, { once: true });
    window.addEventListener('keydown', unlock, { once: true });
    return () => {
      release();
      window.removeEventListener('pointerdown', unlock);
      window.removeEventListener('keydown', unlock);
    };
  }, [phase]);

  async function enablePush() {
    unlockAudio();
    setPushBusy(true);
    try {
      const result = await requestPushPermission();
      setPush(result);
      if (result === 'granted') registerToken();    } finally {
      setPushBusy(false);
    }
  }

  // notificação foreground (page oculta) — RTDB já cuida do estado em tela
  useEffect(() => {
    return listenForMessages(() => {});
  }, []);


  if (phase === 'loading') {
    if (authFailed || failed) return <ErrorView onRetry={handleRetry} />;
    return <LoadingView />;
  }

  if (phase === 'gone') return <GoneView />;

  if (phase === 'closed') return <ClosedView meta={meta} queueId={queueId} />;

  if (phase === 'called' && myEntry) {
    return (
      <CalledView
        meta={meta}
        ticket={myEntry.ticket}
        calledAt={myEntry.calledAt}
        announce={calledAnnounce}
      />
    );
  }

  if (phase === 'thanks') return <ThanksView />;

  if (phase === 'feedback') {
    return (
      <FeedbackView
        rating={rating}
        comment={comment}
        sending={sendingFeedback}
        error={error}
        onRating={setRating}
        onComment={setComment}
        onSend={handleFeedbackSend}
        onSkip={handleFeedbackSkip}
      />
    );
  }

  if (phase === 'left') return <LeftView onRejoin={handleRejoin} />;

  if (phase === 'ticket' && myEntry) {
    return (
      <TicketView
        meta={meta}
        ticket={myEntry.ticket}
        slotStart={myEntry.slotStart}
        scheduled={scheduled}
        claimed={claimed}
        position={position}
        estimatedWaitMin={estimatedWaitMin}
        push={push}
        pushBusy={pushBusy}
        onEnablePush={enablePush}
        installPrompt={installPrompt}
        confirmLeave={confirmLeave}
        leaving={leaving}
        error={error}
        onAskLeave={() => setConfirmLeave(true)}
        onCancelLeave={() => setConfirmLeave(false)}
        onLeave={handleLeave}
      />
    );
  }

  return (
    <JoinForm
      queueId={queueId}
      meta={meta}
      full={full}
      scheduled={scheduled}
      publicReady={publicReady}
      waitSummary={waitSummary}
      slotOptions={slotOptions}
      slotId={slotId}
      selectedUnavailable={selectedUnavailable}
      name={name}
      phone={phone}
      submitting={submitting}
      error={error}
      onName={setName}
      onPhone={setPhone}
      onSlot={setSlotId}
      onSubmit={handleSubmit}
    />
  );
}
