import { ShieldCheck, Radio, Cpu, GitBranch } from "lucide-react";

export default function OverviewPanel() {
  return (
    <section id="overview" className="scroll-mt-24 px-6 py-10 lg:px-10">
      <div className="glass-panel p-6">
        <h1 className="text-3xl font-bold text-white sm:text-4xl">
          Optical Wireless Communication: 38kHz Modulated IR Data Link
        </h1>
        <p className="mt-3 max-w-4xl text-zinc-200">
          Bare-Metal Assembly implementation of robust free-space optical data
          transfer using hardware On-Off Keying modulation and lightweight XOR
          hardware-level encryption.
        </p>

        <p className="mt-2 text-sm text-cyan-200">EE322 Embedded Systems Design</p>

        <div className="mt-4 rounded-xl border border-white/10 border-t-white/20 bg-black/20 p-4 text-sm leading-7 text-zinc-200 backdrop-blur-xl shadow-xl shadow-black/40">
          <p>Oshadha: Soldering, Web Design, Github Handling, Flow Control.</p>
          <p>Movindu: Circuit and Hardware Designer.</p>
          <p>Thaariq: Assembly Coder, Main Debugger (Software Side).</p>
        </div>

        <a
          href="https://github.com/Oshadha345/Li-Fi-File-Sharing"
          target="_blank"
          rel="noopener noreferrer"
          className="glass-pill mt-4 text-cyan-200 hover:border-cyan-300/70 hover:bg-cyan-400/10"
        >
          <GitBranch size={15} className="text-cyan-300" />
          View Source Code
        </a>

        <div className="mt-5 grid gap-3 sm:grid-cols-3">
          <div className="glass-card flex items-center gap-2 p-3 text-sm text-zinc-200">
            <Cpu size={16} className="text-cyan-300" /> Bare-Metal AVR Control
          </div>
          <div className="glass-card flex items-center gap-2 p-3 text-sm text-zinc-200">
            <Radio size={16} className="text-fuchsia-300" /> OOK over 38kHz IR Carrier
          </div>
          <div className="glass-card flex items-center gap-2 p-3 text-sm text-zinc-200">
            <ShieldCheck size={16} className="text-cyan-300" /> XOR Hardware Encryption
          </div>
        </div>
      </div>

      <div className="glass-panel mt-6 p-4">
        <h2 className="mb-3 text-xl font-semibold text-fuchsia-200">Main Demo</h2>
        <video
          className="w-full rounded-xl border border-white/10 border-t-white/20 bg-black/40"
          src="/media/video/Both in one frame.mp4"
          controls
          preload="metadata"
        />
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <article className="glass-panel p-4">
          <h3 className="mb-3 font-semibold text-cyan-200">TX Side Video</h3>
          <video
            className="w-full rounded-xl border border-white/10 border-t-white/20 bg-black/40"
            src="/media/video/TX Side video.mp4"
            controls
            preload="metadata"
          />
        </article>

        <article className="glass-panel p-4">
          <h3 className="mb-3 font-semibold text-fuchsia-200">RX Side Video</h3>
          <video
            className="w-full rounded-xl border border-white/10 border-t-white/20 bg-black/40"
            src="/media/video/RX Side video.mp4"
            controls
            preload="metadata"
          />
        </article>
      </div>

      <p className="mt-3 text-sm text-zinc-400">
        Side-by-side playback demonstrates simultaneous transmission and
        reception performance over room-scale distance.
      </p>
    </section>
  );
}
