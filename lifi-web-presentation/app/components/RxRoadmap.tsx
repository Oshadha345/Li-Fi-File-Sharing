"use client";

import { Cpu, Radar, Monitor, Cable } from "lucide-react";
import Image from "next/image";
import RoadmapItem from "./RoadmapItem";

const rxSteps = [
  {
    title: "TSOP1838 Demodulation Front-End",
    icon: <Radar size={14} />,
    description: (
      <div className="space-y-3">
        <p>
          The TSOP1838 performs an internal hardware pipeline:
          optical daylight filter -&gt; transimpedance amplifier -&gt; AGC -&gt;
          active 38kHz bandpass filter -&gt; envelope detector.
        </p>
        <p>
          It rejects 0Hz sunlight and 50Hz/100Hz AC lighting components while
          outputting clean baseband UART-compatible digital transitions.
        </p>
      </div>
    ),
  },
  {
    title: "ATmega328P Receive and Processing",
    icon: <Cpu size={14} />,
    description: (
      <p>
        Baseband is read on the RX pin, decoded as UART, and routed through
        firmware handling for message buffering and post-processing.
      </p>
    ),
  },
  {
    title: "SSD1306 OLED Interface over I2C",
    icon: <Monitor size={14} />,
    description: (
      <p>
        The 0.91-inch SSD1306 display is driven via SDA/SCL with mandatory
        4.7k ohm pull-up resistors for bus integrity, edge stability, and robust
        clock/data arbitration.
      </p>
    ),
  },
  {
    title: "Physical Wiring Discipline",
    icon: <Cable size={14} />,
    description: (
      <p>
        Short return paths, local decoupling, and clean grounding reduce false
        triggering and preserve demodulator sensitivity in noisy lab
        environments.
      </p>
    ),
  },
];

export default function RxRoadmap() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-12 sm:px-10 lg:px-16">
      <h2 className="text-2xl font-bold text-fuchsia-200 sm:text-3xl">
        RX Side Roadmap (Receiver Pipeline)
      </h2>
      <p className="mt-3 max-w-4xl text-zinc-300">
        Optical burst recovery, baseband restoration, and human-readable display
        output.
      </p>

      <div className="relative mt-8 space-y-6 before:absolute before:left-0 before:top-2 before:h-[calc(100%-16px)] before:w-[2px] before:bg-gradient-to-b before:from-fuchsia-300 before:via-cyan-400 before:to-fuchsia-300 before:shadow-[0_0_14px_rgba(168,85,247,0.9)]">
        {rxSteps.map((step, idx) => (
          <RoadmapItem
            key={step.title}
            index={idx}
            title={step.title}
            description={step.description}
            icon={step.icon}
          />
        ))}
      </div>

      <div className="mt-10 overflow-hidden rounded-2xl border border-fuchsia-400/30 bg-zinc-950/70">
        <Image
          src="/media/images/rx-schematic.png"
          alt="Receiver schematic placeholder"
          width={1200}
          height={560}
          className="h-64 w-full object-cover"
        />
      </div>
    </section>
  );
}
