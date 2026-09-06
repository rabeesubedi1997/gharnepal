import { clsx } from 'clsx'

interface Tab {
  key: string
  label: string
}

interface TabsProps {
  tabs: Tab[]
  active: string
  onChange: (key: string) => void
}

export function Tabs({ tabs, active, onChange }: TabsProps) {
  return (
    <div role="tablist" className="flex gap-1 border-b border-stone-200">
      {tabs.map((tab) => (
        <button
          key={tab.key}
          role="tab"
          type="button"
          aria-selected={active === tab.key}
          onClick={() => onChange(tab.key)}
          className={clsx(
            'border-b-2 px-4 py-2.5 text-sm font-medium transition-colors',
            active === tab.key
              ? 'border-trust-700 text-trust-700'
              : 'border-transparent text-ink-700/70 hover:text-ink-900',
          )}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}
