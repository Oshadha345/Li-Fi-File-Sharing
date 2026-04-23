declare module "react-katex" {
  import type { ComponentType, HTMLAttributes, ReactNode } from "react";

  export type KatexRenderError = (error: Error) => ReactNode;

  export interface KatexProps extends HTMLAttributes<HTMLElement> {
    math: string;
    errorColor?: string;
    renderError?: KatexRenderError;
    settings?: Record<string, unknown>;
  }

  export const InlineMath: ComponentType<KatexProps>;
  export const BlockMath: ComponentType<KatexProps>;
}
