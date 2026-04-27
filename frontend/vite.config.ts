import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'
import { BRANDING } from './src/lib/branding'

// HTML transform plugin — substitutes %BRAND_*% placeholders in index.html
// at build time so the static HTML reads from src/lib/branding.ts. A future
// rename only requires editing branding.ts; index.html stays untouched.
function htmlBrandingPlugin() {
  return {
    name: 'html-branding',
    transformIndexHtml(html: string) {
      return html
        .replace(/%BRAND_NAME%/g, BRANDING.appName)
        .replace(/%BRAND_FULL_TITLE%/g, BRANDING.fullTitle)
        .replace(/%BRAND_TAGLINE%/g, BRANDING.tagline)
        .replace(/%BRAND_DOMAIN%/g, BRANDING.marketingDomain)
        .replace(/%BRAND_WEBSITE%/g, BRANDING.websiteUrl)
    },
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [htmlBrandingPlugin(), react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})
