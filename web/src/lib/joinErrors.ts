const JOIN_ERROR_KEYS: Record<string, string> = {
  'functions/already-exists': 'errors.alreadyExists',
  'functions/resource-exhausted': 'errors.resourceExhausted',
  'functions/failed-precondition': 'errors.failedPrecondition',
  'functions/invalid-argument': 'errors.invalidArgument',
  'functions/not-found': 'errors.notFound',
  'functions/unauthenticated': 'errors.securityCheckFailed',
};

const SLOT_ERROR_KEYS: Record<string, string> = {
  'slot-full': 'errors.slotFull',
  'slot-required': 'errors.reloadPage',
  'slot-invalid': 'errors.reloadPage',
  'slot-passed': 'errors.slotPassed',
};

export function joinErrorKey(err: unknown): string {
  const e = err as { code?: string; details?: { reason?: string } } | null;
  const code = e?.code ?? '';
  if (code === 'functions/resource-exhausted' && e?.details?.reason === 'queue-full') {
    return 'errors.queueFull';
  }
  const reasonKey = e?.details?.reason ? SLOT_ERROR_KEYS[e.details.reason] : undefined;
  if (reasonKey) return reasonKey;
  return JOIN_ERROR_KEYS[code] ?? 'errors.joinFailed';
}

export function feedbackErrorKey(err: unknown): string | null {
  const code = (err as { code?: string } | null)?.code ?? '';
  if (code === 'functions/failed-precondition') return null;
  if (code === 'functions/unauthenticated') return 'errors.securityCheckFailed';
  return 'errors.feedbackFailed';
}
