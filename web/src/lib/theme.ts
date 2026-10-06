import { useCallback, useEffect, useState } from 'react';

const KEY = 'qio:theme';

export type Theme = 'light' | 'dark';

function stored(): Theme | null {
  try {
    const v = localStorage.getItem(KEY);
    return v === 'light' || v === 'dark' ? v : null;
  } catch {
    return null;
  }
}

function systemTheme(): Theme {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function apply(theme: Theme | null) {
  const root = document.documentElement;
  if (theme) root.dataset.theme = theme;
  else delete root.dataset.theme;
  const meta = document.querySelector('meta[name="theme-color"]');
  const effective = theme ?? systemTheme();
  meta?.setAttribute('content', effective === 'dark' ? '#0B1220' : '#2563EB');
}

export function useTheme() {
  const [explicit, setExplicit] = useState<Theme | null>(stored);
  const [system, setSystem] = useState<Theme>(systemTheme);

  useEffect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const onChange = () => setSystem(mq.matches ? 'dark' : 'light');
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, []);

  useEffect(() => {
    apply(explicit);
  }, [explicit, system]);

  const theme = explicit ?? system;

  const toggle = useCallback(() => {
    const next: Theme = theme === 'dark' ? 'light' : 'dark';
    try {
      localStorage.setItem(KEY, next);
    } catch {
      // ignore
    }
    setExplicit(next);
  }, [theme]);

  return { theme, toggle };
}
