"use client";

import { motion } from "framer-motion";
import { ReactNode } from "react";

type RoadmapItemProps = {
  index: number;
  title: string;
  description: ReactNode;
  icon: ReactNode;
};

export default function RoadmapItem({
  index,
  title,
  description,
  icon,
}: RoadmapItemProps) {
  return (
    <motion.article
      initial={{ opacity: 0, y: 36 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.35 }}
      transition={{ duration: 0.55, delay: index * 0.06 }}
      className="group relative ml-8 rounded-2xl border border-cyan-400/30 bg-zinc-950/70 p-5 shadow-[0_0_20px_rgba(34,211,238,0.16)] backdrop-blur"
    >
      <div className="absolute -left-11 top-6 grid h-6 w-6 place-items-center rounded-full border border-cyan-300/60 bg-cyan-400/20 text-cyan-200 shadow-[0_0_16px_rgba(6,182,212,0.7)]">
        {icon}
      </div>
      <h3 className="text-lg font-semibold tracking-wide text-cyan-200">{title}</h3>
      <div className="mt-2 text-sm leading-7 text-zinc-200/90">{description}</div>
    </motion.article>
  );
}
