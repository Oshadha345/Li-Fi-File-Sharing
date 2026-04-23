"use client";

import { useEffect, useId, useState } from "react";

type MermaidChartProps = {
  chart: string;
  title: string;
};

let mermaidInitialized = false;

export default function MermaidChart({ chart, title }: MermaidChartProps) {
  const [svg, setSvg] = useState("");
  const localId = useId().replace(/[^a-z0-9-]/gi, "");
  const chartId = `mermaid-${title.toLowerCase().replace(/[^a-z0-9]+/g, "-")}-${localId}`;

  useEffect(() => {
    let cancelled = false;

    const renderDiagram = async () => {
      const mermaid = (await import("mermaid")).default;

      if (!mermaidInitialized) {
        mermaid.initialize({
          startOnLoad: false,
          theme: "base",
          themeVariables: {
            primaryColor: "#0f172a",
            primaryTextColor: "#e2e8f0",
            primaryBorderColor: "#38bdf8",
            lineColor: "#bc13fe",
            secondaryColor: "#111827",
            tertiaryColor: "#0b1020",
            background: "#070b14",
            nodeBorder: "#38bdf8",
            clusterBkg: "#0f172a",
            clusterBorder: "#bc13fe",
            edgeLabelBackground: "#070b14",
            fontFamily: "Inter, sans-serif",
          },
          flowchart: {
            curve: "basis",
            htmlLabels: true,
          },
        });
        mermaidInitialized = true;
      }

      try {
        const result = await mermaid.render(chartId, chart);
        if (!cancelled) {
          setSvg(result.svg);
        }
      } catch {
        if (!cancelled) {
          setSvg("");
        }
      }
    };

    renderDiagram();

    return () => {
      cancelled = true;
    };
  }, [chart, chartId]);

  return (
    <article className="rounded-2xl border border-white/10 border-t-white/20 bg-white/5 p-4 backdrop-blur-xl shadow-2xl shadow-black/50">
      <h3 className="mb-3 text-base font-semibold text-cyan-200">{title}</h3>
      <div
        className="mermaid-wrap overflow-x-auto rounded-xl border border-white/10 border-t-white/20 bg-black/20 p-3"
        dangerouslySetInnerHTML={{ __html: svg }}
      />
    </article>
  );
}
