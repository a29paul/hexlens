"use client";

import { motion } from "framer-motion";
import {
  Zap,
  Crosshair,
  BarChart3,
  Timer,
  Sparkles,
  Gamepad2,
  Users,
  TrendingUp,
  Building2,
} from "lucide-react";

const features = [
  {
    icon: Zap,
    title: "Native Swift",
    description:
      "30MB, not 300MB. No Electron, no Overwolf. Built for Mac from the ground up.",
  },
  {
    icon: Crosshair,
    title: "Auto-detect",
    description:
      "Launches automatically when LoL starts. Menu bar app, no dock clutter.",
  },
  {
    icon: BarChart3,
    title: "Role-adaptive CS",
    description:
      "Benchmarks that know the difference between a jungler and an ADC. Shows your CS diff vs rank average in real time.",
  },
  {
    icon: Timer,
    title: "Jungle & Inhib Timers",
    description:
      "Dragon, Baron, buff respawns, and inhibitor countdowns. All tracked from live game events. Pulses red when under 30s.",
  },
  {
    icon: Sparkles,
    title: "Rune Import",
    description:
      "One click in champ select. Recommended runes written directly to your client via the LCU API.",
  },
  {
    icon: Gamepad2,
    title: "Spell Tracking",
    description:
      "F1-F10 hotkeys to mark enemy summoner spells. Cooldowns auto-calculated with CDR. Same feature Blitz and Porofessor ship.",
  },
  {
    icon: Users,
    title: "Ally Tracker",
    description:
      "See your teammates' champion, level, ult readiness, and alive/dead status at a glance. Know when to engage.",
  },
  {
    icon: TrendingUp,
    title: "Gold Lead",
    description:
      "Live team gold differential. Know if you're ahead or behind without checking the scoreboard.",
  },
  {
    icon: Building2,
    title: "Inhibitor Timers",
    description:
      "Tracks enemy inhibitor respawns (5 min countdown). Never miss the window to push and end.",
  },
];

export function Features() {
  return (
    <section className="py-24 px-6 max-w-5xl mx-auto">
      <motion.h2
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="text-3xl sm:text-4xl font-bold text-center mb-4 tracking-tight"
      >
        Everything Blitz and Porofessor do.
        <br />
        <span className="text-white/40">On Mac. For free.</span>
      </motion.h2>
      <motion.p
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        className="text-center text-white/35 mb-16 max-w-lg mx-auto"
      >
        9 features. Zero Overwolf dependency. Native performance.
      </motion.p>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {features.map((feature, i) => (
          <motion.div
            key={feature.title}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-50px" }}
            transition={{ duration: 0.4, delay: i * 0.08 }}
            className="group rounded-xl border border-white/[0.06] bg-white/[0.02] p-6 hover:bg-white/[0.04] hover:border-white/[0.1] transition-colors"
          >
            <feature.icon className="w-8 h-8 text-[#c8aa6e] mb-4 group-hover:scale-110 transition-transform" />
            <h3 className="text-base font-semibold mb-2">{feature.title}</h3>
            <p className="text-sm text-white/45 leading-relaxed">
              {feature.description}
            </p>
          </motion.div>
        ))}
      </div>
    </section>
  );
}
