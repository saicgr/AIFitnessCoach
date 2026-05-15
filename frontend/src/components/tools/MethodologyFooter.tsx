interface Citation {
  text: string;
  url?: string;
}

interface MethodologyFooterProps {
  citations: Citation[];
  lastUpdated?: string;
  className?: string;
}

export default function MethodologyFooter({
  citations,
  lastUpdated,
  className = '',
}: MethodologyFooterProps) {
  return (
    <div className={`text-xs text-zinc-500 leading-relaxed border-t border-zinc-800 pt-6 mt-12 ${className}`}>
      <p className="font-semibold text-zinc-400 mb-2">Methodology + Sources</p>
      <ul className="space-y-1.5">
        {citations.map((c, i) => (
          <li key={i}>
            {c.url ? (
              <a
                href={c.url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-emerald-500 hover:text-emerald-400 underline"
              >
                {c.text}
              </a>
            ) : (
              <span>{c.text}</span>
            )}
          </li>
        ))}
      </ul>
      {lastUpdated && (
        <p className="mt-3 text-zinc-600">Last updated: {lastUpdated}</p>
      )}
      <p className="mt-3 text-zinc-600">
        Built by Sai, founder of Zealova. Not a neutral third party. Calculator results are estimates. For medical decisions, consult a qualified professional.
      </p>
    </div>
  );
}
