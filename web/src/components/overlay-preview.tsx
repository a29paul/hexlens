"use client";

import { motion } from "framer-motion";

const timers = [
  { icon: "🐉", name: "Dragon", value: "0:28", urgent: true },
  { icon: "👹", name: "Baron", value: "3:42", urgent: false },
  { icon: "🔵", name: "Blue (Enemy)", value: "UP", up: true },
  { icon: "🔴", name: "Red (Enemy)", value: "1:15", urgent: false },
];

const spells = [
  { champ: "Caitlyn", s1: "42s", s1Ready: false, s2: "✓", s2Ready: true },
  { champ: "Thresh", s1: "✓", s1Ready: true, s2: "180", s2Ready: false },
  { champ: "Lee Sin", s1: "95s", s1Ready: false, s2: "✓", s2Ready: true },
];

function OverlayCard({
  children,
  delay = 0,
}: {
  children: React.ReactNode;
  delay?: number;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 30 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-100px" }}
      transition={{ duration: 0.5, delay }}
      className="bg-black/70 backdrop-blur-xl border border-white/[0.06] rounded-xl p-5 w-[280px] shadow-2xl"
    >
      {children}
    </motion.div>
  );
}

function SectionLabel({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-[10px] uppercase tracking-[1.5px] text-white/40 font-medium mb-3">
      {children}
    </p>
  );
}

export function OverlayPreview() {
  return (
    <section className="relative py-16 px-6">
      <div className="flex justify-center gap-6 flex-wrap">
        {/* CS Tracker */}
        <OverlayCard delay={0}>
          <SectionLabel>CS Tracker</SectionLabel>
          <div className="flex items-baseline justify-between">
            <span className="text-4xl font-extrabold tabular-nums">142</span>
            <span className="text-sm font-semibold text-[#4ade80]">
              +12 vs avg
            </span>
          </div>
        </OverlayCard>

        {/* Jungle Timers */}
        <OverlayCard delay={0.1}>
          <SectionLabel>Jungle Timers</SectionLabel>
          <div className="space-y-1">
            {timers.map((t) => (
              <div
                key={t.name}
                className="flex justify-between items-center text-sm"
              >
                <span className="text-white/50">
                  {t.icon} {t.name}
                </span>
                <span
                  className={`font-semibold tabular-nums ${
                    t.urgent
                      ? "text-[#f87171] animate-pulse"
                      : t.up
                        ? "text-[#facc15]"
                        : "text-white/40"
                  }`}
                >
                  {t.value}
                </span>
              </div>
            ))}
          </div>
        </OverlayCard>

        {/* Spell Tracker */}
        <OverlayCard delay={0.2}>
          <SectionLabel>Enemy Summoner Spells</SectionLabel>
          <div className="space-y-1.5">
            {spells.map((s) => (
              <div key={s.champ} className="flex items-center gap-2 text-xs">
                <span className="text-white/40 w-16">{s.champ}</span>
                <SpellBadge value={s.s1} ready={s.s1Ready} />
                <SpellBadge value={s.s2} ready={s.s2Ready} />
              </div>
            ))}
          </div>
        </OverlayCard>
      </div>
    </section>
  );
}

function SpellBadge({ value, ready }: { value: string; ready: boolean }) {
  return (
    <span
      className={`w-6 h-6 rounded flex items-center justify-center text-[10px] font-bold tabular-nums ${
        ready
          ? "bg-[#4ade80] text-black"
          : "bg-white/[0.06] text-[#f87171]"
      }`}
    >
      {value}
    </span>
  );
}
