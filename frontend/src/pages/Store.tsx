import { useState } from 'react';
import { motion } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
};

type ProductCategory = 'all' | 'apparel' | 'accessories' | 'supplements' | 'digital';

interface Product {
  id: string;
  name: string;
  description: string;
  price: number;
  originalPrice?: number;
  image: string;
  category: ProductCategory;
  badge?: string;
  rating?: number;
  reviews?: number;
  inStock: boolean;
  comingSoon?: boolean;
}

const products: Product[] = [
  // Apparel
  {
    id: 'tee-classic',
    name: 'FitWiz Classic Tee',
    description: 'Premium cotton blend performance tee with moisture-wicking technology',
    price: 29.99,
    image: '👕',
    category: 'apparel',
    rating: 4.8,
    reviews: 124,
    inStock: true,
  },
  {
    id: 'hoodie-performance',
    name: 'Performance Hoodie',
    description: 'Lightweight hoodie perfect for warm-ups and cool-downs',
    price: 59.99,
    originalPrice: 79.99,
    image: '🧥',
    category: 'apparel',
    badge: 'SALE',
    rating: 4.9,
    reviews: 89,
    inStock: true,
  },
  {
    id: 'tank-training',
    name: 'Training Tank Top',
    description: 'Breathable mesh tank for intense workout sessions',
    price: 24.99,
    image: '🎽',
    category: 'apparel',
    rating: 4.7,
    reviews: 56,
    inStock: true,
  },
  {
    id: 'shorts-athletic',
    name: 'Athletic Shorts',
    description: 'Quick-dry shorts with hidden pocket for phone',
    price: 34.99,
    image: '🩳',
    category: 'apparel',
    rating: 4.6,
    reviews: 78,
    inStock: true,
  },
  // Accessories
  {
    id: 'bottle-pro',
    name: 'Pro Water Bottle',
    description: '32oz insulated bottle with time markers',
    price: 24.99,
    image: '🍶',
    category: 'accessories',
    badge: 'BESTSELLER',
    rating: 4.9,
    reviews: 312,
    inStock: true,
  },
  {
    id: 'bag-gym',
    name: 'Gym Duffel Bag',
    description: 'Spacious 40L bag with shoe compartment',
    price: 49.99,
    image: '👜',
    category: 'accessories',
    rating: 4.7,
    reviews: 145,
    inStock: true,
  },
  {
    id: 'bands-resistance',
    name: 'Resistance Bands Set',
    description: '5 bands with different resistance levels + carry bag',
    price: 29.99,
    image: '🏋️',
    category: 'accessories',
    rating: 4.8,
    reviews: 234,
    inStock: true,
  },
  {
    id: 'towel-cooling',
    name: 'Cooling Workout Towel',
    description: 'Instant cooling technology, stays cool for 3 hours',
    price: 14.99,
    image: '🧊',
    category: 'accessories',
    rating: 4.5,
    reviews: 89,
    inStock: true,
  },
  // Supplements
  {
    id: 'protein-whey',
    name: 'Premium Whey Protein',
    description: '25g protein per serving, low sugar, great taste',
    price: 44.99,
    image: '🥛',
    category: 'supplements',
    badge: 'NEW',
    rating: 4.8,
    reviews: 156,
    inStock: false,
    comingSoon: true,
  },
  {
    id: 'preworkout-energy',
    name: 'Energy Pre-Workout',
    description: 'Clean energy boost without the crash',
    price: 34.99,
    image: '⚡',
    category: 'supplements',
    rating: 4.6,
    reviews: 98,
    inStock: false,
    comingSoon: true,
  },
  {
    id: 'creatine-mono',
    name: 'Creatine Monohydrate',
    description: 'Pure micronized creatine, 5g per serving',
    price: 29.99,
    image: '💊',
    category: 'supplements',
    rating: 4.9,
    reviews: 201,
    inStock: false,
    comingSoon: true,
  },
  // Digital Products
  {
    id: 'ebook-nutrition',
    name: 'Nutrition Mastery Guide',
    description: '100+ page guide to optimizing your diet for fitness',
    price: 19.99,
    originalPrice: 39.99,
    image: '📚',
    category: 'digital',
    badge: '50% OFF',
    rating: 4.9,
    reviews: 423,
    inStock: true,
  },
  {
    id: 'program-12week',
    name: '12-Week Transformation',
    description: 'Complete workout program with nutrition plan',
    price: 49.99,
    image: '📋',
    category: 'digital',
    badge: 'POPULAR',
    rating: 4.8,
    reviews: 287,
    inStock: true,
  },
  {
    id: 'templates-meal',
    name: 'Meal Prep Templates',
    description: '52 weekly meal prep templates + shopping lists',
    price: 14.99,
    image: '🍽️',
    category: 'digital',
    rating: 4.7,
    reviews: 156,
    inStock: true,
  },
  {
    id: 'bundle-starter',
    name: 'Starter Bundle',
    description: 'All digital products + 30 days Premium access',
    price: 69.99,
    originalPrice: 124.97,
    image: '🎁',
    category: 'digital',
    badge: 'BEST VALUE',
    rating: 4.9,
    reviews: 89,
    inStock: true,
  },
];

