const EMAIL = /^[^\s@<>()[\]\\,;:"]+@[^\s@<>()[\]\\,;:"]+\.[^\s@<>()[\]\\,;:"]+$/;

export function privacyContact(raw: string | undefined): string | null {
  const value = raw?.trim();
  return value ? value : null;
}

export function contactHref(contact: string | null): string | null {
  if (!contact) return null;
  if (EMAIL.test(contact)) return `mailto:${contact}`;
  try {
    const url = new URL(contact);
    return url.protocol === 'https:' ? url.toString() : null;
  } catch {
    return null;
  }
}

export const PRIVACY_PATH = '/privacidade';
export const TERMS_PATH = '/termos';
