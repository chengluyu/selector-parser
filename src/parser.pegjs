{
  const { SelectorKind, CombinatorKind } = require("./specification");

  function resetKind(obj, kind) {
    obj.kind = kind;
    return obj;
  }
}

// Selectors Grammar
// =================

// Adapted from https://drafts.csswg.org/selectors/#grammar

// In interpreting the above grammar, the following rules apply:
// * White space is forbidden:
//   * Between any of the top-level components of a <compound-selector>
//     (that is, forbidden between the <type-selector> and <subclass-selector>,
//     or between the <subclass-selector> and <pseudo-element-selector>, etc).
//   * Between any of the components of a <type-selector> or a <class-selector>.
//   * Between the ':'s, or between the ':' and <ident-token> or
//     <function-token>, of a <pseudo-element-selector> or a
//     <pseudo-class-selector>.
//   * Between any of the components of a <wq-name>.
//   * Between the components of an <attr-matcher>.
//   * Between the components of a <combinator>.
// * The four Level 2 pseudo-elements (::before, ::after, ::first-line, and
//   ::first-letter) may, for legacy reasons, be represented using the
//   <pseudo-class-selector> grammar, with only a single ":" character at their
//   start.
// * In <id-selector>, the <hash-token>’s value must be an identifier.

selector_list = complex_selector_list

complex_selector_list
  = head:complex_selector tail:(ws_star "," ws_star item:complex_selector { return item; })*
    { return [head].concat(tail); }

compound_selector_list
  = head:compound_selector tail:("," item:compound_selector)*
    { return [head].concat(tail); }

simple_selector_list
  = head:simple_selector tail:("," item:simple_selector)*
    { return [head].concat(tail); }

// Unused rule. I don't know why.
relative_selector_list
  = head:relative_selector tail:("," item:relative_selector)*
    { return [head].concat(tail); }

complex_selector
  = head:compound_selector tail:(combinator? compound_selector)*
    { return { kind: SelectorKind.Complex, head, tail }; }

relative_selector
  = combinator:combinator? selector:complex_selector
    { return { kind: SelectorKind.Relative, combinator, selector }; }

compound_selector
  // Case 1: `type_selector` is required.
  = type:type_selector
    subclasses:subclass_selector*
    pseudoes:(pseudo_element_selector pseudo_class_selector*)*
    { return { kind: SelectorKind.Compound, type, subclasses, pseudoes }; }
  // Case 2: `subclass_selector` is required.
  / subclasses:subclass_selector+
    pseudoes:(pseudo_element_selector pseudo_class_selector*)*
    { return { kind: SelectorKind.Compound, type: null, subclasses, pseudoes }; }
  // Case 3: `(pseudo_element_selector pseudo_class_selector*)` is required.
  / pseudoes:(pseudo_element_selector pseudo_class_selector*)+
    { return { kind: SelectorKind.Compound, type: null, subclasses: [], pseudoes }; }

simple_selector
  = type_selector
  / subclass_selector

combinator
  = ws_star '>' ws_star { return CombinatorKind.Child; }
  / ws_star '+' ws_star { return CombinatorKind.NextSibling; }
  / ws_star '~' ws_star { return CombinatorKind.SubsequentSibling; }
  / ws_star '||' ws_star { return CombinatorKind.Column; }
  / ' ' { return CombinatorKind.Descendant; }

type_selector
  = value:wq_name
    { return { kind: SelectorKind.Type, ...value }; }
  / namespace:ns_prefix? '*'
    { return { kind: SelectorKind.Type, namespace, name: '*' }; }

ns_prefix
  = namespace:(ident_token / '*')? '|'
    { return namespace; }

wq_name
  = namespace:ns_prefix? name:ident_token
    { return { namespace, name }; }

subclass_selector
  = id_selector
  / class_selector
  / attribute_selector
  / pseudo_class_selector

id_selector
  = value:hash_token
    { return { kind: SelectorKind.ID, value }; }

class_selector
  = '.' value:ident_token
    { return { kind: SelectorKind.Class, value }; }

attribute_selector
  = '[' name:wq_name ']'
    { return { kind: SelectorKind.Attribute, name }; }
  / '[' name:wq_name matcher:attr_matcher value:(string_token / ident_token) modifier:attr_modifier? ']'
    { return { kind: SelectorKind.Attribute, name, match: { matcher, value, modifier } }; }

attr_matcher
  = [~|^$*]? '='
    { return text(); }

attr_modifier
  = [is]

pseudo_class_selector
  = ':' name:function_token parameter:any_value ')'
    { return { kind: SelectorKind.PseudoClass, name, parameter }; }
  / ':' name:ident_token
    { return { kind: SelectorKind.PseudoClass, name }; }

pseudo_element_selector
  = ':' selector:pseudo_class_selector
    { return resetKind(selector, SelectorKind.PseudoElement); }

// Tokens
// ======
// Adapted from https://drafts.csswg.org/css-syntax-3/#token-diagrams

comment "comment" = "/*" (!"*/" .) "*/"

newline "newline" = "\n" / "\r\n" / "\r" / "\f"

