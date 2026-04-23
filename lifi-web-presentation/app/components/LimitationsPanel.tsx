export default function LimitationsPanel() {
  const points = [
    {
      title: "Bandwidth Limitations",
      body: "At 115200 baud, bit width is about 8.6 microseconds, too short for enough 38kHz cycles to form a stable envelope at TSOP output. 9600 baud offers practical symbol duration and robust demodulation.",
    },
    {
      title: "Photodiode Saturation",
      body: "Although the receiver rejects ambient frequency noise, direct high-intensity flashlight exposure can saturate the sensor front-end and temporarily blind the silicon.",
    },
    {
      title: "Line of Sight Requirement",
      body: "Infrared transport requires direct optical path. Beam obstruction causes frame corruption, garbage symbols, or dropped reception windows.",
    },
  ];

  return (
    <section id="limitations" className="scroll-mt-24 px-6 py-10 lg:px-10">
      <header className="glass-panel mb-6 p-6">
        <h2 className="text-2xl font-bold text-white">Addressed Problems and Limitations</h2>
        <p className="mt-2 text-zinc-200">
          Critical design constraints and physical-world operating boundaries
          presented for viva defense.
        </p>
      </header>

      <div className="grid gap-4 lg:grid-cols-3">
        {points.map((point) => (
          <article
            key={point.title}
            className="glass-panel p-5"
          >
            <h3 className="text-lg font-semibold text-cyan-200">{point.title}</h3>
            <p className="mt-2 text-sm leading-7 text-zinc-200">{point.body}</p>
          </article>
        ))}
      </div>
    </section>
  );
}
