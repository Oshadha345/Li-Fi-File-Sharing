"use client";

import { useEffect, useState } from "react";
import Particles, { initParticlesEngine } from "@tsparticles/react";
import { loadSlim } from "@tsparticles/slim";

export default function ParticlesBackdrop() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    initParticlesEngine(async (engine) => {
      await loadSlim(engine);
    }).then(() => {
      setReady(true);
    });
  }, []);

  if (!ready) {
    return null;
  }

  return (
    <Particles
      id="lifi-particles"
      options={{
        fullScreen: { enable: false },
        background: { color: { value: "transparent" } },
        fpsLimit: 60,
        particles: {
          number: {
            value: 48,
            density: { enable: true, width: 1000, height: 1000 },
          },
          color: { value: ["#38bdf8", "#bc13fe"] },
          links: {
            enable: true,
            color: "#38bdf8",
            opacity: 0.3,
            distance: 140,
            width: 1,
          },
          move: {
            enable: true,
            speed: 0.8,
            outModes: { default: "bounce" },
          },
          opacity: { value: 0.35 },
          size: { value: { min: 1, max: 3 } },
        },
        detectRetina: true,
      }}
      className="pointer-events-none absolute inset-0"
    />
  );
}
