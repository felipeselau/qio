import { signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';

let pending: Promise<void> | null = null;

export function ensureSignedIn(): Promise<void> {
  if (!pending) {
    pending = (async () => {
      await auth.authStateReady();
      if (!auth.currentUser) await signInAnonymously(auth);
    })().catch((err) => {
      pending = null;
      throw err;
    });
  }
  return pending;
}

export function resetEnsureSignedInForTests() {
  pending = null;
}
