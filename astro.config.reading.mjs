// @ts-check
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  srcDir: './reading-src',
  integrations: [react()],
  site: 'https://june.kim',
  base: '/',
  server: { port: 12346 },
  devToolbar: { enabled: false },
  image: {
    service: { entrypoint: 'astro/assets/services/noop' },
  },
  markdown: {
    shikiConfig: {
      theme: 'github-light',
    },
  },
  vite: {
    plugins: [tailwindcss()],
    server: {
      headers: { 'Cache-Control': 'no-store' },
      hmr: { overlay: true },
    },
  },
});
