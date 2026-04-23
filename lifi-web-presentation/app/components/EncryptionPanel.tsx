"use client";

import { InlineMath } from "react-katex";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { atomDark } from "react-syntax-highlighter/dist/esm/styles/prism";

const txSnippet = `USART_TRANSMIT_SECURE:
    push  r17
    ldi   r17, SECRET_KEY
    eor   r16, r17
    rcall USART_TRANSMIT
    eor   r16, r17
    pop   r17
    ret`;

const rxSnippet = `MAIN_LOOP:
    lds   r16, UCSR0A
    sbrs  r16, RXC0
    rjmp  MAIN_LOOP

    lds   r16, UDR0
    push  r17
    ldi   r17, SECRET_KEY
    eor   r16, r17
    pop   r17`;

export default function EncryptionPanel() {
  return (
    <section id="encryption" className="scroll-mt-24 px-6 py-10 lg:px-10">
      <header className="glass-panel p-6">
        <h2 className="text-2xl font-bold text-white">Hardware Encryption Layer</h2>
        <p className="mt-2 text-zinc-200">
          8-bit AVR targets cannot comfortably host AES with tight RAM budgets.
          XOR-based symmetric masking executes in one clock cycle via
          <code className="ml-1 text-cyan-200">eor</code> with negligible memory overhead.
        </p>
        <div className="mt-4 inline-flex rounded-lg border border-white/10 border-t-white/20 bg-black/20 px-4 py-2 text-zinc-100 backdrop-blur-xl shadow-xl shadow-black/40">
          <InlineMath math={"Ciphertext = Plaintext \\oplus Key"} />
        </div>
      </header>

      <div className="mt-6 grid gap-5 xl:grid-cols-2">
        <article className="overflow-hidden rounded-2xl border border-white/10 border-t-white/20 bg-white/5 backdrop-blur-xl shadow-2xl shadow-black/50">
          <h3 className="border-b border-white/10 px-4 py-3 font-semibold text-cyan-200">
            TX USART_TRANSMIT_SECURE
          </h3>
          <SyntaxHighlighter language="avrasm" style={atomDark} customStyle={{ margin: 0 }}>
            {txSnippet}
          </SyntaxHighlighter>
        </article>

        <article className="overflow-hidden rounded-2xl border border-white/10 border-t-white/20 bg-white/5 backdrop-blur-xl shadow-2xl shadow-black/50">
          <h3 className="border-b border-white/10 px-4 py-3 font-semibold text-fuchsia-200">
            RX Decryption Logic
          </h3>
          <SyntaxHighlighter language="avrasm" style={atomDark} customStyle={{ margin: 0 }}>
            {rxSnippet}
          </SyntaxHighlighter>
        </article>
      </div>
    </section>
  );
}
