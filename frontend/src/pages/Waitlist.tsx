import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import WaitlistSection from '../components/marketing/WaitlistSection';

export default function Waitlist() {
  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)] selection:bg-emerald-500/20 overflow-x-hidden">
      <MarketingNav />
      <div className="pt-16">
        <WaitlistSection source="waitlist_page" />
      </div>
      <MarketingFooter />
    </div>
  );
}
