import { connectFunctionsEmulator, getFunctions } from 'firebase/functions';
import { app } from './firebase';

export const functions = getFunctions(app);

if (import.meta.env.VITE_USE_EMULATORS === 'true') {
  connectFunctionsEmulator(functions, 'localhost', Number(import.meta.env.VITE_FUNCTIONS_EMULATOR_PORT ?? 5001));
}