const categories: { id: ProductCategory; label: string; icon: string }[] = [
  { id: 'all', label: 'All Products', icon: '🛍️' },
  { id: 'apparel', label: 'Apparel', icon: '👕' },
  { id: 'accessories', label: 'Accessories', icon: '🎒' },
  { id: 'supplements', label: 'Supplements', icon: '💊' },
  { id: 'digital', label: 'Digital', icon: '📱' },
];

export default function Store() {
  const [selectedCategory, setSelectedCategory] = useState<ProductCategory>('all');
  const [cart, setCart] = useState<{ id: string; quantity: number }[]>([]);

  const filteredProducts = selectedCategory === 'all'
    ? products
    : products.filter(p => p.category === selectedCategory);

  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);
  const cartTotal = cart.reduce((sum, item) => {
    const product = products.find(p => p.id === item.id);
    return sum + (product?.price || 0) * item.quantity;
  }, 0);

  const addToCart = (productId: string) => {
    setCart(prev => {
      const existing = prev.find(item => item.id === productId);
      if (existing) {
        return prev.map(item =>
          item.id === productId ? { ...item, quantity: item.quantity + 1 } : item
        );
      }
      return [...prev, { id: productId, quantity: 1 }];
    });
  };

  const _removeFromCart = (productId: string) => {
    setCart(prev => prev.filter(item => item.id !== productId));
  };
  // Expose for future cart drawer implementation
  void _removeFromCart;

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      {/* Navigation */}
      <MarketingNav />

      {/* Hero Section */}
      <section className="pt-28 pb-12 px-6">
        <div className="max-w-[980px] mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-emerald-500/10 border border-emerald-500/20 mb-6"
          >
            <span className="text-xl">🏪</span>
            <span className="text-sm text-emerald-400">Official FitWiz Store</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-[40px] sm:text-[56px] font-semibold tracking-[-0.02em] mb-4"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Gear up for greatness
          </motion.h1>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-[17px] sm:text-[21px] text-[var(--color-text-secondary)] max-w-[600px] mx-auto mb-8"
          >
            Premium apparel, accessories, and supplements to fuel your fitness journey.
          </motion.p>

          {/* Category Filter */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="flex flex-wrap items-center justify-center gap-2"
          >
            {categories.map((cat) => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`px-4 py-2 rounded-full text-sm font-medium transition-all flex items-center gap-2 ${
                  selectedCategory === cat.id
                    ? 'bg-emerald-500 text-white'
                    : 'bg-[var(--color-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-text)] border border-[var(--color-border)]'
                }`}
              >
                <span>{cat.icon}</span>
                {cat.label}
              </button>
            ))}
          </motion.div>
        </div>
      </section>

      {/* Products Grid */}
      <section className="px-6 pb-20">
        <motion.div
          initial="hidden"
          animate="visible"
          variants={stagger}
          className="max-w-[1200px] mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
        >
          {filteredProducts.map((product) => (
            <motion.div
              key={product.id}
              variants={fadeUp}
              className={`relative p-5 rounded-3xl bg-[var(--color-surface)] border transition-all hover:border-[var(--color-border)] ${
                product.comingSoon ? 'opacity-75' : 'border-[var(--color-border)]'
              }`}
            >
              {product.badge && (
                <div className={`absolute top-4 right-4 px-2.5 py-1 text-[10px] font-semibold rounded-full ${
                  product.badge === 'SALE' || product.badge === '50% OFF'
                    ? 'bg-red-500 text-white'
                    : product.badge === 'NEW'
                    ? 'bg-blue-500 text-white'
                    : 'bg-lime-400 text-black'
                }`}>
                  {product.badge}
                </div>
              )}

              {/* Product Image */}
              <div className="w-full aspect-square rounded-2xl bg-gradient-to-br from-[var(--color-surface-elevated)] to-[var(--color-surface)] flex items-center justify-center mb-4">
                <span className="text-6xl">{product.image}</span>
              </div>

              {/* Product Info */}
              <div className="space-y-2">
                <h3 className="text-[17px] font-semibold text-[var(--color-text)]">{product.name}</h3>
                <p className="text-[13px] text-[var(--color-text-secondary)] line-clamp-2">{product.description}</p>

                {/* Rating */}
                {product.rating && (
                  <div className="flex items-center gap-2">
                    <div className="flex items-center gap-0.5">
                      {[...Array(5)].map((_, i) => (
                        <span key={i} className={`text-xs ${i < Math.floor(product.rating!) ? 'text-yellow-400' : 'text-[var(--color-text-muted)]'}`}>
                          ★
                        </span>
                      ))}
                    </div>
                    <span className="text-[12px] text-[var(--color-text-secondary)]">({product.reviews})</span>
                  </div>
                )}

                {/* Price */}
                <div className="flex items-baseline gap-2">
                  <span className="text-[21px] font-bold text-[var(--color-text)]">${product.price}</span>
                  {product.originalPrice && (
                    <span className="text-[15px] text-[var(--color-text-secondary)] line-through">${product.originalPrice}</span>
                  )}
                </div>

                {/* Add to Cart Button */}
                {product.comingSoon ? (
                  <button
                    disabled
                    className="w-full py-3 rounded-xl bg-[var(--color-surface-elevated)] text-[var(--color-text-muted)] text-[15px] font-medium cursor-not-allowed"
                  >
                    Coming Soon
                  </button>
                ) : product.inStock ? (
                  <button
                    onClick={() => addToCart(product.id)}
                    className="w-full py-3 rounded-xl bg-emerald-500 text-white text-[15px] font-medium hover:bg-emerald-400 transition-colors"
                  >
                    Add to Cart
                  </button>
                ) : (
                  <button
                    disabled
                    className="w-full py-3 rounded-xl bg-[var(--color-surface-elevated)] text-[var(--color-text-muted)] text-[15px] font-medium cursor-not-allowed"
                  >
                    Out of Stock
                  </button>
                )}
              </div>
            </motion.div>
          ))}
        </motion.div>
      </section>

      {/* Featured Section - Digital Products */}
      <section className="px-6 py-20 bg-gradient-to-br from-emerald-900/20 to-green-900/10">
        <div className="max-w-[1000px] mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <span className="text-4xl mb-4 block">📱</span>
            <h2
              className="text-[32px] sm:text-[40px] font-semibold tracking-[-0.02em] mb-4"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Digital products, instant access
            </h2>
            <p className="text-[17px] text-[var(--color-text-secondary)] max-w-[600px] mx-auto mb-8">
              Download immediately after purchase. Lifetime access to all digital products.
            </p>
            <button
              onClick={() => setSelectedCategory('digital')}
              className="px-8 py-3.5 bg-emerald-500 text-white text-[17px] rounded-full hover:bg-emerald-400 transition-colors"
            >
              Browse Digital Products
            </button>
          </motion.div>
        </div>
      </section>

      {/* Supplements Coming Soon Banner */}
      <section className="px-6 py-16">
        <div className="max-w-[1000px] mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="p-8 rounded-3xl bg-gradient-to-r from-purple-900/30 to-pink-900/20 border border-purple-500/20 text-center"
          >
            <span className="text-4xl mb-4 block">💪</span>
            <h3 className="text-[24px] font-semibold mb-2">FitWiz Supplements Coming Soon</h3>
            <p className="text-[15px] text-[var(--color-text-secondary)] max-w-[500px] mx-auto mb-6">
              Premium quality supplements formulated for athletes. Sign up to be notified when they launch.
            </p>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <input
                type="email"
                placeholder="Enter your email"
                className="w-full sm:w-80 px-4 py-3 rounded-xl bg-[var(--color-surface)] border border-[var(--color-border)] text-[var(--color-text)] placeholder-[var(--color-text-muted)] focus:outline-none focus:border-purple-500"
              />
              <button className="w-full sm:w-auto px-6 py-3 bg-purple-500 text-white rounded-xl font-medium hover:bg-purple-400 transition-colors">
                Notify Me
              </button>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Trust Badges */}
      <section className="px-6 py-16 bg-[var(--color-surface-muted)]">
        <div className="max-w-[1000px] mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
            {[
              { icon: '🚚', title: 'Free Shipping', desc: 'Orders over $50' },
              { icon: '↩️', title: '30-Day Returns', desc: 'No questions asked' },
              { icon: '🔒', title: 'Secure Checkout', desc: 'SSL encrypted' },
              { icon: '💬', title: '24/7 Support', desc: 'Always here to help' },
            ].map((badge, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="p-4"
              >
                <span className="text-3xl mb-2 block">{badge.icon}</span>
                <h4 className="text-[15px] font-semibold text-[var(--color-text)] mb-1">{badge.title}</h4>
                <p className="text-[13px] text-[var(--color-text-secondary)]">{badge.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Footer */}
      <MarketingFooter />

      {/* Floating Cart (Mobile) */}
      {cartCount > 0 && (
        <motion.div
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="fixed bottom-6 left-6 right-6 md:hidden"
        >
          <button className="w-full py-4 px-6 bg-emerald-500 text-white rounded-2xl font-medium flex items-center justify-between shadow-lg shadow-emerald-500/20">
            <div className="flex items-center gap-3">
              <span className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center text-sm">
                {cartCount}
              </span>
              <span>View Cart</span>
            </div>
            <span className="font-bold">${cartTotal.toFixed(2)}</span>
          </button>
        </motion.div>
      )}
    </div>
  );
}
