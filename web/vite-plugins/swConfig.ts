import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Plugin } from 'vite';
import { firebaseConfig } from '../src/firebaseConfig.ts';

export const SW_FILE_NAME = 'firebase-messaging-sw.js';
export const SW_PLACEHOLDER = '__FIREBASE_CONFIG__';

export function renderServiceWorker(template: string, config: Record<string, string | undefined>): string {
  if (!template.includes(SW_PLACEHOLDER)) {
    throw new Error(`Template do service worker sem o placeholder ${SW_PLACEHOLDER}`);
  }
  const defined = Object.fromEntries(Object.entries(config).filter(([, v]) => v !== undefined));
  const output = template.split(SW_PLACEHOLDER).join(JSON.stringify(defined, null, 2));
  if (output.includes(SW_PLACEHOLDER)) {
    throw new Error('Placeholder do service worker não foi substituído');
  }
  return output;
}

export function swConfigPlugin(): Plugin {
  const templatePath = fileURLToPath(new URL('./firebase-messaging-sw.template.js', import.meta.url));
  const render = () => renderServiceWorker(readFileSync(templatePath, 'utf8'), firebaseConfig);
  return {
    name: 'qio-sw-config',
    configureServer(server) {
      server.middlewares.use(`/${SW_FILE_NAME}`, (_req, res) => {
        res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
        res.setHeader('Cache-Control', 'no-cache');
        res.end(render());
      });
    },
    generateBundle() {
      this.emitFile({ type: 'asset', fileName: SW_FILE_NAME, source: render() });
    },
  };
}
