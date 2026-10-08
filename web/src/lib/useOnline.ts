import { useEffect, useState } from 'react';
import { onValue, ref } from 'firebase/database';
import { db } from '../firebase';
import { isEffectivelyOnline } from './connectivity';

export function useOnline(): boolean {
  const [browserOnline, setBrowserOnline] = useState(() => navigator.onLine);
  const [rtdbConnected, setRtdbConnected] = useState<boolean | null>(null);
  const [everConnected, setEverConnected] = useState(false);

  useEffect(() => {
    const up = () => setBrowserOnline(true);
    const down = () => setBrowserOnline(false);
    window.addEventListener('online', up);
    window.addEventListener('offline', down);
    return () => {
      window.removeEventListener('online', up);
      window.removeEventListener('offline', down);
    };
  }, []);

  useEffect(() => {
    const unsub = onValue(
      ref(db, '.info/connected'),
      (snap) => {
        const connected = snap.val() === true;
        setRtdbConnected(connected);
        if (connected) setEverConnected(true);
      },
      () => {},
    );
    return unsub;
  }, []);

  return isEffectivelyOnline(browserOnline, rtdbConnected, everConnected);
}
