import { defineConfig } from 'astro/config';
import myExtIntegration from '/src/config/myExtIntegration';

// refs. https://astro.build/config
export default defineConfig({
  site: 'https://astro.debiru.net',
  trailingSlash: 'always',
  compressHTML: false,
  integrations: [myExtIntegration()],
  build: {
    format: 'directory',
  },
});
