import { Link } from 'react-router-dom';

export default function MarketingFooter() {
  return (
    <footer className="bg-[#0F172A] text-white">
      <div className="max-w-[1200px] mx-auto px-6 py-16">
        {/* 4-column grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-12">
          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <Link
              to="/"
              className="text-[22px] font-bold tracking-[-0.02em] text-white hover:text-emerald-400 transition-colors"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              FitWiz
            </Link>
            <p className="mt-3 text-sm text-slate-400 leading-relaxed">
              Your AI-powered fitness coach. Personalized workouts, nutrition tracking, and real-time guidance.
            </p>
          </div>

          {/* Product */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-4">Product</h4>
            <ul className="space-y-3">
              <li><Link to="/features" className="text-sm text-slate-400 hover:text-white transition-colors">Features</Link></li>
              <li><Link to="/pricing" className="text-sm text-slate-400 hover:text-white transition-colors">Pricing</Link></li>
              <li><Link to="/store" className="text-sm text-slate-400 hover:text-white transition-colors">Store</Link></li>
              <li><Link to="/login" className="text-sm text-slate-400 hover:text-white transition-colors">Get Started</Link></li>
            </ul>
          </div>

          {/* Company */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-4">Company</h4>
            <ul className="space-y-3">
              <li><Link to="/" className="text-sm text-slate-400 hover:text-white transition-colors">About</Link></li>
              <li><Link to="/" className="text-sm text-slate-400 hover:text-white transition-colors">Blog</Link></li>
              <li><Link to="/" className="text-sm text-slate-400 hover:text-white transition-colors">Careers</Link></li>
              <li><Link to="/" className="text-sm text-slate-400 hover:text-white transition-colors">Contact</Link></li>
            </ul>
          </div>

          {/* Legal */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-4">Legal</h4>
            <ul className="space-y-3">
              <li><Link to="/terms" className="text-sm text-slate-400 hover:text-white transition-colors">Terms of Service</Link></li>
              <li><Link to="/privacy" className="text-sm text-slate-400 hover:text-white transition-colors">Privacy Policy</Link></li>
              <li><Link to="/refunds" className="text-sm text-slate-400 hover:text-white transition-colors">Refund Policy</Link></li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-8 border-t border-slate-700/50">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-slate-500">
              Copyright {new Date().getFullYear()} FitWiz. All rights reserved.
            </p>
            <div className="flex items-center gap-6">
              <Link to="/terms" className="text-sm text-slate-500 hover:text-slate-300 transition-colors">Terms</Link>
              <Link to="/privacy" className="text-sm text-slate-500 hover:text-slate-300 transition-colors">Privacy</Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
