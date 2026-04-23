declare module "react-syntax-highlighter" {
  import type { ComponentType, CSSProperties, ReactNode } from "react";

  export interface SyntaxHighlighterProps {
    language?: string;
    style?: Record<string, CSSProperties>;
    children?: ReactNode;
    customStyle?: CSSProperties;
    codeTagProps?: Record<string, unknown>;
    showLineNumbers?: boolean;
    wrapLongLines?: boolean;
    useInlineStyles?: boolean;
    lineNumberStyle?: CSSProperties | ((lineNumber: number) => CSSProperties);
    lineProps?: Record<string, unknown> | ((lineNumber: number) => Record<string, unknown>);
  }

  export const Prism: ComponentType<SyntaxHighlighterProps>;
  export const Light: ComponentType<SyntaxHighlighterProps>;
  export const PrismLight: ComponentType<SyntaxHighlighterProps>;
  export default Prism;
}

declare module "react-syntax-highlighter/dist/esm/styles/prism" {
  import type { CSSProperties } from "react";

  export const atomDark: Record<string, CSSProperties>;
}
