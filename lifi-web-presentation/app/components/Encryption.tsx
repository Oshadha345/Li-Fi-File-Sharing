"use client";

import { InlineMath } from "react-katex";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { atomDark } from "react-syntax-highlighter/dist/esm/styles/prism";

const txSecureSnippet = `; --- NEW: Encryption Subroutine ---
USART_TRANSMIT_SECURE:
    push  r17
    ldi   r17, SECRET_KEY           ; Load the secret key
    eor   r16, r17                  ; Encrypt the character in r16
    rcall USART_TRANSMIT            ; Send the garbled byte over IR
    eor   r16, r17                  ; Restore r16 to original
    pop   r17
    ret`;

const rxDecryptSnippet = `MAIN_LOOP:
    lds   r16, UCSR0A
    sbrs  r16, RXC0                 ; Wait for data from TSOP pipeline
    rjmp  MAIN_LOOP

    lds   r16, UDR0                 ; Read encrypted byte

    ; --- DECRYPTION STAGE ---
    push  r17
    ldi   r17, SECRET_KEY
    eor   r16, r17                  ; Plaintext recovery
    pop   r17`;

export default function Encryption() {
  return (
    <section className="mx-auto max-w-6xl px-6 py-12 sm:px-10 lg:px-16">
      <h2 className="text-2xl font-bold text-cyan-200 sm:text-3xl">
        Hardware Encryption Layer
      </h2>
      <p className="mt-3 max-w-4xl text-zinc-300">
        The link adopts a symmetric XOR stream mask to harden line-of-sight
        interception. On 8-bit AVR hardware, AES is computationally expensive,
        while <code className="text-cyan-200">eor</code> completes in one clock
        cycle with effectively zero SRAM overhead.
      </p>

      <div className="mt-5 inline-flex rounded-xl border border-fuchsia-400/30 bg-zinc-950/80 px-4 py-3 text-zinc-100 shadow-[0_0_20px_rgba(168,85,247,0.25)]">
        <InlineMath math={"Ciphertext = Plaintext \\oplus Key"} />
      </div>

      <div className="mt-8 grid gap-5 lg:grid-cols-2">
        <article className="overflow-hidden rounded-2xl border border-cyan-400/35 bg-zinc-950/80">
          <h3 className="border-b border-cyan-400/20 bg-cyan-400/8 px-4 py-3 text-sm font-semibold text-cyan-200">
            Transmitter: USART_TRANSMIT_SECURE
          </h3>
          <SyntaxHighlighter
            language="avrasm"
            style={atomDark}
            customStyle={{ margin: 0, background: "#0a0a0a", fontSize: "0.86rem" }}
            showLineNumbers
            wrapLongLines
          >
            {txSecureSnippet}
          </SyntaxHighlighter>
        </article>

        <article className="overflow-hidden rounded-2xl border border-fuchsia-400/35 bg-zinc-950/80">
          <h3 className="border-b border-fuchsia-400/20 bg-fuchsia-400/8 px-4 py-3 text-sm font-semibold text-fuchsia-200">
            Receiver: MAIN_LOOP Decryption Stage
          </h3>
          <SyntaxHighlighter
            language="avrasm"
            style={atomDark}
            customStyle={{ margin: 0, background: "#0a0a0a", fontSize: "0.86rem" }}
            showLineNumbers
            wrapLongLines
          >
            {rxDecryptSnippet}
          </SyntaxHighlighter>
        </article>
      </div>
    </section>
  );
}
