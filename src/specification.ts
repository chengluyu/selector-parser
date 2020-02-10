export enum SelectorKind {
  Complex,
  Compound,
  Simple,
  Type,
  ID,
  Class,
  Attribute,
  PseudoClass,
  PseudoElement,
}

export enum CombinatorKind {
  Descendant,
  Child,
  NextSibling,
  SubsequentSibling,
  Column,
}

export interface ComplexSelector {
  readonly kind: SelectorKind.Complex;
  readonly head: CompoundSelector;
  readonly tail: [CombinatorKind, CompoundSelector];
}

export interface CompoundSelector {
  readonly kind: SelectorKind.Compound;
  readonly type: TypeSelector;
  readonly subClasses: IDSelector | ClassSelector | AttributeSelector | PseudoClassSelector;
  readonly pseudoes: PseudoClassSelector | PseudoElementSelector;
}

export interface TypeSelector {
  readonly kind: SelectorKind.Type;
  readonly value: string;
}

// eslint-disable-next-line @typescript-eslint/interface-name-prefix
export interface IDSelector {
  readonly kind: SelectorKind.ID;
  readonly value: string;
}

export interface ClassSelector {
  readonly kind: SelectorKind.Class;
  readonly value: string;
}

export type AttributeMatcher = '~=' | '|=' | '^=' | '$=' | '*=';

export type AttributeValue = { string: boolean; value: string };

export type AttributeModifier = 'i' | 's';

export interface AttributeSelector {
  readonly kind: SelectorKind.Attribute;
  readonly name: string;
  readonly match?: {
    readonly matcher: AttributeMatcher;
    readonly value: AttributeValue;
    readonly modifier?: AttributeModifier;
  };
}

export type AnyValue = string | AnyValue[];

export interface PseudoClassSelector {
  readonly kind: SelectorKind.PseudoClass;
  readonly name: string;
  readonly parameter?: AnyValue;
}

export interface PseudoElementSelector {
  readonly kind: SelectorKind.PseudoClass;
  readonly name: string;
  readonly parameter?: AnyValue;
}
