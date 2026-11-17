import { useEffect, useRef, useState } from 'react';
import { Phone } from './Phone';
import { SCREENS, type ScreenKey } from './screenMap';
import { useReveal } from './useReveal';

type Step = { t: string; b: string };

type StoryProps = {
  id: string;
  eyebrow: string;
  title: string;
  steps: Step[];
  screens: ScreenKey[];
  flip?: boolean;
};

export function Story({ id, eyebrow, title, steps, screens, flip = false }: StoryProps) {
  const [active, setActive] = useState(0);
  const stepRefs = useRef<(HTMLElement | null)[]>([]);
  const head = useReveal<HTMLDivElement>();

  useEffect(() => {
    if (typeof IntersectionObserver === 'undefined') return;
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            const i = Number((e.target as HTMLElement).dataset.i);
            if (!Number.isNaN(i)) setActive(i);
          }
        }
      },
      { rootMargin: '-45% 0px -45% 0px' },
    );
    for (const el of stepRefs.current) if (el) io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <section id={id} className={`lp-story${flip ? ' lp-story-flip' : ''}`} aria-labelledby={`${id}-h`}>
      <div className="lp-story-grid">
        <div className="lp-story-text">
          <div ref={head} className="rv lp-story-head">
            <p className="lp-eyebrow">{eyebrow}</p>
            <h2 id={`${id}-h`} className="lp-h2">
              {title}
            </h2>
          </div>
          {steps.map((s, i) => {
            const Screen = SCREENS[screens[i]];
            return (
              <article
                key={s.t}
                data-i={i}
                ref={(el) => {
                  stepRefs.current[i] = el;
                }}
                className={`lp-step${active === i ? ' is-active' : ''}`}
              >
                <span className="lp-step-n">{String(i + 1).padStart(2, '0')}</span>
                <h3 className="lp-h3">{s.t}</h3>
                <p className="lp-p">{s.b}</p>
                <div className="lp-step-phone">
                  <Phone size={13} label={s.t}>
                    <Screen />
                  </Phone>
                </div>
              </article>
            );
          })}
        </div>
        <div className="lp-story-stage" aria-hidden="true">
          <div className="lp-dots" />
          <div className="lp-sticky">
            <Phone size={15}>
              {screens.map((k, i) => {
                const Screen = SCREENS[k];
                return (
                  <div key={k} className={`ms-layer${active === i ? ' is-on' : ''}`}>
                    <Screen />
                  </div>
                );
              })}
            </Phone>
            <div className="lp-dotsnav">
              {screens.map((k, i) => (
                <span key={k} className={active === i ? 'is-on' : ''} />
              ))}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
