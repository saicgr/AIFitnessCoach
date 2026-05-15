// Labeled numeric input with unit suffix. Validates min/max, allows decimals.

interface NumberInputProps {
  label: string;
  value: number | '';
  onChange: (v: number | '') => void;
  unit?: string;
  min?: number;
  max?: number;
  step?: number;
  placeholder?: string;
  help?: string;
  className?: string;
}

export default function NumberInput({
  label,
  value,
  onChange,
  unit,
  min,
  max,
  step = 0.1,
  placeholder,
  help,
  className = '',
}: NumberInputProps) {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value;
    if (raw === '') {
      onChange('');
      return;
    }
    const n = parseFloat(raw);
    if (Number.isFinite(n)) onChange(n);
  };

  return (
    <label className={`block ${className}`}>
      <span className="block text-sm font-medium text-zinc-300 mb-1.5">{label}</span>
      <div className="relative">
        <input
          type="number"
          inputMode="decimal"
          value={value === '' ? '' : value}
          onChange={handleChange}
          min={min}
          max={max}
          step={step}
          placeholder={placeholder}
          className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-zinc-700 text-white text-base placeholder-zinc-600 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
        />
        {unit && (
          <span className="absolute right-4 top-1/2 -translate-y-1/2 text-sm text-zinc-500 font-medium pointer-events-none">
            {unit}
          </span>
        )}
      </div>
      {help && <p className="text-xs text-zinc-500 mt-1.5">{help}</p>}
    </label>
  );
}
