importScripts('https://www.gstatic.com/firebasejs/12.17.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.17.0/firebase-messaging-compat.js');

firebase.initializeApp(__FIREBASE_CONFIG__);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const title = payload.notification?.title ?? 'Qio';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/icon-192.png',
    badge: '/icon-192.png',
    data: payload.data ?? {},
  };
  self.registration.showNotification(title, options);
});
