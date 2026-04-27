// Centralized app store + legal links.
//
// Brand identity (name, marketing domain, support email) lives in
// `lib/branding.ts`. This file constructs URLs from those values plus
// the locked Play Store package ID.
import { BRANDING } from './branding';

export const APP_LINKS = {
  playStore: `https://play.google.com/store/apps/details?id=${BRANDING.packageIdAndroid}`,
  appStore: '', // TODO: add App Store URL after iOS submission
  website: `https://${BRANDING.marketingDomain}`,
  support: `mailto:${BRANDING.supportEmail}`,
  privacy: `https://${BRANDING.marketingDomain}/privacy`,
  terms: `https://${BRANDING.marketingDomain}/terms`,
} as const;
