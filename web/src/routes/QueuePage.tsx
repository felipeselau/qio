import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { onAuthStateChanged, signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';
import { getStoredEntryId, clearStoredEntryId } from '../lib/storage';
import { joinQueue, leaveQueue, saveFcmToken } from '../lib/join';
import { getFcmToken, listenForMessages } from '../lib/fcm';
import { useQueue } from '../lib/useQueue';
import { formatPhone, isValidPhone } from '../lib/format';

type Phase = 'loading' | 'join' | 'ticket' | 'called' | 'left' | 'closed' | 'gone';

export default function QueuePage() {
  const { queueId = '' } = useParams();
  const [authed, setAuthed] = useState(false);
  const [entryId, setEntryId] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmLeave, setConfirmLeave] = useState(false);
  const [leaving, setLeaving] = useState(false);
  const [fcmDone, setFcmDone] = useState(false);

  const {
    meta,
    myEntry,
    myEntryResolved,
    position,
    estimatedWaitMin,
    loading,
    exists,
  } = useQueue(queueId, entryId);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (user) => {
      if (user) {
        setAuthed(true);
        setEntryId(getStoredEntryId(queueId));
      } else {
        signInAnonymously(auth).catch(() => setError('Falha na autenticação'));
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
      setError('Informe seu nome');
      return;
    }
    if (phone.trim() && !isValidPhone(phone.trim())) {
      setError('Telefone inválido. Use o formato (00) 00000-0000');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const result = await joinQueue(queueId, name.trim(), phone.trim());
      setEntryId(result.entryId);
    } catch (err: any) {
      setError(err?.message ?? 'Não foi possível entrar na fila');
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
      setConfirmLeave(false);
    } catch (err: any) {
      setError(err?.message ?? 'Não foi possível sair da fila');
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
    if (loading || !authed) return 'loading';
    if (!exists) return 'gone';
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
    return (
      <div className="center-col">
        <div className="spinner" />
      </div>
    );
  }

  if (phase === 'gone') {
    return (
      <div className="center-col">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>Fila não encontrada</h1>
        <p className="muted">Verifique o link ou escaneie o QR code novamente.</p>
      </div>
    );
  }

  if (phase === 'closed') {
    return (
      <div className="center-col">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>{meta?.name}</h1>
        <span className="badge badge-closed">Fechada</span>
        <p className="muted">Esta fila não está recebendo novos participantes.</p>
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
        <h1 style={{ fontSize: 24, fontWeight: 700 }}>É a sua vez!</h1>
        <p style={{ fontSize: 18, fontWeight: 600 }}>
          Senha #{myEntry.ticket}
        </p>
        <p style={{ fontSize: 14, opacity: 0.9 }}>
          Dirija-se ao atendimento.
        </p>
      </div>
    );
  }

  if (phase === 'left') {
    return (
      <div className="center-col">
        <h1 style={{ fontSize: 20, fontWeight: 700 }}>Você saiu da fila</h1>
        <p className="muted">Obrigado por avisar.</p>
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
              SUA SENHA
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
                Posição
              </span>
              <span style={{ fontSize: 14, fontWeight: 600 }}>
                {position != null ? `${position}º` : '—'}
              </span>
            </div>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
              }}
            >
              <span style={{ fontSize: 14, color: 'var(--gray-dark)' }}>
                Espera estimada
              </span>
              <span style={{ fontSize: 14, fontWeight: 600 }}>
                {estimatedWaitMin != null ? `~${estimatedWaitMin} min` : '—'}
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
              Mantenha esta página aberta. Você será avisado quando chegar sua vez.
            </p>
          </div>

          {confirmLeave ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              <p
                style={{
                  fontSize: 14,
                  color: 'var(--gray-dark)',
                  textAlign: 'center',
                }}
              >
                Tem certeza? Você perderá sua posição na fila.
              </p>
              <button
                type="button"
                className="btn btn-danger"
                disabled={leaving}
                onClick={handleLeave}
              >
                {leaving ? 'Saindo...' : 'Confirmar saída'}
              </button>
              <button
                type="button"
                className="btn btn-secondary"
                disabled={leaving}
                onClick={() => setConfirmLeave(false)}
              >
                Cancelar
              </button>
            </div>
          ) : (
            <button
              type="button"
              className="btn btn-danger-ghost"
              onClick={() => setConfirmLeave(true)}
            >
              Sair da fila
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
              ? 'Pausada'
              : meta?.status === 'closed'
                ? 'Fechada'
                : 'Aberta'}
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
            <label htmlFor="name">Nome *</label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Seu nome"
              autoComplete="name"
            />
          </div>
          <div className="field">
            <label htmlFor="phone">Telefone</label>
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
            {submitting ? 'Entrando...' : 'Entrar na fila'}
          </button>
        </form>
      </div>
    </div>
  );
}