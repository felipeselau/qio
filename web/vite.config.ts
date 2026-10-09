import { fileURLToPath } from 'node:url'
import { defineConfig, type Plugin } from 'vite'
import react from '@vitejs/plugin-react'
import { swConfigPlugin } from './vite-plugins/swConfig.ts'

function widgetRewritePlugin(): Plugin {
  return {
    name: 'qio-widget-rewrite',
    configureServer(server) {
      server.middlewares.use((req, _res, next) => {
        if (req.url && /^\/w\/[^?#]+/.test(req.url)) req.url = '/widget.html'
        next()
      })
    },
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), swConfigPlugin(), widgetRewritePlugin()],
  build: {
    rollupOptions: {
      input: {
        main: fileURLToPath(new URL('./index.html', import.meta.url)),
        widget: fileURLToPath(new URL('./widget.html', import.meta.url)),
      },
    },
  },
})
