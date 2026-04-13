"use client";

import { motion } from "framer-motion";
import {
  Zap,
  Crosshair,
  BarChart3,
  Timer,
  Sparkles,
  Gamepad2,
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
      "Benchmarks that know the difference between a jungler and an ADC.",
  },
  {
    icon: Timer,
    title: "Jungle Timers",
    description:
      "Dragon, Baron, buffs. Respawn countdowns from live game events.",
  },
  {
    icon: Sparkles,
    title: "Rune Import",
    description:
      "One click in champ select. Recommended runes written directly to your client.",
  },
  {
    icon: Gamepad2,
    title: "Spell Tracking",
    description:
      "F1-F10 hotkeys to mark enemy summoner spells. Cooldowns auto-calculated.",
  },
];

export function Features() {
  return (
    <section className="py-24 px-6 max-w-5xl mx-auto">
      <motion.h2
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="text-3xl sm:text-4xl font-bold text-center mb-16 tracking-tight"
      >
        Everything you need, nothing you don&apos;t.
      </motion.h2>

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
