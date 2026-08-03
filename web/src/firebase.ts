import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getDatabase } from 'firebase/database';

const firebaseConfig = {
  apiKey: 'AIzaSyAY29R07GlubY5lFmUriQ8qiVuiiWv7W6Y',
  authDomain: 'qio-app.firebaseapp.com',
  databaseURL: 'https://qio-app-default-rtdb.firebaseio.com',
  projectId: 'qio-app',
  storageBucket: 'qio-app.firebasestorage.app',
  messagingSenderId: '981965097928',
  appId: '1:981965097928:web:b08d7d1bfce182d3d4cefd',
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getDatabase(app);