importScripts('https://www.gstatic.com/firebasejs/12.17.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.17.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAY29R07GlubY5lFmUriQ8qiVuiiWv7W6Y',
  authDomain: 'qio-app.firebaseapp.com',
  databaseURL: 'https://qio-app-default-rtdb.firebaseio.com',
  projectId: 'qio-app',
  storageBucket: 'qio-app.firebasestorage.app',
  messagingSenderId: '981965097928',
  appId: '1:981965097928:web:b08d7d1bfce182d3d4cefd',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Qio';
  const options = {
    body: payload.notification?.body ?? '',
    icon: '/favicon.svg',
    badge: '/favicon.svg',
    data: payload.data ?? {},
  };
  self.registration.showNotification(title, options);
});
