"use client";

import MermaidChart from "./MermaidChart";

const txFlow = `flowchart TD
  A[Keypad Scan] --> B[Software Debounce]
  B --> C[UART Framing]
  C --> D[XOR Encryption\nUSART_TRANSMIT_SECURE]
  D --> E[TX Output / OOK Path]`;

const initFlow = `flowchart TD
  A[I2C Setup\nTWI_INIT] --> B[SSD1306 Boot Sequence\nSSD1306_INIT]
  B --> C[UART RX Enable\nUSART_INIT]
  C --> D[Splash Screen\nSSD1306_PRINT_FLASH_STRING]`;

const displayFlow = `flowchart TD
  A[UART RX Byte] --> B[XOR Decryption]
  B --> C[SRAM Buffer Write\nMSG_BUF]
  C --> D[Font Glyph Lookup\nSSD1306_SEND_CHAR_GLYPH]
  D --> E[I2C Byte Blast to OLED\nTWI_WRITE Loop]`;

export default function FlowchartsPanel() {
  return (
    <section id="flowcharts" className="scroll-mt-24 px-6 py-10 lg:px-10">
      <header className="glass-panel mb-5 p-6">
        <h2 className="text-2xl font-bold text-white">Firmware Control Flow</h2>
        <p className="mt-2 text-zinc-200">
          Mermaid.js flowcharts derived from current transmitter and receiver AVR
          assembly routines.
        </p>
      </header>

      <div className="grid gap-5">
        <MermaidChart title="Transmitter Side" chart={txFlow} />
        <MermaidChart title="System Initialization of Receiver End" chart={initFlow} />
        <MermaidChart title="Display Subroutine" chart={displayFlow} />
      </div>
    </section>
  );
}
