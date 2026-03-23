import myExtIntegration from './myExtIntegration';

// refs. https://astro.build/config
export const astroConfig = {
  base: '/',
  site: 'https://astro.debiru.net',
  trailingSlash: 'always',
  compressHTML: false,
  integrations: [myExtIntegration()],
  build: {
    format: 'directory',
  },
};
