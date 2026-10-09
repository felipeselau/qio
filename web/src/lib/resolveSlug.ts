import { signInAnonymously } from 'firebase/auth';
import { auth } from '../firebase';

export async function resolveSlugToQueueId(slug: string): Promise<string> {
  await auth.authStateReady();
  if (!auth.currentUser) await signInAnonymously(auth);
  const [{ httpsCallable }, { functions }] = await Promise.all([
    import('firebase/functions'),
    import('../firebaseFunctions'),
  ]);
  const call = httpsCallable<{ slug: string }, { queueId: string }>(functions, 'resolveSlug');
  return (await call({ slug })).data.queueId;
}
