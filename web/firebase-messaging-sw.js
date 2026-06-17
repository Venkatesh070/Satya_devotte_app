/* eslint-disable no-undef */
// Firebase Cloud Messaging service worker (Flutter web).
// Must live at the site root: /firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBKd3xfIGpsxSUhsoNwPf5O3D4HQEc0QCs',
  authDomain: 'sathyatest-4b2b1.firebaseapp.com',
  projectId: 'sathyatest-4b2b1',
  storageBucket: 'sathyatest-4b2b1.firebasestorage.app',
  messagingSenderId: '460042314237',
  appId: '1:460042314237:android:2dfce106f585b513847994',
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
