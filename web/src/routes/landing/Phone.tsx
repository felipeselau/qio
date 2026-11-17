import type { CSSProperties, ReactNode } from 'react';

type PhoneProps = {
  size?: number;
  className?: string;
  label?: string;
  children: ReactNode;
};

export function StatusBar({ light = false }: { light?: boolean }) {
  return (
    <div className={`ph-status${light ? ' ph-status-light' : ''}`} aria-hidden="true">
      <span>9:41</span>
      <span className="ph-status-icons">
        <svg viewBox="0 0 18 12" width="1.3em" height="0.9em">
          <rect x="0" y="8" width="3" height="4" rx="0.8" fill="currentColor" />
          <rect x="5" y="5.5" width="3" height="6.5" rx="0.8" fill="currentColor" />
          <rect x="10" y="3" width="3" height="9" rx="0.8" fill="currentColor" />
          <rect x="15" y="0" width="3" height="12" rx="0.8" fill="currentColor" />
        </svg>
        <svg viewBox="0 0 27 13" width="1.9em" height="0.95em">
          <rect x="0.5" y="0.5" width="22" height="12" rx="3.5" fill="none" stroke="currentColor" opacity="0.45" />
          <rect x="2" y="2" width="19" height="9" rx="2.2" fill="currentColor" />
          <rect x="24" y="4.2" width="2" height="4.6" rx="1" fill="currentColor" opacity="0.5" />
        </svg>
      </span>
    </div>
  );
}

export function Phone({ size = 14, className = '', label, children }: PhoneProps) {
  const style = { '--ph': `${size}px` } as CSSProperties;
  return (
    <div
      className={`ph ${className}`.trim()}
      style={style}
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <div className="ph-screen">
        <div className="ph-island" />
        {children}
      </div>
    </div>
  );
}
