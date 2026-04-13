"use client";

import { motion } from "framer-motion";
import { ShieldCheck, Eye, Bot, Brain, Monitor, Users } from "lucide-react";

const rules = [
  {
    icon: Eye,
    title: "No obfuscated data",
    description:
      "Only reads Riot's own APIs. No memory reading, no code injection, no hidden information.",
  },
  {
    icon: Bot,
    title: "No automation",
    description:
      "Spell tracking is manual (you press a hotkey). The app never plays the game for you.",
  },
  {
    icon: Brain,
    title: "No decision-making",
    description:
      'CS benchmarks show static averages. No real-time coaching or "you should do X" prompts.',
  },
  {
    icon: Monitor,
    title: "No vision hacks",
    description:
      "The overlay displays the same information already available to you in-game.",
  },
  {
    icon: Users,
    title: "No player tracking",
    description:
      "Hexlens does not collect, store, or transmit any player data. Zero telemetry.",
  },
];

export function Compliance() {
  return (
    <section className="py-24 px-6 border-t border-white/[0.04]">
      <div className="max-w-4xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <div className="inline-flex items-center gap-2 mb-4">
            <ShieldCheck className="w-6 h-6 text-[#4ade80]" />
            <h2 className="text-2xl sm:text-3xl font-bold tracking-tight">
              Riot-compliant. Always.
            </h2>
          </div>
          <p className="text-white/45 max-w-xl mx-auto">
            Hexlens follows{" "}
            <a
              href="https://support-leagueoflegends.riotgames.com/hc/en-us/articles/225266848-Third-Party-Applications"
              className="text-[#c8aa6e] hover:underline"
              target="_blank"
              rel="noopener noreferrer"
            >
              Riot&apos;s Third Party Application Policy
            </a>
            . Same rules as Blitz and Porofessor. Free, open source, no ads.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {rules.map((rule, i) => (
            <motion.div
              key={rule.title}
              initial={{ opacity: 0, y: 15 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.3, delay: i * 0.06 }}
              className="flex gap-3 p-4 rounded-lg border border-white/[0.04] bg-white/[0.01]"
            >
              <rule.icon className="w-5 h-5 text-[#4ade80] flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="text-sm font-semibold mb-1">{rule.title}</h3>
                <p className="text-xs text-white/40 leading-relaxed">
                  {rule.description}
                </p>
              </div>
            </motion.div>
          ))}
        </div>

        <p className="text-center text-xs text-white/20 mt-8">
          The League Client API is not officially supported by Riot for
          third-party use, but is tolerated (every major companion app uses it).
          Hexlens will never get your account banned.
        </p>
      </div>
    </section>
  );
}
