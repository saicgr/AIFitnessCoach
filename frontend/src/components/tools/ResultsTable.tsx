// Multi-method comparison table. Rows = methods, columns = name/value/note/highlight.
// Used by 1RM, BMR, Body Fat, Powerlifting, VO2 Max, etc.

export interface ResultRow {
  name: string;
  value: string;          // pre-formatted (with units)
  note?: string;
  recommended?: boolean;  // highlights the best-fit method for this input
  citation?: string;
}

interface ResultsTableProps {
  rows: ResultRow[];
  valueLabel?: string;     // header for value column (e.g. "1RM", "Body Fat %")
  className?: string;
}

export default function ResultsTable({
  rows,
  valueLabel = 'Result',
  className = '',
}: ResultsTableProps) {
  return (
    <div className={`overflow-x-auto rounded-2xl border border-zinc-800 ${className}`}>
      <table className="w-full text-sm">
        <thead className="bg-zinc-900 border-b border-zinc-800">
          <tr>
            <th className="text-left px-4 py-3 font-semibold text-zinc-300">Method</th>
            <th className="text-right px-4 py-3 font-semibold text-zinc-300">{valueLabel}</th>
            <th className="text-left px-4 py-3 font-semibold text-zinc-300 hidden md:table-cell">Best for</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={row.name}
              className={`border-b border-zinc-800 last:border-b-0 ${
                row.recommended ? 'bg-emerald-950/30' : 'bg-zinc-950'
              }`}
            >
              <td className="px-4 py-3">
                <div className="flex items-center gap-2">
                  <span className="font-medium text-white">{row.name}</span>
                  {row.recommended && (
                    <span className="text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-semibold uppercase tracking-wide">
                      Best fit
                    </span>
                  )}
                </div>
                {row.citation && (
                  <p className="text-xs text-zinc-500 mt-0.5">{row.citation}</p>
                )}
              </td>
              <td className="px-4 py-3 text-right font-mono font-semibold text-white">
                {row.value}
              </td>
              <td className="px-4 py-3 text-zinc-400 hidden md:table-cell">
                {row.note}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
