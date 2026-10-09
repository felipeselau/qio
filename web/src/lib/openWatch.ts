import { get, ref, remove, serverTimestamp, set } from 'firebase/database';
import { auth, db } from '../firebase';
import i18n from '../i18n';
import { LANGUAGES, type Language } from '../i18n/resolveLanguage';
import { getFcmToken } from './fcm';

export const WATCH_TTL_MS = 24 * 60 * 60 * 1000;

export function watcherLang(language: string | undefined): Language {
  const base = (language ?? '').toLowerCase().split('-')[0];
  return (LANGUAGES as readonly string[]).includes(base) ? (base as Language) : 'pt';
}

export function isWatchActive(createdAt: unknown, now: number): boolean {
  return typeof createdAt === 'number' && now - createdAt <= WATCH_TTL_MS;
}

function watcherRef(queueId: string) {
  const uid = auth.currentUser?.uid;
  if (!uid) throw new Error(i18n.t('errors.notAuthenticated'));
  return ref(db, `queues/${queueId}/openWatchers/${uid}`);
}

export async function isWatchingOpen(queueId: string): Promise<boolean> {
  const snap = await get(watcherRef(queueId));
  return snap.exists() && isWatchActive(snap.val()?.createdAt, Date.now());
}

export async function watchOpen(queueId: string): Promise<boolean> {
  const token = await getFcmToken();
  if (!token) return false;
  await set(watcherRef(queueId), {
    fcmToken: token,
    lang: watcherLang(i18n.language),
    createdAt: serverTimestamp(),
  });
  return true;
}

export async function unwatchOpen(queueId: string): Promise<void> {
  await remove(watcherRef(queueId));
}
