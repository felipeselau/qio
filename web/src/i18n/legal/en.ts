import type { LegalBundle } from './types';

const bundle: LegalBundle = {
  draftBanner:
    'Technical draft — review with the advisor/legal counsel before publishing. The authoritative text is the Portuguese version. This is not legal advice and does not promise compliance.',
  effectiveLabel: 'Effective date',
  effectivePlaceholder: '[effective date]',
  contactHeading: 'Contact',
  contactIntro:
    'To exercise your rights or ask about your data, contact the controller (the business running the queue):',
  contactMissing: 'No contact channel configured. Please contact the business where you joined the queue.',
  privacy: {
    title: 'Privacy policy',
    sections: [
      {
        heading: 'Who is who',
        paragraphs: [
          'Controller: the business that creates and runs the queue. Processor: Qio, an academic project that provides the tool on the business behalf.',
        ],
      },
      {
        heading: 'Data we handle',
        items: [
          'Name and optional phone number you type when joining.',
          'An anonymous session identifier (anonymous Firebase Authentication).',
          'Ticket data: number, status, join and call times, language, chosen time slot.',
          'Optional push notification token, only if you tap "Enable alerts".',
          'Optional "Notify me when it opens" request: push token, language and request date, tied to the anonymous session identifier, with no name or phone number.',
          'Optional rating and comment after service.',
          'Usage statistics (Google Analytics) only if enabled, with opt-out in the footer and Do Not Track respected.',
        ],
      },
      {
        heading: 'Purpose and legal basis',
        paragraphs: [
          'To organize the queue, show your position and call you. Basis: performance of the service you requested and your consent when typing the data.',
        ],
      },
      {
        heading: 'Sharing',
        paragraphs: [
          'The business (owner and operators) sees names and phones. Firebase/Google Cloud acts as sub-processor. Other participants only see ticket number and status. We do not sell data.',
        ],
      },
      {
        heading: 'Retention',
        items: [
          'Active queue entry: only while you are in the queue.',
          '"Notify me when it opens" request (push token, language and date): until the queue opens (deleted after the alert), for 24 hours at most, until you cancel it, or until the queue is deleted.',
          'Service history (name, phone, result, times): target of 180 days; the automatic deletion routine is still pending.',
        ],
      },
      {
        heading: 'Your rights',
        paragraphs: [
          'Access, correction and deletion, requested from the controller. You can also leave the queue at any time on the page.',
        ],
      },
      {
        heading: 'Local storage',
        paragraphs: [
          'We use the browser localStorage for your entry, pending rating, language, theme and the statistics opt-out. Clear site data to remove them.',
        ],
      },
      {
        heading: 'Children and changes',
        paragraphs: [
          'The service is not aimed at children under 12. This policy may change; see the effective date.',
        ],
      },
    ],
  },
  terms: {
    title: 'Terms of use',
    sections: [
      {
        heading: 'Service',
        paragraphs: [
          'Qio lets you join an in-person queue from your browser. The business decides who is called and when.',
        ],
      },
      {
        heading: 'Academic project',
        paragraphs: [
          'Qio is an academic project provided as is, with no availability guarantee. Wait estimates are approximate.',
        ],
      },
      {
        heading: 'Your responsibilities',
        paragraphs: [
          'Provide truthful data, do not abuse or automate the service, and watch the page or enable alerts: you may be marked as no-show if you miss the call.',
        ],
      },
      {
        heading: 'Liability and changes',
        paragraphs: [
          'To the extent allowed by law, Qio is not liable for downtime, notification delays or business decisions. These terms may change. Subject to legal review.',
        ],
      },
    ],
  },
};

export default bundle;
