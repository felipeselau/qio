import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import './widget.css';
import { useTheme } from '../lib/theme';
import { useWidget, type WidgetMeta } from '../lib/useWidget';
import { WIDGET_PATH_PREFIX, futureTime, parseWidgetTarget, widgetEstimateMin } from '../lib/widget';
import type { WidgetCounts } from '../lib/widget';

function formatWhen(ms: number, language: string): string {
  const same = new Date(ms).toDateString() === new Date().toDateString();
  return new Date(ms).toLocaleString(
    language,
    same
      ? { hour: '2-digit', minute: '2-digit' }
      : { weekday: 'short', hour: '2-digit', minute: '2-digit' },
  );
}

function WidgetLogo({ meta }: { meta: WidgetMeta }) {
  const [failed, setFailed] = useState(false);
  useEffect(() => {
    setFailed(false);
  }, [meta.logoUrl]);
  if (meta.logoUrl && !failed) {
    return (
      <img
        className="widget-logo"
        src={meta.logoUrl}
        alt=""
        referrerPolicy="no-referrer"
        onError={() => setFailed(true)}
      />
    );
  }
  return (
    <div className="widget-logo widget-logo-fallback" aria-hidden="true">
      {meta.name.trim().charAt(0).toUpperCase() || 'Q'}
    </div>
  );
}

function Summary({ meta, counts }: { meta: WidgetMeta; counts: WidgetCounts }) {
  const { t } = useTranslation();
  const estimate = widgetEstimateMin(
    counts.waiting,
    meta.avgServiceMinAuto,
    meta.avgServiceMin,
    meta.scheduled,
  );
  return (
    <>
      <p className="widget-count">
        {counts.waiting === 0 ? (
          t('widget.empty')
        ) : (
          <>
            <strong>{counts.waiting}</strong> {t('widget.inQueue', { count: counts.waiting })}
          </>
        )}
        {estimate != null && (
          <span className="widget-estimate"> · {t('widget.estimate', { minutes: estimate })}</span>
        )}
      </p>
      {counts.called > 0 && (
        <p className="widget-sub">{t('widget.beingServed', { count: counts.called })}</p>
      )}
    </>
  );
}

function Notice({ meta, now }: { meta: WidgetMeta; now: number }) {
  const { t, i18n } = useTranslation();
  if (meta.status === 'open') return null;
  const resume = futureTime(meta.resumeAt, now);
  const opens = meta.status === 'closed' ? futureTime(meta.opensAt, now) : null;
  return (
    <div className={`notice ${meta.status === 'paused' ? 'notice-warning' : 'notice-closed'}`}>
      <strong>{meta.status === 'paused' ? t('queue.pausedTitle') : t('queue.closedTitle')}</strong>
      {meta.statusMessage && <span>{meta.statusMessage}</span>}
      {resume && (
        <span>
          {t('queue.returnAt', {
            time: new Date(resume).toLocaleTimeString(i18n.language, {
              hour: '2-digit',
              minute: '2-digit',
            }),
          })}
        </span>
      )}
      {opens && <span>{t('queue.opensAt', { when: formatWhen(opens, i18n.language) })}</span>}
    </div>
  );
}

export default function Widget() {
  useTheme();
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { id } = useParams();
  const state = useWidget(parseWidgetTarget(id));
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 30000);
    return () => window.clearInterval(timer);
  }, []);

  const readyId = state.phase === 'ready' ? state.queueId : null;
  useEffect(() => {
    if (readyId && readyId !== id) navigate(`${WIDGET_PATH_PREFIX}${readyId}`, { replace: true });
  }, [readyId, id, navigate]);

  const brand = state.phase === 'ready' ? state.meta.brandColor : null;
  useEffect(() => {
    const root = document.documentElement;
    if (brand) root.style.setProperty('--brand', brand);
    else root.style.removeProperty('--brand');
    return () => {
      root.style.removeProperty('--brand');
    };
  }, [brand]);

  const name = state.phase === 'ready' ? state.meta.name : null;
  useEffect(() => {
    if (!name) return;
    const previous = document.title;
    document.title = `${name} · Qio`;
    return () => {
      document.title = previous;
    };
  }, [name]);

  if (state.phase === 'loading') {
    return (
      <main className="widget" aria-busy="true">
        <p className="muted" role="status">
          {t('widget.loading')}
        </p>
      </main>
    );
  }

  if (state.phase === 'notFound') {
    return (
      <main className="widget">
        <h1 className="widget-name">{t('queue.notFound')}</h1>
        <p className="muted">{t('queue.notFoundHint')}</p>
      </main>
    );
  }

  if (state.phase === 'failed') {
    return (
      <main className="widget" role="alert">
        <h1 className="widget-name">{t('queue.connectFailed')}</h1>
        <p className="muted">{t('queue.connectFailedHint')}</p>
        <button type="button" className="btn btn-primary" onClick={state.retry}>
          {t('slug.retry')}
        </button>
      </main>
    );
  }

  const { meta, counts } = state;
  return (
    <main className="widget fade-in">
      <WidgetLogo meta={meta} />
      <h1 className="widget-name">{meta.name}</h1>
      <div aria-live="polite" aria-atomic="true" className="widget-live">
        {meta.status === 'closed' ? null : <Summary meta={meta} counts={counts} />}
        <Notice meta={meta} now={now} />
      </div>
    </main>
  );
}
