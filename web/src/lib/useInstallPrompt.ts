import { useCallback, useEffect, useState } from 'react';

const DISMISS_KEY = 'qio:install-dismissed';

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
};

export function shouldShowInstallBanner(state: {
  standalone: boolean;
  dismissed: boolean;
  hasPrompt: boolean;
  isIos: boolean;
}): boolean {
  if (state.standalone || state.dismissed) return false;
  return state.hasPrompt || state.isIos;
}

function readDismissed(): boolean {
  try {
    return localStorage.getItem(DISMISS_KEY) === '1';
  } catch {
    return false;
  }
}

function writeDismissed() {
  try {
    localStorage.setItem(DISMISS_KEY, '1');
  } catch {}
}

function detectStandalone(): boolean {
  if (typeof window === 'undefined') return false;
  const nav = navigator as Navigator & { standalone?: boolean };
  return (
    nav.standalone === true ||
    (typeof window.matchMedia === 'function' &&
      window.matchMedia('(display-mode: standalone)').matches)
  );
}

function detectIosSafari(): boolean {
  if (typeof navigator === 'undefined') return false;
  const ua = navigator.userAgent;
  const isIosDevice =
    /iPad|iPhone|iPod/.test(ua) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  if (!isIosDevice) return false;
  return !/CriOS|FxiOS|EdgiOS|OPiOS|GSA/.test(ua);
}

export function useInstallPrompt() {
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null);
  const [dismissed, setDismissed] = useState(readDismissed);
  const [standalone, setStandalone] = useState(detectStandalone);
  const isIos = detectIosSafari();

  useEffect(() => {
    function onBeforeInstall(e: Event) {
      e.preventDefault();
      setDeferred(e as BeforeInstallPromptEvent);
    }
    function onInstalled() {
      setDeferred(null);
      setStandalone(true);
    }
    window.addEventListener('beforeinstallprompt', onBeforeInstall);
    window.addEventListener('appinstalled', onInstalled);
    return () => {
      window.removeEventListener('beforeinstallprompt', onBeforeInstall);
      window.removeEventListener('appinstalled', onInstalled);
    };
  }, []);

  const dismiss = useCallback(() => {
    writeDismissed();
    setDismissed(true);
  }, []);

  const install = useCallback(async () => {
    if (!deferred) return;
    try {
      await deferred.prompt();
      await deferred.userChoice;
    } catch {}
    setDeferred(null);
  }, [deferred]);

  const canInstall = shouldShowInstallBanner({
    standalone,
    dismissed,
    hasPrompt: deferred !== null,
    isIos: false,
  });

  const showIosHint = shouldShowInstallBanner({
    standalone,
    dismissed,
    hasPrompt: false,
    isIos,
  });

  return { canInstall, isIos: showIosHint, install, dismiss };
}
