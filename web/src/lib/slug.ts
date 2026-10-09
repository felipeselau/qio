export const SHORT_PATH_PREFIX = '/n/';

export const RESERVED_SLUGS = [
  'admin',
  'api',
  'app',
  'q',
  'c',
  'w',
  'n',
  'privacidade',
  'termos',
  'assets',
  'fonts',
  'icons',
] as const;

const SLUG_PATTERN = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;

export function normalizeSlug(value: unknown): string {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

export function isValidSlug(value: unknown): boolean {
  return (
    typeof value === 'string' &&
    SLUG_PATTERN.test(value) &&
    !(RESERVED_SLUGS as readonly string[]).includes(value)
  );
}

export function parseSlug(value: unknown): string | null {
  const slug = normalizeSlug(value);
  return isValidSlug(slug) ? slug : null;
}

export function queuePathFor(queueId: string): string {
  return `/q/${queueId}`;
}

export function slugErrorKind(err: unknown): 'notFound' | 'retry' {
  const code = (err as { code?: string } | null)?.code ?? '';
  return code === 'functions/not-found' ? 'notFound' : 'retry';
}
