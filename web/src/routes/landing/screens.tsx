import { useTranslation } from 'react-i18next';
import { StatusBar } from './Phone';
import { QR_SIZE, qrPath } from './qr';

const QR = qrPath();

function Chip({ children }: { children: string }) {
  return <span className="ms-chip">{children}</span>;
}

export function JoinScreen() {
  const { t } = useTranslation();
  return (
    <div className="ms ms-gray">
      <StatusBar />
      <div className="ms-body ms-join">
        <h4 className="ms-title">{t('landing.mock.clinic')}</h4>
        <Chip>{t('landing.mock.open')}</Chip>
        <p className="ms-hint">{t('landing.mock.joinHint')}</p>
        <label className="ms-field">
          <span>{t('landing.mock.name')} *</span>
          <i>{t('landing.mock.namePh')}</i>
        </label>
        <label className="ms-field">
          <span>{t('landing.mock.phone')}</span>
          <i>(00) 00000-0000</i>
        </label>
        <div className="ms-btn ms-btn-blue">{t('landing.mock.join')}</div>
      </div>
    </div>
  );
}

export function TicketScreen() {
  const { t } = useTranslation();
  return (
    <div className="ms ms-gray">
      <StatusBar />
      <div className="ms-body">
        <div className="ms-card ms-ticket">
          <small>{t('landing.mock.yourTicket')}</small>
          <b>#32</b>
          <span>{t('landing.mock.clinic')}</span>
        </div>
        <div className="ms-card ms-rows">
          <div>
            <span>{t('landing.mock.position')}</span>
            <b>2º</b>
          </div>
          <div>
            <span>{t('landing.mock.wait')}</span>
            <b>{t('landing.mock.waitValue')}</b>
          </div>
        </div>
        <div className="ms-info">
          <svg viewBox="0 0 20 20" width="1.4em" height="1.4em" aria-hidden="true">
            <circle cx="10" cy="10" r="9" fill="#2563EB" />
            <rect x="9" y="8.5" width="2" height="6" rx="1" fill="#fff" />
            <circle cx="10" cy="5.8" r="1.2" fill="#fff" />
          </svg>
          <p>{t('landing.mock.keepOpen')}</p>
        </div>
        <p className="ms-leave">{t('landing.mock.leave')}</p>
      </div>
    </div>
  );
}

export function CalledScreen() {
  const { t } = useTranslation();
  return (
    <div className="ms ms-green">
      <StatusBar light />
      <div className="ms-called">
        <div className="ms-checkwrap">
          <span className="ms-ring" />
          <svg viewBox="0 0 48 48" width="5em" height="5em" aria-hidden="true">
            <path
              d="M10 25l9 9 19-21"
              fill="none"
              stroke="#fff"
              strokeWidth="5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>
        <h4>{t('landing.mock.yourTurn')}</h4>
        <b>
          {t('landing.mock.ticket')} #32
        </b>
        <p>{t('landing.mock.goTo')}</p>
      </div>
    </div>
  );
}

export function QrScreen() {
  const { t } = useTranslation();
  return (
    <div className="ms ms-gray">
      <StatusBar />
      <header className="ms-head">
        <span className="ms-back">←</span>
        <div>
          <h4>{t('landing.mock.clinic')}</h4>
          <Chip>{t('landing.mock.open')}</Chip>
        </div>
      </header>
      <div className="ms-body ms-qrbody">
        <div className="ms-card ms-qrcard">
          <div className="ms-qrbox">
            <svg viewBox={`-1 -1 ${QR_SIZE + 2} ${QR_SIZE + 2}`} shapeRendering="crispEdges" aria-hidden="true">
              <path d={QR} fill="#0b1220" />
            </svg>
          </div>
          <p>{t('landing.mock.scan')}</p>
          <div className="ms-link">qio.web.app/n/clinicavida</div>
          <div className="ms-btnrow">
            <div className="ms-btn ms-btn-blue">{t('landing.mock.copyLink')}</div>
            <div className="ms-btn ms-btn-line">{t('landing.mock.share')}</div>
          </div>
          <p className="ms-poster">{t('landing.mock.poster')}</p>
        </div>
      </div>
    </div>
  );
}

