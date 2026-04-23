"use client";

import { ReactNode, useEffect, useMemo, useState } from "react";
import { motion } from "framer-motion";
import {
  LayoutDashboard,
  GitBranch,
  CircuitBoard,
  Shield,
  TriangleAlert,
} from "lucide-react";
import ParticlesBackdrop from "./ParticlesBackdrop";
import OverviewPanel from "./OverviewPanel";
import FlowchartsPanel from "./FlowchartsPanel";
import HardwareRoadmapPanel from "./HardwareRoadmapPanel";
import EncryptionPanel from "./EncryptionPanel";
import LimitationsPanel from "./LimitationsPanel";

type NavItem = {
  id: string;
  label: string;
  icon: ReactNode;
};

const navItems: NavItem[] = [
  { id: "overview", label: "Overview and Demos", icon: <LayoutDashboard size={16} /> },
  { id: "flowcharts", label: "Firmware Flowcharts", icon: <GitBranch size={16} /> },
  { id: "hardware", label: "Hardware Roadmap", icon: <CircuitBoard size={16} /> },
  { id: "encryption", label: "Encryption Layer", icon: <Shield size={16} /> },
  { id: "limitations", label: "Problems and Limits", icon: <TriangleAlert size={16} /> },
];

export default function PresentationShell() {
  const [activeSection, setActiveSection] = useState("overview");
  const sectionIds = useMemo(() => navItems.map((item) => item.id), []);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);

        if (visible[0]?.target?.id) {
          setActiveSection(visible[0].target.id);
        }
      },
      { threshold: [0.3, 0.45, 0.6], rootMargin: "-20% 0px -35% 0px" }
    );

    sectionIds.forEach((id) => {
      const node = document.getElementById(id);
      if (node) observer.observe(node);
    });

    return () => observer.disconnect();
  }, [sectionIds]);

  const jumpTo = (id: string) => {
    const section = document.getElementById(id);
    if (!section) return;
    section.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <div className="relative min-h-screen bg-[#050810] text-zinc-100">
      <ParticlesBackdrop />
      <div className="pointer-events-none fixed inset-0 bg-[#050810]" />
      <div className="pointer-events-none fixed -left-24 top-20 h-72 w-72 rounded-full bg-[#00f3ff]/25 blur-[100px]" />
      <div className="pointer-events-none fixed right-10 top-36 h-80 w-80 rounded-full bg-[#bc13fe]/25 blur-[110px]" />
      <div className="pointer-events-none fixed bottom-6 left-1/3 h-72 w-72 rounded-full bg-[#00f3ff]/20 blur-[100px]" />

      <div className="relative mx-auto flex max-w-[1800px]">
        <aside className="sticky top-0 hidden h-screen w-[320px] shrink-0 border-r border-white/10 bg-black/20 p-6 backdrop-blur-2xl xl:block">
          <div className="glass-panel p-4">
            <h2 className="text-xl font-bold text-white">LiFi Engineering Viva</h2>
            <p className="mt-2 text-xs leading-6 text-cyan-200">EE322 Embedded Systems Design</p>
            <p className="mt-3 text-xs leading-6 text-zinc-300">
              Oshadha: Soldering, Web Design, Github Handling, Flow Control.
              <br />
              Movindu: Circuit and Hardware Designer.
              <br />
              Thaariq: Assembly Coder, Main Debugger (Software Side).
            </p>

            <a
              href="https://github.com/Oshadha345/Li-Fi-File-Sharing"
              target="_blank"
              rel="noopener noreferrer"
              className="glass-pill mt-4 text-cyan-200 hover:border-cyan-300/70 hover:bg-cyan-400/10"
            >
              <GitBranch size={15} className="text-cyan-300" />
              View Source Code
            </a>
          </div>

          <nav className="mt-6 space-y-2">
            {navItems.map((item) => {
              const isActive = activeSection === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => jumpTo(item.id)}
                  className={`flex w-full items-center gap-3 rounded-xl border px-4 py-3 text-left text-sm backdrop-blur-xl transition ${
                    isActive
                      ? "border-cyan-300/70 bg-white/10 text-cyan-100"
                      : "border-white/10 bg-white/5 text-zinc-300 hover:border-[#bc13fe]/50 hover:bg-white/10"
                  }`}
                >
                  <span className={isActive ? "text-cyan-200" : "text-fuchsia-300"}>{item.icon}</span>
                  {item.label}
                </button>
              );
            })}
          </nav>
        </aside>

        <main className="w-full pb-16 xl:pl-2">
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.5 }}>
            <OverviewPanel />
            <FlowchartsPanel />
            <HardwareRoadmapPanel />
            <EncryptionPanel />
            <LimitationsPanel />

            <footer className="px-6 pb-8 lg:px-10">
              <div className="glass-panel p-5 text-sm text-zinc-300">
                <p className="text-white">EE322 Embedded Systems Design</p>
                <p className="mt-2">
                  Oshadha: Soldering, Web Design, Github Handling, Flow Control.
                </p>
                <p>Movindu: Circuit and Hardware Designer.</p>
                <p>Thaariq: Assembly Coder, Main Debugger (Software Side).</p>
                <a
                  href="https://github.com/Oshadha345/Li-Fi-File-Sharing"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="glass-pill mt-4 text-fuchsia-200 hover:border-fuchsia-300/70 hover:bg-fuchsia-500/10"
                >
                  <GitBranch size={15} className="text-fuchsia-300" />
                  View Source Code
                </a>
              </div>
            </footer>
          </motion.div>
        </main>
      </div>
    </div>
  );
}
