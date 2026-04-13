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
  Swords,
  Eye,
  MousePointerClick,
  Keyboard,
  Ban,
} from "lucide-react";

const features = [
  {
    icon: Ban,
    title: "No Ads. Ever.",
    description:
      "Free and open source. No ads, no premium tier, no Overwolf pop-ups. Riot banned overlay ads in 2025. We never had them.",
  },
  {
    icon: Zap,
    title: "Native Swift",
    description:
      "30MB, not 300MB. No Electron, no Overwolf. Built for Mac from the ground up. Works in fullscreen.",
  },
  {
    icon: Keyboard,
    title: "Tab to Show",
    description:
      "Hold Tab to see the overlay, release to hide. Same muscle memory as the LoL scoreboard. Zero distraction.",
  },
  {
    icon: MousePointerClick,
    title: "Click-to-Track Spells",
    description:
      "Click enemy summoner spell icons when used. Cooldowns start automatically. Real spell icons from Data Dragon.",
  },
  {
    icon: Swords,
    title: "Ult Cooldown Tracking",
    description:
      "Click the R badge when an enemy ults. Per-champion cooldowns from Meraki (170+ champs), reduced by their actual ability haste from items.",
  },
  {
    icon: TrendingUp,
    title: "Gold Scoreboard",
    description:
      "Per-lane gold matchups with champion portraits. Team totals and gold diff. See who's winning every lane at a glance.",
  },
  {
    icon: BarChart3,
    title: "Player Stats",
    description:
      "CS/min, Gold/min, Kill Participation %, Vision/min, KDA, and level. All updated live from the Riot API.",
  },
  {
    icon: Users,
    title: "Ally Tracker",
    description:
      "Teammate champion, level, ult readiness, and alive/dead status. Know when to engage.",
  },
  {
    icon: Sparkles,
    title: "Rune Import",
    description:
      "One click in champ select. Recommended runes written directly to your client via the LCU API.",
  },
  {
    icon: Crosshair,
    title: "Auto-detect + Mid-game Join",
    description:
      "Detects LoL automatically. Launch the app mid-game and it picks up where you are. Menu bar app, no dock clutter.",
  },
  {
    icon: Eye,
    title: "Champion Portraits",
    description:
      "Real champion icons and summoner spell images loaded from Riot's Data Dragon CDN. Name fallback if offline.",
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
        No ads. No Overwolf. Native performance. Hold Tab to see it all.
      </motion.p>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        {features.map((feature, i) => (
          <motion.div
            key={feature.title}
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-50px" }}
            transition={{ duration: 0.4, delay: i * 0.06 }}
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
