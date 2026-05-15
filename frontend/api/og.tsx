// Vercel OG dynamic image — /api/og?slug=<tool>&title=<title>&result=<result>
//
// Returns a 1200x630 PNG used as the og:image / twitter:image for free-tool
// pages. Per-result share previews drive virality: a Twitter screenshot of
// "My TDEE = 2,450 cal/day · zealova.com" beats a generic logo card.

import { ImageResponse } from '@vercel/og';

// Vercel Functions config (not Next.js syntax). Edge runtime required:
// @vercel/og uses Web APIs like Response streaming + WebAssembly that need
// the Edge runtime; Node would crash with FUNCTION_INVOCATION_FAILED.
export const config = {
  runtime: 'edge',
};

export default function handler(request: Request) {
  const { searchParams } = new URL(request.url);
  const title = (searchParams.get('title') || 'My Result').slice(0, 60);
  const result = (searchParams.get('result') || '').slice(0, 80);
  const slug = (searchParams.get('slug') || '').slice(0, 60);
  const subtitle = (searchParams.get('subtitle') || 'Calculated free at zealova.com').slice(0, 90);

  return new ImageResponse(
    (
      <div
        style={{
          width: '1200px',
          height: '630px',
          display: 'flex',
          flexDirection: 'column',
          background: 'linear-gradient(135deg, #052e16 0%, #09090b 60%)',
          color: 'white',
          padding: '72px',
          fontFamily: 'system-ui, sans-serif',
          position: 'relative',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px', fontSize: '26px', fontWeight: 700 }}>
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '12px',
              background: '#10b981',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#052e16',
              fontWeight: 900,
              fontSize: '24px',
            }}
          >
            Z
          </div>
          <span>Zealova</span>
        </div>

        <div style={{ marginTop: '80px', display: 'flex', flexDirection: 'column' }}>
          <div
            style={{
              fontSize: '24px',
              fontWeight: 600,
              color: '#34d399',
              textTransform: 'uppercase',
              letterSpacing: '3px',
              marginBottom: '20px',
            }}
          >
            {title}
          </div>
          <div
            style={{
              fontSize: result.length > 30 ? '88px' : '128px',
              fontWeight: 900,
              lineHeight: 1.05,
              letterSpacing: '-3px',
              color: 'white',
              maxWidth: '1060px',
              display: 'flex',
            }}
          >
            {result || 'Get your result'}
          </div>
        </div>

        <div
          style={{
            position: 'absolute',
            bottom: '60px',
            left: '72px',
            right: '72px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            fontSize: '22px',
            color: '#a1a1aa',
          }}
        >
          <span>{subtitle}</span>
          <span style={{ color: '#34d399', fontWeight: 700 }}>
            zealova.com{slug ? `/free-tools/${slug}` : ''}
          </span>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  );
}
