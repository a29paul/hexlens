"use client";

import { motion } from "framer-motion";
import {
  Download,
  Terminal,
  Shield,
  Monitor,
  CheckCircle2,
  ArrowLeft,
  Apple,
} from "lucide-react";
import Link from "next/link";

const steps = [
  {
    number: "1",
    title: "Download",
    description: "Grab the latest DMG from GitHub Releases.",
    action: (
      <a
        href="https://github.com/a29paul/hexlens/releases/latest"
        className="inline-flex items-center justify-center gap-2 bg-[#c8aa6e] hover:bg-[#d4ba82] text-[#1a1a2e] font-semibold text-base px-8 h-12 rounded-lg shadow-[0_4px_24px_rgba(200,170,110,0.3)] transition-all hover:-translate-y-0.5 w-full sm:w-auto"
      >
        <Download className="w-5 h-5" />
        Download Hexlens.dmg
      </a>
    ),
  },
  {
    number: "2",
    title: "Install",
    description:
      "Open the DMG and drag Hexlens to your Applications folder. That's it.",
  },
  {
    number: "3",
    title: "Launch",
    description:
      'Open Hexlens from Applications. It appears in your menu bar (not the Dock). You may need to right-click → Open the first time if macOS says "unidentified developer."',
  },
  {
    number: "4",
    title: "Grant permissions",
    description:
      "Hexlens will ask for Accessibility access (needed for spell tracking hotkeys). Go to System Settings → Privacy & Security → Accessibility and toggle Hexlens on.",
  },
  {
    number: "5",
    title: "Play",
    description:
      "Launch League of Legends. Hexlens detects it automatically. The overlay appears when your game starts. Works in both fullscreen and borderless windowed.",
  },
];

export default function InstallPage() {
  return (
    <main className="min-h-screen py-16 px-6">
      <div className="max-w-2xl mx-auto">
        <Link
          href="/"
          className="inline-flex items-center gap-1.5 text-sm text-white/40 hover:text-white/60 transition-colors mb-10"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to home
        </Link>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <h1 className="text-4xl font-extrabold tracking-tight mb-3">
            Install Hexlens
          </h1>
          <p className="text-white/45 text-lg mb-12">
            Up and running in under a minute.
          </p>

          {/* Requirements */}
          <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] p-5 mb-12">
            <h2 className="text-sm font-semibold text-white/60 uppercase tracking-wider mb-3">
              Requirements
            </h2>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-sm">
              <div className="flex items-center gap-2 text-white/50">
                <Apple className="w-4 h-4 text-[#c8aa6e]" />
                macOS 14 (Sonoma)+
              </div>
              <div className="flex items-center gap-2 text-white/50">
                <Monitor className="w-4 h-4 text-[#c8aa6e]" />
                Fullscreen supported
              </div>
              <div className="flex items-center gap-2 text-white/50">
                <Shield className="w-4 h-4 text-[#c8aa6e]" />
                Accessibility access
              </div>
            </div>
          </div>

          {/* Steps */}
          <div className="space-y-8 mb-16">
            {steps.map((step, i) => (
              <motion.div
                key={step.number}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.4, delay: i * 0.1 }}
                className="flex gap-5"
              >
                <div className="flex-shrink-0 w-9 h-9 rounded-full bg-[#c8aa6e]/10 border border-[#c8aa6e]/20 flex items-center justify-center text-[#c8aa6e] font-bold text-sm">
                  {step.number}
                </div>
                <div className="flex-1 pt-1">
                  <h3 className="font-semibold text-lg mb-1">{step.title}</h3>
                  <p className="text-white/45 text-sm leading-relaxed mb-3">
                    {step.description}
                  </p>
                  {step.action}
                </div>
              </motion.div>
            ))}
          </div>

          {/* Build from source */}
          <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] p-6 mb-12">
            <div className="flex items-center gap-2 mb-4">
              <Terminal className="w-4 h-4 text-white/50" />
              <span className="text-sm font-medium text-white/60">
                Or build from source
              </span>
            </div>
            <div className="font-mono text-sm space-y-2">
              {[
                "git clone https://github.com/a29paul/hexlens.git",
                "cd hexlens/desktop",
                "swift build -c release",
                "cp -r .build/release/MacLeagueOverlay /Applications/Hexlens",
              ].map((cmd) => (
                <div key={cmd} className="flex items-start gap-2">
                  <span className="text-[#4ade80] select-none">$</span>
                  <span className="text-white/40">{cmd}</span>
                </div>
              ))}
            </div>
            <p className="text-xs text-white/25 mt-3">
              Requires Xcode Command Line Tools.
            </p>
          </div>

          {/* Troubleshooting */}
          <div>
            <h2 className="text-xl font-bold mb-4">Troubleshooting</h2>
            <div className="space-y-4 text-sm">
              <div>
                <h3 className="font-semibold text-white/80 mb-1">
                  &ldquo;Hexlens can&apos;t be opened because it is from an
                  unidentified developer&rdquo;
                </h3>
                <p className="text-white/40">
                  Right-click the app → Open → Open. macOS remembers your
                  choice. Alternatively: System Settings → Privacy & Security →
                  scroll down → click &ldquo;Open Anyway.&rdquo;
                </p>
              </div>
              <div>
                <h3 className="font-semibold text-white/80 mb-1">
                  Overlay doesn&apos;t appear
                </h3>
                <p className="text-white/40">
                  Try switching between fullscreen and borderless windowed in
                  LoL&apos;s Video settings. Restart the game after changing.
                  If still not visible, check that Hexlens is running in the
                  menu bar.
                </p>
              </div>
              <div>
                <h3 className="font-semibold text-white/80 mb-1">
                  Hotkeys don&apos;t work
                </h3>
                <p className="text-white/40">
                  Grant Accessibility permission: System Settings → Privacy &
                  Security → Accessibility → toggle Hexlens on. You may need to
                  restart the app.
                </p>
              </div>
            </div>
          </div>

          {/* Success state */}
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="mt-16 text-center"
          >
            <CheckCircle2 className="w-10 h-10 text-[#4ade80] mx-auto mb-3" />
            <p className="text-white/60">
              That&apos;s it. Hexlens runs in the background and activates when
              you start a game. GLHF.
            </p>
          </motion.div>
        </motion.div>
      </div>
    </main>
  );
}
