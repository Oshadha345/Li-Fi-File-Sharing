"use client";

import { motion } from "framer-motion";
import { InlineMath, BlockMath } from "react-katex";
import Image from "next/image";
import { ReactNode } from "react";
import {
  Cpu,
  Keyboard,
  Waves,
  Gauge,
  Plug,
  Zap,
  Lightbulb,
  Radio,
  Monitor,
} from "lucide-react";

type Item = {
  icon: ReactNode;
  title: string;
  text: ReactNode;
};

const txItems: Item[] = [
  {
    icon: <Keyboard size={15} />,
    title: "Keypad",
    text: "4x4 matrix input scanned through GPIO polling with software debouncing.",
  },
  {
    icon: <Cpu size={15} />,
    title: "ATmega328P",
    text: "Converts key events into UART frames at 9600 baud.",
  },
  {
    icon: <Gauge size={15} />,
    title: "16MHz Oscillator",
    text: "External crystal maintains strict timing and avoids internal 8MHz RC thermal drift.",
  },
  {
    icon: <Plug size={15} />,
    title: "Regulator and Decoupling",
    text: "7805 regulates 5V rail; 100nF capacitors across VCC/GND suppress ground bounce.",
  },
  {
    icon: <Zap size={15} />,
    title: "74HC04 NOT Gate",
    text: "Inverts UART to idle LOW, reducing LED idle power and preventing AGC blindness.",
  },
  {
    icon: <Waves size={15} />,
    title: "74HC08 AND Gate",
    text: (
      <div className="space-y-2">
        <p>OOK mix stage for data and carrier:</p>
        <div className="rounded-md border border-cyan-400/30 bg-black/30 p-2 text-center">
          <InlineMath math={"S(t) = m(t) \\cdot c(t)"} />
        </div>
        <div className="overflow-x-auto rounded-md border border-fuchsia-400/30 bg-black/30 p-2">
          <BlockMath math={"f_{carrier} = \\frac{f_{clock}}{2 \\cdot N \\cdot (1 + OCR2A)}"} />
        </div>
      </div>
    ),
  },
  {
    icon: <Lightbulb size={15} />,
    title: "IR LED",
    text: "940nm transducer executing OOK/ASK optical emission.",
  },
];

const rxItems: Item[] = [
  {
    icon: <Radio size={15} />,
    title: "TSOP1838 Receiver",
    text: "Optical filter -> TIA -> AGC -> 38kHz bandpass -> envelope detector.",
  },
  {
    icon: <Cpu size={15} />,
    title: "ATmega328P",
    text: "Receives UART and performs XOR decryption on incoming bytes.",
  },
  {
    icon: <Monitor size={15} />,
    title: "SSD1306 OLED",
    text: "I2C-driven output with 4.7k ohm pull-ups on SDA/SCL for bus stability.",
  },
];

function Timeline({ items }: { items: Item[] }) {
  return (
    <div className="relative space-y-5 before:absolute before:left-3 before:top-2 before:h-[calc(100%-8px)] before:w-px before:bg-gradient-to-b before:from-cyan-400/80 before:to-fuchsia-400/80">
      {items.map((item, idx) => (
        <motion.div
          key={item.title}
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.3 }}
          transition={{ duration: 0.45, delay: idx * 0.06 }}
          className="relative ml-10 rounded-xl border border-white/10 border-t-white/20 bg-white/5 p-4 backdrop-blur-xl shadow-xl shadow-black/40"
        >
          <span className="absolute -left-10 top-4 grid h-6 w-6 place-items-center rounded-full border border-cyan-300/60 bg-cyan-500/20 text-cyan-200">
            {item.icon}
          </span>
          <h4 className="font-semibold text-cyan-200">{item.title}</h4>
          <div className="mt-1 text-sm leading-6 text-zinc-200">{item.text}</div>
        </motion.div>
      ))}
    </div>
  );
}

export default function HardwareRoadmapPanel() {
  return (
    <section id="hardware" className="scroll-mt-24 px-6 py-10 lg:px-10">
      <header className="glass-panel mb-6 p-6">
        <h2 className="text-2xl font-bold text-white">The Hardware Roadmap</h2>
        <p className="mt-2 text-zinc-200">
          End-to-end physical pipeline for transmitter and receiver hardware.
        </p>
      </header>

      <div className="grid gap-6 xl:grid-cols-2">
        <article className="glass-panel p-5">
          <h3 className="mb-4 text-lg font-semibold text-cyan-200">TX Side Pipeline</h3>
          <Timeline items={txItems} />
          <div className="mt-5 overflow-hidden rounded-xl border border-white/10 border-t-white/20">
            <Image
              src="/media/images/Transmitter simulation.png"
              alt="Transmitter simulation"
              width={1200}
              height={700}
              unoptimized
              className="h-56 w-full object-cover"
            />
          </div>
        </article>

        <article className="glass-panel p-5">
          <h3 className="mb-4 text-lg font-semibold text-fuchsia-200">RX Side Pipeline</h3>
          <Timeline items={rxItems} />
          <div className="mt-5 overflow-hidden rounded-xl border border-white/10 border-t-white/20">
            <Image
              src="/media/images/Receiver simulation.png"
              alt="Receiver simulation"
              width={1200}
              height={700}
              unoptimized
              className="h-56 w-full object-cover"
            />
          </div>
        </article>
      </div>
    </section>
  );
}