const QUEUE = [
  { i: 'BL', n: 'Bruno Lima', w: '#32 · 2 min' },
  { i: 'CM', n: 'Carla Mendes', w: '#33 · 6 min' },
  { i: 'DR', n: 'Diego Rocha', w: '#34 · 10 min' },
];

export function PanelScreen() {
  const { t } = useTranslation();
  return (
    <div className="ms ms-gray">
      <StatusBar />
      <header className="ms-head">
        <span className="ms-back">←</span>
        <div>
          <h4>{t('landing.mock.clinic')}</h4>
          <Chip>{t('landing.mock.open')}</Chip>
        </div>
      </header>
      <div className="ms-body ms-panelbody">
        <div className="ms-calling">
          <small>{t('landing.mock.calling')}</small>
          <b>#31</b>
          <span>Ana Souza</span>
          <i>{t('landing.mock.callAgain')}</i>
        </div>
        <h5 className="ms-sec">{t('landing.mock.next')}</h5>
        {QUEUE.map((q) => (
          <div key={q.i} className="ms-row">
            <span className="ms-av">{q.i}</span>
            <div>
              <b>{q.n}</b>
              <small>{q.w}</small>
            </div>
            <em>···</em>
          </div>
        ))}
      </div>
      <div className="ms-dock">
        <div className="ms-btn ms-btn-off">{t('landing.mock.callNext')}</div>
        <div className="ms-btnrow">
          <div className="ms-btn ms-btn-ok">{t('landing.mock.served')}</div>
          <div className="ms-btn ms-btn-no">{t('landing.mock.noShow')}</div>
        </div>
      </div>
    </div>
  );
}

const BARS = [0, 0, 0, 0, 0, 0, 0, 0, 0.3, 0.55, 0.42, 0.28, 0.28, 0, 0.8, 1, 0.68, 0.3, 0.3, 0, 0, 0, 0, 0];

export function MetricsScreen() {
  const { t } = useTranslation();
  return (
    <div className="ms ms-gray">
      <StatusBar />
      <header className="ms-head">
        <span className="ms-back">←</span>
        <h4>{t('landing.mock.metrics')}</h4>
      </header>
      <div className="ms-body">
        <div className="ms-chips">
          <span>{t('landing.mock.today')}</span>
          <span className="ms-chip-on">✓ {t('landing.mock.week')}</span>
          <span>{t('landing.mock.all')}</span>
        </div>
        <div className="ms-card ms-stats">
          <div>
            <small>{t('landing.mock.servedLabel')}</small>
            <b>47</b>
          </div>
          <div>
            <small>{t('landing.mock.noShowLabel')}</small>
            <b>6 (13%)</b>
          </div>
          <div>
            <small>{t('landing.mock.avgWait')}</small>
            <b>8 min</b>
          </div>
          <div>
            <small>{t('landing.mock.avgService')}</small>
            <b>6 min</b>
          </div>
        </div>
        <div className="ms-card ms-chart">
          <h5>{t('landing.mock.peaks')}</h5>
          <div className="ms-bars" aria-hidden="true">
            {BARS.map((v, i) => (
              <span key={i} style={{ height: v ? `${Math.max(v * 100, 8)}%` : '4%' }} className={v ? '' : 'ms-bar-0'} />
            ))}
          </div>
          <div className="ms-axis">
            <span>0h</span>
            <span>6h</span>
            <span>12h</span>
            <span>18h</span>
            <span>23h</span>
          </div>
          <p>{t('landing.mock.peakHours')}</p>
        </div>
      </div>
    </div>
  );
}
