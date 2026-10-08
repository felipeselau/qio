import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { swConfigPlugin } from './vite-plugins/swConfig.ts'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), swConfigPlugin()],
})
