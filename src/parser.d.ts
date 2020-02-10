import { ComplexSelector } from './specification';

/**
 * Indicates the position in source code.
 */
export interface Position {
  readonly offset: number;
  readonly line: number;
  readonly column: number;
}

/**
 * Indicates a span (start and and) in source code.
 */
export interface Location {
  readonly start: Position;
  readonly end: Position;
}

/**
 * A customized syntax error class.
 */
export declare class SyntaxError {
  public message: string;
  public expected: [
    {
      type: string;
      description: string;
      parts: string[];
      inverted: boolean;
      ignoreCase: boolean;
    },
  ];
  public found: string;
  public location: Location;
  public name: string;
}

/**
 * Parsing function generated by PEG.js.
 * @param input the source to parse
 * @param options PEG.js parsing options
 */
export declare function parse(
  input: string,
  options?: { startRule: 'start' | 'start_text' },
): ComplexSelector[];