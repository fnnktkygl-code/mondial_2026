importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyBzUFfMaITpS5UXAEsINYK-atbPLJsrjlE",
  authDomain: "mondial-2026-challenge-8f.firebaseapp.com",
  projectId: "mondial-2026-challenge-8f",
  storageBucket: "mondial-2026-challenge-8f.firebasestorage.app",
  messagingSenderId: "1106243131",
  appId: "1:1106243131:web:e750b217aa5c11120df61e"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
