/* eslint-disable no-undef */
// Firebase Cloud Messaging service worker (Flutter web).
// Must live at the site root: /firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA-eEji6_kLAAN8nw6I-SuiYRfa84B58dU',
  authDomain: 'satya-devotte-app.firebaseapp.com',
  projectId: 'satya-devotte-app',
  storageBucket: 'satya-devotte-app.firebasestorage.app',
  messagingSenderId: '1053803605697',
  appId: '1:1053803605697:web:b3cddc97158a26852a6e40',
  measurementId: 'G-18Z1BB36SF',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const title =
    (payload.notification && payload.notification.title) ||
    payload.data?.title ||
    'Satya Admin';
  const options = {
    body:
      (payload.notification && payload.notification.body) ||
      payload.data?.body ||
      '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    silent: false,
    data: payload.data || {},
    tag: payload.data?.type || payload.messageId || 'satya-admin',
  };
  return self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const targetUrl = self.location.origin + '/';
  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then(function (clientList) {
        for (let i = 0; i < clientList.length; i++) {
          const client = clientList[i];
          if ('focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      }),
  );
});
