import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey:
    import.meta.env.VITE_FIREBASE_API_KEY ??
    "AIzaSyCQmM1laIWowA87beJz5rJF4EXcohas1ew",
  authDomain:
    import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ??
    "khatu-shyam-7452d.firebaseapp.com",
  projectId:
    import.meta.env.VITE_FIREBASE_PROJECT_ID ?? "khatu-shyam-7452d",
  storageBucket:
    import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ??
    "khatu-shyam-7452d.firebasestorage.app",
  messagingSenderId:
    import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? "191548396096",
  appId:
    import.meta.env.VITE_FIREBASE_APP_ID ??
    "1:191548396096:web:6f90357560854bccbe85a5",
};

const app = initializeApp(firebaseConfig);

export const firebaseAuth = getAuth(app);
