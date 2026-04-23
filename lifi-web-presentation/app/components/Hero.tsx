"use client";

import { motion } from "framer-motion";
import { GitBranch } from "lucide-react";

export default function Hero() {
  return (
    <section className="relative overflow-hidden px-6 pb-16 pt-24 sm:px-10 lg:px-16">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_20%_15%,rgba(34,211,238,0.22),transparent_40%),radial-gradient(circle_at_80%_25%,rgba(168,85,247,0.2),transparent_45%)]" />
      <div className="pointer-events-none absolute inset-0 opacity-35 [background-image:linear-gradient(rgba(34,211,238,0.16)_1px,transparent_1px),linear-gradient(90deg,rgba(168,85,247,0.16)_1px,transparent_1px)] [background-size:44px_44px]" />

      <div className="relative mx-auto max-w-6xl">
        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="mb-3 inline-block rounded-full border border-fuchsia-400/40 px-4 py-1 text-xs tracking-[0.18em] text-fuchsia-200"
        >
          EE322 EMBEDDED SYSTEMS DESIGN
        </motion.p>

        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.05 }}
          className="max-w-5xl text-3xl font-extrabold leading-tight text-zinc-100 sm:text-5xl"
        >
          Optical Wireless Communication: 38kHz Modulated IR Data Link
        </motion.h1>

        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.12 }}
          className="mt-5 max-w-3xl text-lg text-cyan-100/90"
        >
          Bare-Metal Architecture via On-Off Keying &amp; Hardware Encryption.
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.2 }}
          className="mt-4 space-y-1 text-sm tracking-wide text-zinc-300"
        >
          <p>Oshadha: Soldering, Web Design, Github Handling, Flow Control.</p>
          <p>Movindu: Circuit and Hardware Designer.</p>
          <p>Thaariq: Assembly Coder, Main Debugger (Software Side).</p>

          <a
            href="https://github.com/Oshadha345/Li-Fi-File-Sharing"
            target="_blank"
            rel="noopener noreferrer"
            className="glass-pill mt-3 text-cyan-200 hover:border-cyan-300/70 hover:bg-cyan-400/10"
          >
            <GitBranch size={15} className="text-cyan-300" />
            View Source Code
          </a>
        </motion.div>
      </div>
    </section>
  );
}
