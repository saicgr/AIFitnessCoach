import { useEffect } from 'react';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import KineticHero from '../components/landing/KineticHero';
import StatMarquee from '../components/landing/StatMarquee';
import FeatureStory from '../components/landing/FeatureStory';
import FreeToolsShowcase from '../components/landing/FreeToolsShowcase';
import ComparisonTeaser from '../components/landing/ComparisonTeaser';
import PricingSection from '../components/landing/PricingSection';
import FAQSection from '../components/landing/FAQSection';
import WaitlistCTA from '../components/landing/WaitlistCTA';
import { BRANDING } from '../lib/branding';
import '../components/landing/landing.css';

// "Dark kinetic volt" homepage. Hardcoded dark (ignores the app theme
// toggle); every section renders complete, crawlable HTML at initial
// render — motion is layered on top in effects, gated by runtimeEnv.

export default function MarketingLanding() {
  useEffect(() => {
    document.title = `${BRANDING.appName}: AI Workout & Meal Coach`;
    const setMeta = (key: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, key);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    const description =
      'Zealova is your AI workout and meal coach. Personalized training plans, real-time coaching mid-set, photo food logging, and progress analytics that adapt weekly. 7-day free trial.';
    setMeta('description', description);
    setMeta('og:title', `${BRANDING.appName}: AI Workout & Meal Coach`, true);
    setMeta('og:description', description, true);
    setMeta('og:url', `https://${BRANDING.marketingDomain}/`, true);
    setMeta('og:type', 'website', true);
    setMeta('og:image', `https://${BRANDING.marketingDomain}/og/home.png`, true);
    setMeta('og:image:width', '1200', true);
    setMeta('og:image:height', '630', true);
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:title', `${BRANDING.appName}: AI Workout & Meal Coach`);
    setMeta('twitter:description', description);
    setMeta('twitter:image', `https://${BRANDING.marketingDomain}/og/home.png`);

    // Self-referencing canonical — explicit (not relying on the prerender
    // fallback injection) so it consolidates signals against trailing-slash
    // and query-param variants and survives client-side navigation.
    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = `https://${BRANDING.marketingDomain}/`;
  }, []);

  const organizationJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Organization',
    name: BRANDING.appName,
    url: `https://${BRANDING.marketingDomain}`,
    logo: `https://${BRANDING.marketingDomain}/zealova-logo.png`,
    sameAs: [
      BRANDING.instagram,
      'https://tiktok.com/@getzealova',
      'https://youtube.com/@getzealova',
      'https://x.com/getzealova',
      'https://reddit.com/r/zealova',
    ],
  };

  const softwareJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name: `${BRANDING.appName}: AI Workout & Meal Coach`,
    operatingSystem: 'Android',
    applicationCategory: 'HealthApplication',
    url: `https://${BRANDING.marketingDomain}`,
    installUrl: 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app',
    offers: [
      { '@type': 'Offer', price: '7.99', priceCurrency: 'USD', description: 'Premium monthly, 7-day free trial' },
      { '@type': 'Offer', price: '59.99', priceCurrency: 'USD', description: 'Premium yearly ($5/mo, 37% off), 7-day free trial' },
    ],
    publisher: { '@type': 'Organization', name: BRANDING.appName, url: `https://${BRANDING.marketingDomain}` },
  };

  return (
    <div className="vl-page min-h-screen overflow-x-clip">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(organizationJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareJsonLd) }}
      />
      <MarketingNav />
      <main>
        <KineticHero />
        <StatMarquee />
        <FeatureStory />
        <FreeToolsShowcase />
        <ComparisonTeaser />
        <PricingSection />
        <FAQSection />
        <WaitlistCTA />
      </main>
      <MarketingFooter />
    </div>
  );
}
