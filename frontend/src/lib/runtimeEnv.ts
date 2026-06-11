/**
 * Runtime environment gates for animation / WebGL features.
 *
 * The marketing site is SSG-prerendered by a headless Puppeteer crawler
 * (scripts/prerender.mjs). Everything that moves — GSAP intro tweens, the
 * WebGL hero backdrop, the live phone demo — must be skipped during
 * prerender so that:
 *   1. the HTML snapshot contains fully-visible, settled content, and
 *   2. headless Chromium never creates a WebGL context (SwiftShader can
 *      hang the render and bloat the run).
 *
 * Rule for components: render the COMPLETE static state by default, then
 * enhance with motion in useEffect only when these gates allow it.
 */

declare global {
  interface Window {
    __PRERENDER__?: boolean;
  }
}

/** True when running under the SSG prerender crawler (or any webdriver). */
export function isPrerender(): boolean {
  if (typeof window === 'undefined') return true;
  return Boolean(window.__PRERENDER__) || Boolean(navigator.webdriver);
}

/** True when the user has requested reduced motion at the OS level. */
export function prefersReducedMotion(): boolean {
  if (typeof window === 'undefined' || !window.matchMedia) return false;
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

let webglSupport: boolean | null = null;

/** Cached probe — true when a WebGL(2) context can actually be created. */
export function canWebGL(): boolean {
  if (webglSupport !== null) return webglSupport;
  try {
    const canvas = document.createElement('canvas');
    const gl =
      canvas.getContext('webgl2') ||
      canvas.getContext('webgl') ||
      canvas.getContext('experimental-webgl');
    webglSupport = Boolean(gl);
  } catch {
    webglSupport = false;
  }
  return webglSupport;
}

/** Convenience: should fancy motion run at all? */
export function motionAllowed(): boolean {
  return !isPrerender() && !prefersReducedMotion();
}
