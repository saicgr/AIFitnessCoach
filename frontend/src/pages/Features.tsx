import { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import {
  features,
  categoryLabels,
  categoryIcons,
  searchFeatures,
  getAllCategories,
  getPopularFeatures,
  getNewFeatures,
  type Feature,
  type FeatureCategory,
  type FeatureTier,
} from '../data/featuresData';

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.05 } },
};

const tierColors: Record<FeatureTier, string> = {
  free: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  premium: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  all: 'bg-gray-500/20 text-gray-400 border-gray-500/30',
};

const tierLabels: Record<FeatureTier, string> = {
  free: 'Free',
  premium: 'Premium',
  all: 'All Tiers',
};

function FeatureCard({ feature }: { feature: Feature }) {
  return (
    <motion.div
      variants={fadeUp}
      whileHover={{ y: -4, scale: 1.01 }}
      className="group p-6 rounded-2xl bg-[var(--color-surface)] hover:bg-[var(--color-surface-elevated)] border border-[var(--color-border)] transition-all"
    >
      <div className="flex items-start justify-between gap-4 mb-3">
        <h3 className="text-[17px] font-semibold text-[var(--color-text)] group-hover:text-emerald-400 transition-colors">
          {feature.title}
        </h3>
        <div className="flex items-center gap-2 flex-shrink-0">
          {feature.isNew && (
            <span className="px-2 py-0.5 text-[10px] font-medium bg-emerald-500/20 text-emerald-400 rounded-full">
              NEW
            </span>
          )}
          {feature.isPopular && (
            <span className="px-2 py-0.5 text-[10px] font-medium bg-orange-500/20 text-orange-400 rounded-full">
              POPULAR
            </span>
          )}
        </div>
      </div>

      <p className="text-[14px] text-[var(--color-text-secondary)] leading-relaxed mb-4">
        {feature.description}
      </p>

      <div className="flex items-center justify-between">
        <div className="flex flex-wrap gap-2">
          {feature.tags.slice(0, 3).map((tag) => (
            <span
              key={tag}
              className="px-2 py-0.5 text-[10px] text-[var(--color-text-secondary)] bg-[var(--color-surface-muted)] rounded-full"
            >
              {tag}
            </span>
          ))}
        </div>
        <span className={`px-2 py-0.5 text-[10px] font-medium rounded-full border ${tierColors[feature.tier]}`}>
          {tierLabels[feature.tier]}
        </span>
      </div>
    </motion.div>
  );
}

