import { ref, update } from 'firebase/database';
import { httpsCallable } from 'firebase/functions';
import { auth, db, getFunctionsSafe } from '../firebase';
import { storeEntryId } from './storage';

export type JoinResult = { entryId: string; ticket: number; existing: boolean };

const JOIN_ERROR_MESSAGES: Record<string, string> = {
  'functions/already-exists': 'Este telefone já está na fila.',
  'functions/resource-exhausted': 'Muitas tentativas. Aguarde alguns minutos.',
  'functions/failed-precondition': 'Fila fechada ou pausada.',
  'functions/invalid-argument': 'Dados inválidos. Confira nome e telefone.',
  'functions/not-found': 'Fila não encontrada.',
};

const JOIN_ERROR_FALLBACK = 'Não foi possível entrar na fila. Tente novamente.';

export async function joinQueue(
  queueId: string,
  name: string,
  phone: string,
): Promise<JoinResult> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error('Não autenticado');

  let result: JoinResult;
  try {
    const call = httpsCallable<
      { queueId: string; name: string; phone: string },
      JoinResult
    >(getFunctionsSafe(), 'joinQueue');
    result = (await call({ queueId, name, phone })).data;
  } catch (err) {
    const code = (err as { code?: string } | null)?.code ?? '';
    throw new Error(JOIN_ERROR_MESSAGES[code] ?? JOIN_ERROR_FALLBACK);
  }

  storeEntryId(queueId, result.entryId);
  return result;
}

export async function leaveQueue(queueId: string, entryId: string): Promise<void> {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error('Não autenticado');
  await update(ref(db, `queues/${queueId}/entries/${entryId}`), {
    status: 'left',
  });
}

export async function saveFcmToken(
  queueId: string,
  entryId: string,
  token: string,
): Promise<void> {
  await update(ref(db, `queues/${queueId}/entries/${entryId}`), {
    fcmToken: token,
  });
}
