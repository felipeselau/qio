import type { Analytics } from 'firebase/analytics';
import { app } from '../firebase';

export const ANALYTICS_OPT_OUT_KEY = 'qio:analytics-optout';

export type AnalyticsEventName = 'queue_joined' | 'feedback_sent';

export function isAnalyticsOptedOut(): boolean {
  try {
    return localStorage.getItem(ANALYTICS_OPT_OUT_KEY) === '1';
  } catch {
    return false;
  }
}

export function setAnalyticsOptOut(value: boolean): void {
  try {
    if (value) localStorage.setItem(ANALYTICS_OPT_OUT_KEY, '1');
    else localStorage.removeItem(ANALYTICS_OPT_OUT_KEY);
  } catch {
  }
}

function doNotTrack(): boolean {
  const nav = navigator as Navigator & { msDoNotTrack?: string };
  const win = window as Window & { doNotTrack?: string };
  return [nav.doNotTrack, win.doNotTrack, nav.msDoNotTrack].some(
    (v) => v === '1' || v === 'yes',
  );
}

export function analyticsConfigured(): boolean {
  return (
    import.meta.env.PROD &&
    import.meta.env.VITE_USE_EMULATORS !== 'true' &&
    Boolean(import.meta.env.VITE_MEASUREMENT_ID) &&
    !doNotTrack()
  );
}

export function analyticsAllowed(): boolean {
  return analyticsConfigured() && !isAnalyticsOptedOut();
}

let _analytics: Promise<Analytics | null> | undefined;

function getAnalyticsSafe(): Promise<Analytics | null> {
  if (_analytics) return _analytics;
  _analytics = (async () => {
    try {
      const mod = await import('firebase/analytics');
      if (!(await mod.isSupported())) return null;
      return mod.initializeAnalytics(app, {
        config: {
          send_page_view: false,
          allow_google_signals: false,
          allow_ad_personalization_signals: false,
        },
      });
    } catch {
      return null;
    }
  })();
  return _analytics;
}

export function trackEvent(name: AnalyticsEventName, queueId: string): void {
  if (!analyticsAllowed()) return;
  void (async () => {
    try {
      const analytics = await getAnalyticsSafe();
      if (!analytics) return;
      const { logEvent } = await import('firebase/analytics');
      logEvent(analytics, name, { queue_id: queueId });
    } catch {
    }
  })();
}
