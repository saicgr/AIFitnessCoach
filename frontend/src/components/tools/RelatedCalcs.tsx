import { Link } from 'react-router-dom';
import { relatedCalcs } from './calcRegistry';

interface RelatedCalcsProps {
  currentSlug: string;
}

export default function RelatedCalcs({ currentSlug }: RelatedCalcsProps) {
  const related = relatedCalcs(currentSlug, 4);
  if (related.length === 0) return null;

  return (
    <section className="border-t border-zinc-800 pt-12 mt-16">
      <h2 className="text-xl font-bold text-white mb-1">Related calculators</h2>
      <p className="text-sm text-zinc-500 mb-6">More tools in this category.</p>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {related.map((c) => (
          <Link
            key={c.slug}
            to={`/free-tools/${c.slug}`}
            className="block rounded-xl border border-zinc-800 bg-zinc-900 p-4 hover:border-emerald-500/40 hover:bg-zinc-900/50 transition"
          >
            <p className="font-semibold text-white text-sm">{c.name}</p>
            <p className="text-xs text-zinc-400 mt-1 leading-relaxed">{c.description}</p>
          </Link>
        ))}
      </div>
    </section>
  );
}
