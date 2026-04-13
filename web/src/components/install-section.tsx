"use client";

import { motion } from "framer-motion";
import { Download, Terminal, ArrowRight } from "lucide-react";
import Link from "next/link";

export function InstallSection() {
  return (
    <section className="py-24 px-6">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        className="max-w-2xl mx-auto text-center"
      >
        <h2 className="text-3xl sm:text-4xl font-bold mb-4 tracking-tight">
          Ready to play?
        </h2>
        <p className="text-white/45 mb-10 text-lg">
          Download the app or build from source. Up and running in under a
          minute.
        </p>

        <div className="flex flex-col sm:flex-row gap-4 justify-center mb-8">
          <a
            href="https://github.com/a29paul/hexlens/releases/latest"
            className="inline-flex items-center justify-center gap-2 bg-[#c8aa6e] hover:bg-[#d4ba82] text-[#1a1a2e] font-semibold text-base px-8 h-12 rounded-lg shadow-[0_4px_24px_rgba(200,170,110,0.3)] transition-all hover:-translate-y-0.5"
          >
            <Download className="w-5 h-5" />
            Download for Mac
          </a>

          <Link
            href="/install"
            className="inline-flex items-center justify-center gap-2 border border-white/10 bg-white/[0.04] hover:bg-white/[0.08] text-white font-semibold text-base px-8 h-12 rounded-lg transition-all hover:-translate-y-0.5"
          >
            Install Guide
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Quick build-from-source */}
        <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] p-6 text-left">
          <div className="flex items-center gap-2 mb-4 text-sm text-white/50">
            <Terminal className="w-4 h-4" />
            <span>Or build from source</span>
          </div>
          <div className="font-mono text-sm space-y-1">
            {[
              "git clone https://github.com/a29paul/hexlens.git",
              "cd hexlens/desktop && swift build -c release",
            ].map((cmd) => (
              <div key={cmd} className="text-white/30">
                <span className="text-[#4ade80]">$</span> {cmd}
              </div>
            ))}
          </div>
        </div>
      </motion.div>
    </section>
  );
}
