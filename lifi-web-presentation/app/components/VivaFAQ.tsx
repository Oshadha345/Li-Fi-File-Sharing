"use client";

import { motion } from "framer-motion";
import { ChevronDown } from "lucide-react";
import { useState } from "react";

const faqs = [
  {
    title: "Bandwidth Limit: Why 9600 and not 115200 Baud?",
    answer:
      "At 115200 baud, one bit is about 8.6 microseconds, which is too short for the 38kHz carrier to present enough cycles for the TSOP envelope detector to form a reliable pulse. At 9600 baud, symbol duration is longer, enabling robust envelope reconstruction and lower BER.",
  },
  {
    title: "Photodiode Saturation under Direct Light",
    answer:
      "Frequency filtering removes most ambient-noise components, but extreme direct illumination from a bright flashlight can saturate the silicon front-end. In saturation, the detector loses dynamic range and appears temporarily blind to valid modulated bursts.",
  },
  {
    title: "Full Duplex Challenges and Crosstalk",
    answer:
      "Bidirectional optical links risk transmitter self-blinding and optical crosstalk. Production-grade duplexing requires multiplexing isolation, such as WDM with distinct bands (for example 850nm and 940nm filtering) or TDM slots with strict synchronization.",
  },
];

export default function VivaFAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  return (
    <section className="mx-auto max-w-6xl px-6 py-14 sm:px-10 lg:px-16">
      <h2 className="text-2xl font-bold text-fuchsia-200 sm:text-3xl">
        Viva Defense: Critical Engineering Constraints
      </h2>
      <p className="mt-3 max-w-4xl text-zinc-300">
        Anticipated panel questions and physics-grounded answers around
        bandwidth, optical limits, and scalable duplex architecture.
      </p>

      <div className="mt-8 space-y-4">
        {faqs.map((item, idx) => {
          const isOpen = openIndex === idx;

          return (
            <div
              key={item.title}
              className="rounded-2xl border border-cyan-400/25 bg-zinc-950/70"
            >
              <button
                type="button"
                className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
                onClick={() => setOpenIndex(isOpen ? null : idx)}
              >
                <span className="font-semibold text-cyan-100">{item.title}</span>
                <ChevronDown
                  className={`h-5 w-5 shrink-0 text-cyan-300 transition-transform ${
                    isOpen ? "rotate-180" : ""
                  }`}
                />
              </button>

              <motion.div
                initial={false}
                animate={{ height: isOpen ? "auto" : 0, opacity: isOpen ? 1 : 0 }}
                transition={{ duration: 0.28 }}
                className="overflow-hidden"
              >
                <p className="px-5 pb-5 text-sm leading-7 text-zinc-200/90">
                  {item.answer}
                </p>
              </motion.div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