whitespace "whitespace" = " " / "\t" / newline

hex_digit "hex digit" = [0-9a-fA-F]

escape "escape"
  = "\\"
    (
        !(newline / hex_digit) . // not newline or hex digit
      / hex_digit hex_digit? hex_digit? hex_digit? hex_digit? hex_digit? whitespace_token?
    )

whitespace_token "<whitespace-token>" = whitespace+

// ws*
ws_star "ws*" = whitespace*

ident_token "<ident-token>"
  = ('--' / ('-'? ([a-zA-Z_] / escape)))
    ([a-zA-Z0-9_-] / escape)*
    { return text() }

function_token "<function-token>"
  = name:ident_token "("
    { return name; }

at_keyword_token "<at-keyword-token>"
  = "@" name:ident_token
    { return name; }

hash_token "<hash-token>"
  = "#" name:$([a-zA-Z0-9_-] / escape)+
    { return name; }

// https://drafts.csswg.org/css-syntax-3/#typedef-string-token
string_token "<string-token>"
  = '"' text:$(
        (!('"' / "\\" / newline) .)
      / escape
      / "\\" newline
    )* '"'
    { return text; }
  / "'" text:$(
        (!("'" / "\\" / newline) .)
      / escape
      / "\\" newline
    )* "'"
    { return text; }

// https://drafts.csswg.org/css-syntax-3/#typedef-url-token
url_token "<url-token>"
  = "url"
    "(" ws_star
    content:$(
        // not " ' ( ) \ ws or non-printable
        !('"' / "'" / "(" / ")" / "\\" / whitespace_token / nonprintable) .
      / escape
    )*
    ws_star ")"
    { return { content }; }

// https://drafts.csswg.org/css-syntax-3/#typedef-number-token
number_token "<number-token>"
  = sign:[+-]?
    number:( // BEGIN number part
        digit+ "." digit+
      / digit+
      / "." digit+
    ) // END number part
    exponent:( // BEGIN exponent part
      [eE]
      [+-]?
      digit+
    )? // END exponent part
    { return { sign, number, exponent }; }

// https://drafts.csswg.org/css-syntax-3/#typedef-dimension-token
dimension_token "<dimension-token>" = number_token ident_token

// https://drafts.csswg.org/css-syntax-3/#typedef-percentage-token
percentage_token "<percentage-token>" = number_token "%"

// https://drafts.csswg.org/css-syntax-3/#typedef-cdo-token
CDO_token "<CDO-token>" = "<!--"

// https://drafts.csswg.org/css-syntax-3/#typedef-cdc-token
CDC_token "<CDC-token>" = "-->"

// Definitions
// ===========
// https://drafts.csswg.org/css-syntax-3/#tokenizer-definitions

digit = [\u0030-\u0039]

nonprintable = [\u0000-\u0008\u000B\u000E-\u001F\u007F]

// <any-value>
// ===========

// The most tricky part of the whole grammar. Here's the definition from the
// standard (see https://drafts.csswg.org/css-syntax-3/#any-value).
//
// > The <declaration-value> production matches any sequence of one or more
// > tokens, so long as the sequence does not contain <bad-string-token>,
// > <bad-url-token>, unmatched <)-token>, <]-token>, or <}-token>, or top-level
// > <semicolon-token> tokens or <delim-token> tokens with a value of "!".
// > It represents the entirety of what a valid declaration can have as its value.
// >
// > The <any-value> production is identical to <declaration-value>, but also
// > allows top-level <semicolon-token> tokens and <delim-token> tokens with a
// > value of "!". It represents the entirety of what valid CSS can be in any
// > context.
//
// In summary, we should match any tokens without any unmatched parthenses,
// brackets, and braces.

any_value "any value" = token_sequence

// Punctuator
// ----------
colon = ':'
right_angle = '>'
plus = '+'
tlide = '~'
vertical_bar = '|'
asterisk = '*'
period = '.'

left_paren = '('
right_paren = ')'
left_bracket = '['
right_bracket = ']'
left_brace = '{'
right_brace = '}'

// Token Sequence
// --------------

token_sequence = (
  // Punctuators
    colon
  / right_angle
  / plus
  / tlide
  / vertical_bar
  / asterisk
  / period
  // Tokens (some of them are unused)
  / comment
  / newline
  / whitespace
  // / hex_digit
  // / escape
  / whitespace_token
  / ident_token
  // / function_token
  / at_keyword_token
  / hash_token
  / string_token
  / url_token
  / number_token
  / dimension_token
  / percentage_token
  // Paired parthenses, brackets, and braces
  / parenthesized_token_sequence
  / bracketed_token_sequence
  / braced_token_sequence
)*

parenthesized_token_sequence = left_paren token_sequence right_paren

bracketed_token_sequence = left_brace token_sequence right_bracket

braced_token_sequence = left_brace token_sequence right_brace

// Helpers
// =======

// CSS drafts don't declare any of them. But in order to implement grammars
// describe in CSS drafts, these rules are necessary.

non_ascii = [^\x00-\xFF]
