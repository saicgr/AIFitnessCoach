import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import WaitlistSection from '../components/marketing/WaitlistSection';

export default function Waitlist() {
  return (
    <div className="min-h-screen bg-[#050505] text-white selection:bg-volt-500/30 overflow-x-hidden">
      <MarketingNav />
      <div className="pt-24">
        <WaitlistSection source="waitlist_page" />
      </div>
      <MarketingFooter />
    </div>
  );
}