export default function Features() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<FeatureCategory | 'all'>('all');
  const [selectedTier, setSelectedTier] = useState<FeatureTier | 'all'>('all');
  const [showFilters, setShowFilters] = useState(false);

  const filteredFeatures = useMemo(() => {
    let result = features;

    // Apply search
    if (searchQuery.trim()) {
      result = searchFeatures(searchQuery);
    }

    // Apply category filter
    if (selectedCategory !== 'all') {
      result = result.filter(f => f.category === selectedCategory);
    }

    // Apply tier filter
    if (selectedTier !== 'all') {
      result = result.filter(f => f.tier === selectedTier || f.tier === 'all');
    }

    return result;
  }, [searchQuery, selectedCategory, selectedTier]);

  const categories = getAllCategories();
  const popularFeatures = getPopularFeatures();
  const newFeatures = getNewFeatures();

  const clearFilters = () => {
    setSearchQuery('');
    setSelectedCategory('all');
    setSelectedTier('all');
  };

  const hasActiveFilters = searchQuery || selectedCategory !== 'all' || selectedTier !== 'all';

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      {/* Navigation */}
      <MarketingNav />

      {/* Hero Section */}
      <section className="pt-28 pb-12 px-6">
        <div className="max-w-[1200px] mx-auto text-center">
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[40px] sm:text-[56px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            <span className="bg-gradient-to-r from-emerald-400 via-green-400 to-lime-400 bg-clip-text text-transparent">
              1000+ Features
            </span>
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)] max-w-[600px] mx-auto"
          >
            Everything you need for your fitness journey, powered by AI.
          </motion.p>
        </div>
      </section>

      {/* Search and Filters */}
      <section className="px-6 pb-8 sticky top-16 z-40 bg-[var(--color-surface-glass)] backdrop-blur-xl">
        <div className="max-w-[1200px] mx-auto">
          <div className="flex flex-col md:flex-row gap-4 items-stretch md:items-center">
            {/* Search Input */}
            <div className="relative flex-1">
              <svg
                className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-[var(--color-text-muted)]"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <input
                type="text"
                placeholder="Search features..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-12 pr-4 py-3 rounded-xl bg-[var(--color-surface)] border border-[var(--color-border)] text-[var(--color-text)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-emerald-500/50 transition-colors"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery('')}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)] hover:text-[var(--color-text)]"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              )}
            </div>

            {/* Filter Toggle */}
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center gap-2 px-4 py-3 rounded-xl border transition-colors ${
                showFilters || hasActiveFilters
                  ? 'bg-emerald-500/20 border-emerald-500/50 text-emerald-400'
                  : 'bg-[var(--color-surface)] border-[var(--color-border)] text-[var(--color-text)] hover:text-[var(--color-text)]'
              }`}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
              </svg>
              <span className="text-sm font-medium">Filters</span>
              {hasActiveFilters && (
                <span className="w-2 h-2 rounded-full bg-emerald-400" />
              )}
            </button>

            {/* Clear Filters */}
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="px-4 py-3 rounded-xl bg-[var(--color-surface)] border border-[var(--color-border)] text-[var(--color-text-secondary)] hover:text-[var(--color-text)] text-sm transition-colors"
              >
                Clear all
              </button>
            )}
          </div>

          {/* Filter Dropdowns */}
          <AnimatePresence>
            {showFilters && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                exit={{ opacity: 0, height: 0 }}
                className="overflow-hidden"
              >
                <div className="flex flex-wrap gap-4 pt-4">
                  {/* Category Filter */}
                  <div className="flex-1 min-w-[200px]">
                    <label className="block text-xs text-[var(--color-text-secondary)] mb-2">Category</label>
                    <select
                      value={selectedCategory}
                      onChange={(e) => setSelectedCategory(e.target.value as FeatureCategory | 'all')}
                      className="w-full px-4 py-2.5 rounded-xl bg-[var(--color-surface)] border border-[var(--color-border)] text-[var(--color-text)] focus:outline-none focus:border-emerald-500/50 cursor-pointer"
                    >
                      <option value="all">All Categories</option>
                      {categories.map((cat) => (
                        <option key={cat} value={cat}>
                          {categoryLabels[cat]}
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* Tier Filter */}
                  <div className="flex-1 min-w-[200px]">
                    <label className="block text-xs text-[var(--color-text-secondary)] mb-2">Tier</label>
                    <select
                      value={selectedTier}
                      onChange={(e) => setSelectedTier(e.target.value as FeatureTier | 'all')}
                      className="w-full px-4 py-2.5 rounded-xl bg-[var(--color-surface)] border border-[var(--color-border)] text-[var(--color-text)] focus:outline-none focus:border-emerald-500/50 cursor-pointer"
                    >
                      <option value="all">All Tiers</option>
                      <option value="free">Free</option>
                      <option value="premium">Premium</option>
                    </select>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Results Count */}
          <div className="flex items-center justify-between mt-4 text-sm text-[var(--color-text-secondary)]">
            <span>
              {filteredFeatures.length} feature{filteredFeatures.length !== 1 ? 's' : ''} found
            </span>
            <div className="flex items-center gap-4">
              <button
                onClick={() => {
                  setSelectedCategory('all');
                  setSelectedTier('all');
                  setSearchQuery('');
                }}
                className={`hover:text-emerald-400 transition-colors ${!hasActiveFilters ? 'text-emerald-400' : ''}`}
              >
                All
              </button>
              <button
                onClick={() => {
                  clearFilters();
                  // Show only popular
                }}
                className="hover:text-emerald-400 transition-colors"
              >
                Popular ({popularFeatures.length})
              </button>
              <button
                onClick={() => {
                  clearFilters();
                  // Show only new
                }}
                className="hover:text-emerald-400 transition-colors"
              >
                New ({newFeatures.length})
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Category Quick Links */}
      {!hasActiveFilters && (
        <section className="px-6 pb-8">
          <div className="max-w-[1200px] mx-auto">
            <div className="flex flex-wrap gap-2">
              {categories.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className="flex items-center gap-2 px-4 py-2 rounded-full bg-[var(--color-surface)] hover:bg-[var(--color-surface-elevated)] border border-[var(--color-border)] text-sm text-[var(--color-text)] hover:text-[var(--color-text)] transition-all"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d={categoryIcons[cat]} />
                  </svg>
                  {categoryLabels[cat]}
                </button>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* Features Grid */}
      <section className="px-6 pb-20">
        <div className="max-w-[1200px] mx-auto">
          {filteredFeatures.length > 0 ? (
            <motion.div
              initial="hidden"
              animate="visible"
              variants={stagger}
              className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"
            >
              {filteredFeatures.map((feature) => (
                <FeatureCard key={feature.id} feature={feature} />
              ))}
            </motion.div>
          ) : (
            <div className="text-center py-20">
              <svg
                className="w-16 h-16 mx-auto text-[var(--color-text-muted)] mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1}
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <h3 className="text-xl font-semibold text-[var(--color-text)] mb-2">No features found</h3>
              <p className="text-[var(--color-text-secondary)] mb-4">Try adjusting your search or filters</p>
              <button
                onClick={clearFilters}
                className="px-6 py-2.5 rounded-full bg-emerald-500 text-white hover:bg-emerald-400 transition-colors"
              >
                Clear filters
              </button>
            </div>
          )}
        </div>
      </section>

      {/* CTA Section */}
      <section className="px-6 py-20 bg-gradient-to-br from-emerald-900/30 to-green-900/20">
        <div className="max-w-[680px] mx-auto text-center">
          <h2
            className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Ready to get started?
          </h2>
          <p className="text-[17px] text-[var(--color-text-secondary)] mb-8">
            Join thousands of users transforming their fitness journey with FitWiz.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              to="/login"
              className="px-8 py-3.5 bg-emerald-500 text-white text-[17px] rounded-full hover:bg-emerald-400 transition-colors"
            >
              Get started free
            </Link>
            <Link
              to="/pricing"
              className="px-8 py-3.5 text-emerald-400 text-[17px] hover:underline transition-all"
            >
              View pricing
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <MarketingFooter />
    </div>
  );
}
