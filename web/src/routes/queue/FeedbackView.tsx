import { useTranslation } from 'react-i18next';

const MAX_COMMENT = 300;

type Props = {
  rating: number;
  comment: string;
  sending: boolean;
  error: string | null;
  onRating: (n: number) => void;
  onComment: (value: string) => void;
  onSend: () => void;
  onSkip: () => void;
};

export default function FeedbackView({
  rating,
  comment,
  sending,
  error,
  onRating,
  onComment,
  onSend,
  onSkip,
}: Props) {
  const { t } = useTranslation();
  return (
    <div className="page fade-in" key="feedback">
      <div className="page-scroll">
        <div className="card" style={{ textAlign: 'center' }}>
          <h1 data-autofocus tabIndex={-1} style={{ fontSize: 20, fontWeight: 700, marginBottom: 12 }}>
            {t('queue.feedbackTitle')}
          </h1>
          <div className="stars" role="radiogroup" aria-label={t('queue.feedbackTitle')}>
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                role="radio"
                aria-checked={rating === n}
                aria-label={t('queue.feedbackStar', { count: n })}
                className={`star${n <= rating ? ' star-on' : ''}`}
                onClick={() => onRating(n)}
              >
                ★
              </button>
            ))}
          </div>
          <div className="field" style={{ marginTop: 16, textAlign: 'left' }}>
            <label htmlFor="feedback-comment">{t('queue.feedbackComment')}</label>
            <textarea
              id="feedback-comment"
              value={comment}
              onChange={(e) => onComment(e.target.value)}
              maxLength={MAX_COMMENT}
              rows={3}
            />
          </div>
        </div>
        {error && <p className="error-text" role="alert">{error}</p>}
        <button
          type="button"
          className="btn btn-primary"
          disabled={rating < 1 || sending}
          onClick={onSend}
        >
          {sending ? t('queue.feedbackSending') : t('queue.feedbackSend')}
        </button>
        <button
          type="button"
          className="btn btn-danger-ghost"
          disabled={sending}
          onClick={onSkip}
        >
          {t('queue.feedbackSkip')}
        </button>
      </div>
    </div>
  );
}
