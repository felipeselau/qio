const { onValueWritten } = require('firebase-functions/v2/database');
const { initializeApp } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const { getDatabase } = require('firebase-admin/database');

initializeApp();

exports.onEntryCalled = onValueWritten(
  {
    ref: 'queues/{queueId}/entries/{entryId}',
    region: 'us-central1',
  },
  async (event) => {
    const after = event.data.after.val();
    const before = event.data.before.val();

    const wasCalled = before?.status === 'called';
    const isCalled = after?.status === 'called';
    if (wasCalled || !isCalled) {
      return null;
    }

    const token = after.fcmToken;
    if (!token) {
      return null;
    }

    const queueId = event.params.queueId;
    let queueName = 'Fila';
    try {
      const metaSnap = await getDatabase()
        .ref(`queues/${queueId}/meta/name`)
        .once('value');
      if (metaSnap.exists()) {
        queueName = metaSnap.val();
      }
    } catch {
      // fallback name
    }

    const ticket = after.ticket ?? '';

    const message = {
      token,
      notification: {
        title: 'É a sua vez!',
        body: `Senha #${ticket} — dirija-se ao atendimento (${queueName})`,
      },
      webpush: {
        fcmOptions: {
          link: `https://qio.web.app/q/${queueId}`,
        },
      },
    };

    try {
      await getMessaging().send(message);
      return { ok: true };
    } catch (err) {
      console.error('FCM send failed', err);
      return null;
    }
  },
);
