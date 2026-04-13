"use client";

import { motion } from "framer-motion";
import { Badge } from "@/components/ui/badge";
import { Download, Apple } from "lucide-react";

function GithubIcon({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
    </svg>
  );
}

export function Hero() {
  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center text-center px-6 overflow-hidden">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-[800px] h-[600px] rounded-full bg-[#c8aa6e]/[0.04] blur-[120px]" />
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[600px] h-[400px] rounded-full bg-[#4ade80]/[0.02] blur-[100px]" />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative z-10"
      >
        <Badge
          variant="outline"
          className="mb-8 border-[#c8aa6e]/20 bg-[#c8aa6e]/[0.06] text-[#c8aa6e] px-4 py-1.5 text-sm font-medium"
        >
          <span className="w-1.5 h-1.5 rounded-full bg-[#4ade80] mr-2 inline-block" />
          Free &amp; Open Source
        </Badge>

        <h1 className="text-5xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight leading-[1.08] mb-6">
          The LoL overlay
          <br />
          <span className="bg-gradient-to-r from-[#c8aa6e] to-[#e8d5a3] bg-clip-text text-transparent">
            Mac deserved.
          </span>
        </h1>

        <p className="text-lg sm:text-xl text-white/50 max-w-xl mx-auto mb-10 leading-relaxed">
          CS tracker, jungle timers, spell tracking, rune import. Native Swift.
          Zero Overwolf. The first League overlay built for macOS.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <a
            href="https://github.com/a29paul/hexlens/releases/latest"
            className="inline-flex items-center justify-center gap-2 bg-[#c8aa6e] hover:bg-[#d4ba82] text-[#1a1a2e] font-semibold text-base px-8 h-12 rounded-lg shadow-[0_4px_24px_rgba(200,170,110,0.3)] hover:shadow-[0_8px_32px_rgba(200,170,110,0.4)] transition-all hover:-translate-y-0.5"
          >
            <Download className="w-5 h-5" />
            Download for Mac
          </a>

          <a
            href="https://github.com/a29paul/hexlens"
            className="inline-flex items-center justify-center gap-2 border border-white/10 bg-white/[0.04] hover:bg-white/[0.08] text-white font-semibold text-base px-8 h-12 rounded-lg transition-all hover:-translate-y-0.5"
          >
            <GithubIcon className="w-5 h-5" />
            View on GitHub
          </a>
        </div>

        <p className="mt-5 text-sm text-white/30 flex items-center justify-center gap-1.5">
          <Apple className="w-3.5 h-3.5" />
          macOS 14+ required
        </p>
      </motion.div>
    </section>
  );
}
