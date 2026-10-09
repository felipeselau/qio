import type { LegalBundle } from './types';

const bundle: LegalBundle = {
  draftBanner:
    'Borrador técnico — revisar con el orientador/asesoría jurídica antes de publicar. El texto de referencia es la versión en portugués. No es asesoría jurídica ni promete cumplimiento.',
  effectiveLabel: 'Vigencia',
  effectivePlaceholder: '[fecha de vigencia]',
  contactHeading: 'Contacto',
  contactIntro:
    'Para ejercer tus derechos o consultar sobre tus datos, contacta al responsable (el establecimiento que opera la fila):',
  contactMissing:
    'Canal de contacto no configurado. Contacta al establecimiento donde entraste en la fila.',
  privacy: {
    title: 'Política de privacidad',
    sections: [
      {
        heading: 'Quién es quién',
        paragraphs: [
          'Responsable: el establecimiento que crea y opera la fila. Encargado: Qio, proyecto académico que ofrece la herramienta en nombre del establecimiento.',
        ],
      },
      {
        heading: 'Datos que tratamos',
        items: [
          'Nombre y teléfono opcional que escribes al entrar.',
          'Identificador anónimo de sesión (Firebase Authentication anónimo).',
          'Datos del turno: número, estado, horarios de entrada y llamada, idioma, franja elegida.',
          'Token de notificaciones push opcional, solo si tocas "Activar aviso".',
          'Valoración y comentario opcionales tras la atención.',
          'Estadísticas de uso (Google Analytics) solo si están activadas, con opt-out en el pie y respetando Do Not Track.',
        ],
      },
      {
        heading: 'Finalidad y base legal',
        paragraphs: [
          'Organizar la fila, mostrar tu posición y llamarte. Base: ejecución del servicio solicitado y tu consentimiento al escribir los datos.',
        ],
      },
      {
        heading: 'Compartición',
        paragraphs: [
          'El establecimiento (dueño y operadores) ve nombres y teléfonos. Firebase/Google Cloud actúa como subencargado. Otros participantes solo ven número y estado. No vendemos datos.',
        ],
      },
      {
        heading: 'Retención',
        items: [
          'Entrada activa: solo mientras estás en la fila.',
          'Historial de atenciones (nombre, teléfono, resultado, horarios): objetivo de 180 días; la rutina automática de eliminación aún está pendiente.',
        ],
      },
      {
        heading: 'Tus derechos',
        paragraphs: [
          'Acceso, corrección y eliminación, solicitados al responsable. También puedes salir de la fila en cualquier momento desde la página.',
        ],
      },
      {
        heading: 'Almacenamiento local',
        paragraphs: [
          'Usamos localStorage del navegador para tu entrada, valoración pendiente, idioma, tema y la opción de no recopilar estadísticas. Borra los datos del sitio para eliminarlos.',
        ],
      },
      {
        heading: 'Niños y cambios',
        paragraphs: [
          'El servicio no está dirigido a menores de 12 años. La política puede cambiar; consulta la fecha de vigencia.',
        ],
      },
    ],
  },
  terms: {
    title: 'Términos de uso',
    sections: [
      {
        heading: 'Servicio',
        paragraphs: [
          'Qio permite entrar en una fila presencial desde el navegador. El establecimiento decide a quién llama y cuándo.',
        ],
      },
      {
        heading: 'Proyecto académico',
        paragraphs: [
          'Qio es un proyecto académico ofrecido tal cual, sin garantía de disponibilidad. Las estimaciones de espera son aproximadas.',
        ],
      },
      {
        heading: 'Tus responsabilidades',
        paragraphs: [
          'Dar datos verdaderos, no abusar ni automatizar el servicio y seguir la página o activar avisos: puedes ser marcado como ausente si no atiendes la llamada.',
        ],
      },
      {
        heading: 'Responsabilidad y cambios',
        paragraphs: [
          'En la medida permitida por la ley, Qio no responde por indisponibilidad, retrasos de notificación ni decisiones del establecimiento. Los términos pueden cambiar. Sujeto a revisión jurídica.',
        ],
      },
    ],
  },
};

export default bundle;
