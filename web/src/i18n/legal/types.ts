export type LegalSection = {
  heading: string;
  paragraphs?: string[];
  items?: string[];
};

export type LegalDoc = {
  title: string;
  sections: LegalSection[];
};

export type LegalBundle = {
  draftBanner: string;
  effectiveLabel: string;
  effectivePlaceholder: string;
  contactHeading: string;
  contactIntro: string;
  contactMissing: string;
  privacy: LegalDoc;
  terms: LegalDoc;
};
