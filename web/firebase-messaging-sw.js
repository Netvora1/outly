importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBwvNeaPOybKkgNMrWB4fVKeSID-8SF9lA",
  authDomain: "clipza-1bf99.firebaseapp.com",
  projectId: "clipza-1bf99",
  storageBucket: "clipza-1bf99.firebasestorage.app",
  messagingSenderId: "298079047994",
  appId: "1:298079047994:web:e3c3c7ee7baea57e27c003",
});

const messaging = firebase.messaging();