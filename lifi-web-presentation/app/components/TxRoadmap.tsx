"use client";

import { BlockMath, InlineMath } from "react-katex";
import Image from "next/image";
import {
  Binary,
  Cpu,
  Gauge,
  RadioTower,
  Waves,
  Zap,
  Power,
  Lightbulb,
} from "lucide-react";
import RoadmapItem from "./RoadmapItem";

const txSteps = [
  {
    title: "Keypad Source Stage",
    icon: <Binary size={14} />,
    description: (
      <p>
        A 4x4 matrix keypad is scanned through GPIO polling with deterministic
        software debouncing to suppress chatter and false edges before UART
        serialization.
      </p>
    ),
  },
  {
    title: "ATmega328P Framing Core",
    icon: <Cpu size={14} />,
    description: (
      <p>
        Keystrokes are encoded into ASCII and packetized as UART frames at 9600
        baud, transmitted from Pin 3 (TX) with start-bit and stop-bit timing.
      </p>
    ),
  },
  {
    title: "16MHz Oscillator Discipline",
    icon: <Gauge size={14} />,
    description: (
      <p>
        The external 16MHz crystal enforces timing stability. An internal 8MHz
        RC oscillator can drift with temperature, degrading 38kHz carrier
        precision and receiver lock quality.
      </p>
    ),
  },
  {
    title: "74HC04 NOT Gate (Double Inversion Trick)",
    icon: <Zap size={14} />,
    description: (
      <p>
        UART is inverted so idle becomes LOW (0V). This avoids continuous IR LED
        current at idle, protects emitter longevity, and prevents TSOP AGC
        blindness from a permanently illuminated channel.
      </p>
    ),
  },
  {
    title: "74HC08 AND Gate: OOK Modulation",
    icon: <Waves size={14} />,
    description: (
      <div className="space-y-3">
        <p>
          The gate multiplies inverted data and the timer carrier to generate
          hardware OOK/ASK bursts:
        </p>
        <div className="rounded-lg border border-fuchsia-400/30 bg-zinc-900/90 p-3 text-center">
          <InlineMath math={"S(t) = m(t) \\cdot c(t)"} />
        </div>
      </div>
    ),
  },
  {
    title: "Timer2 CTC Carrier Synthesis",
    icon: <RadioTower size={14} />,
    description: (
      <div className="space-y-3">
        <p>Carrier generation is fully hardware-driven in CTC mode:</p>
        <div className="overflow-x-auto rounded-lg border border-cyan-400/30 bg-zinc-900/90 p-3">
          <BlockMath math={"f_{carrier} = \\frac{f_{clock}}{2 \\cdot N \\cdot (1 + OCR2A)}"} />
        </div>
        <p>
          With <strong>OCR2A = 209</strong> and prescaler <strong>N = 1</strong>,
          the system produces <strong>38.095kHz</strong> with zero CPU overhead.
        </p>
      </div>
    ),
  },
  {
    title: "Power Integrity and Decoupling",
    icon: <Power size={14} />,
    description: (
      <p>
        A 7805 regulator provides the 5V rail. 100nF ceramic decoupling
        capacitors are placed directly across VCC/GND of logic ICs to suppress
        high-frequency ground bounce and switching transients.
      </p>
    ),
  },
  {
    title: "IR LED Optical Transducer",
    icon: <Lightbulb size={14} />,
    description: (
      <p>
        A 940nm IR LED emits amplitude-shift keyed optical pulses where carrier
        bursts represent logic-high intervals and optical silence encodes
        logic-low intervals.
      </p>
    ),
  },
];

export default function TxRoadmap() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-12 sm:px-10 lg:px-16">
      <h2 className="text-2xl font-bold text-cyan-200 sm:text-3xl">
        TX Side Roadmap (Transmitter Pipeline)
      </h2>
      <p className="mt-3 max-w-4xl text-zinc-300">
        Signal construction from human input to modulated optical emission.
      </p>

      <div className="relative mt-8 space-y-6 before:absolute before:left-0 before:top-2 before:h-[calc(100%-16px)] before:w-[2px] before:bg-gradient-to-b before:from-cyan-300 before:via-fuchsia-400 before:to-cyan-300 before:shadow-[0_0_14px_rgba(34,211,238,0.8)]">
        {txSteps.map((step, idx) => (
          <RoadmapItem
            key={step.title}
            index={idx}
            title={step.title}
            description={step.description}
            icon={step.icon}
          />
        ))}
      </div>

      <div className="mt-10 overflow-hidden rounded-2xl border border-cyan-400/30 bg-zinc-950/70">
        <Image
          src="/media/images/tx-schematic.png"
          alt="Transmitter schematic placeholder"
          width={1200}
          height={560}
          className="h-64 w-full object-cover"
        />
      </div>
    </section>
  );
}
