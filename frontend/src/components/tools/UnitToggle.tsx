// Generic two-option toggle (e.g. kg/lb, cm/in).

interface UnitToggleProps<T extends string> {
  value: T;
  options: readonly { value: T; label: string }[];
  onChange: (v: T) => void;
  label?: string;
  className?: string;
}

export default function UnitToggle<T extends string>({
  value,
  options,
  onChange,
  label,
  className = '',
}: UnitToggleProps<T>) {
  return (
    <div className={`flex items-center gap-2 ${className}`}>
      {label && <span className="text-xs text-zinc-500">{label}</span>}
      <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-900 p-0.5">
        {options.map((opt) => {
          const active = opt.value === value;
          return (
            <button
              key={opt.value}
              type="button"
              onClick={() => onChange(opt.value)}
              className={`px-3 py-1 text-xs font-medium rounded-md transition ${
                active
                  ? 'bg-emerald-500 text-zinc-900'
                  : 'text-zinc-400 hover:text-white'
              }`}
            >
              {opt.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}
