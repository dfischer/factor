in: alien.syntax
USING: alien alien.c-types alien.enums alien.libraries classes.struct
help.markup help.syntax see ;

HELP: DLL"
{ $syntax "DLL\" path\"" }
{ $values { "path" "a pathname string" } }
{ $description "Constructs a DLL handle at parse time." } ;

HELP: ALIEN:
{ $syntax "ALIEN: address" }
{ $values { "address" "a non-negative hexadecimal integer" } }
{ $description "Creates an alien object at parse time." }
{ $notes "Alien objects are invalidated between image saves and loads, and hence source files should not contain alien literals; this word is for interactive use only. See " { $link "alien-expiry" } " for details." } ;

ARTICLE: "syntax-aliens" "Alien object literal syntax"
{ $subsections
    postpone: ALIEN:
    postpone: DLL"
} ;

HELP: library:
{ $syntax "library: name" }
{ $values { "name" "a logical library name" } }
{ $description "Sets the logical library for consequent " { $link postpone: FUNCTION: } ", " { $link postpone: C-GLOBAL: } " and " { $link postpone: CALLBACK: } " definitions, as well as " { $link postpone: &: } " forms." }
{ $notes "Logical library names are defined with the " { $link add-library } " word." } ;

HELP: FUNCTION:
{ $syntax "FUNCTION: return name ( parameters )" }
{ $values { "return" "a C return type" } { "name" "a C function name" } { "parameters" "a comma-separated sequence of type/name pairs; " { $snippet "type1 arg1, type2 arg2, ..." } } }
{ $description "Defines a new word " { $snippet "name" } " which calls the C library function with the same " { $snippet "name" } " in the logical library given by the most recent " { $link postpone: library: } " declaration."
$nl
"The new word must be compiled before being executed." }
{ $examples
"For example, suppose the " { $snippet "foo" } " library exports the following function:"
{ $code
    "void the_answer(char* question, int value) {"
    "    printf(\"The answer to %s is %d.\n\",question,value);"
    "}"
}
"You can define a word for invoking it:"
{ $unchecked-example
    "library: foo\nFUNCTION: void the_answer ( c-string question, int value )"
    "\"the question\" 42 the_answer"
    "The answer to the question is 42."
} }
"Using the " { $link c-string } " type instead of " { $snippet "char*" } " causes the FFI to automatically convert Factor strings to C strings. See " { $link "c-strings" } " for more information on using strings with the FFI."
{ $notes "To make a Factor word with a name different from the C function, use " { $link postpone: FUNCTION-ALIAS: } "." } ;

HELP: FUNCTION-ALIAS:
{ $syntax "FUNCTION-ALIAS: factor-name
    return c_name ( parameters ) ;" }
{ $values { "factor-name" "a Factor word name" } { "return" "a C return type" } { "name" "a C function name" } { "parameters" "a comma-separated sequence of type/name pairs; " { $snippet "type1 arg1, type2 arg2, ..." } } }
{ $description "Defines a new word " { $snippet "factor-name" } " which calls the C library function named " { $snippet "c_name" } " in the logical library given by the most recent " { $link postpone: library: } " declaration."
$nl
"The new word must be compiled before being executed." }
{ $notes "Note that the parentheses and commas are only syntax sugar and can be omitted. They serve no purpose other than to make the declaration easier to read." } ;

{ postpone: FUNCTION: postpone: FUNCTION-ALIAS: } related-words

HELP: TYPEDEF:
{ $syntax "TYPEDEF: old new ;" }
{ $values { "old" "a C type" } { "new" "a C type" } }
{ $description "Aliases the C type " { $snippet "old" } " under the name " { $snippet "new" } "." }
{ $notes "This word differs from " { $link typedef } " in that it runs at parse time, to ensure correct ordering of operations when loading source files. Words defined in source files are compiled before top-level forms are run, so if a source file defines C binding words and uses " { $link typedef } ", the type alias won't be available at compile time." } ;

HELP: ENUM:
{ $syntax "ENUM: type words... ;" "ENUM: type < base-type words..." }
{ $values { "type" { $maybe "a name to typedef to int" } } { "words" "a sequence of word names" } }
{ $description "Creates a c-type that boxes and unboxes integer values to symbols. A symbol is defined for each member word. The base c-type can optionally be specified and defaults to " { $link int } ". A constructor word " { $snippet "<type>" } " is defined for converting from integers to singletons. The generic word " { $link enum>number } " converts from singletons to integers. Enum-typed values are automatically prettyprinted as their singleton words. Unrecognizing enum numbers are kept as numbers." }
{ $examples
    "Here is an example enumeration definition:"
    { $code "ENUM: color_t red { green 3 } blue ;" }
    "The following expression returns true:"
    { $code "3 <color_t> [ green = ] [ enum>number 3 = ] bi and" }

    "Here is a version where the C-type takes a single byte:"
    { $code "ENUM: tv_peripherals_1 < uchar\n{ appletv 1 } { chromecast 2 } { roku 4 } ;" }

    "The same as above but four bytes instead of one:"
    { $code "ENUM: tv_peripherals_4 < uint\n{ appletv 1 } { chromecast 2 } { roku 4 } ;" }
} ;

HELP: c-type:
{ $syntax "c-type: type" }
{ $values { "type" "a new C type" } }
{ $description "Defines a new, opaque C type. Since it is opaque, " { $snippet "type" } " will not be directly usable as a parameter or return type of a " { $link postpone: FUNCTION: } " or as a slot of a " { $link postpone: STRUCT: } ". However, it can be used as the type of a " { $link pointer } "." $nl
{ $snippet "c-type:" } " can also be used to forward declare C types, allowing circular dependencies to occur between types. For example:"
{ $code "c-type: forward
STRUCT: backward { x forward* } ;
STRUCT: forward { x backward* } ;" } }
{ $notes "Primitive C types are displayed using " { $snippet "c-type:" } " syntax when they are " { $link see } "n." } ;

HELP: CALLBACK:
{ $syntax "CALLBACK: return type ( parameters )" }
{ $values { "return" "a C return type" } { "type" "a type name" } { "parameters" "a comma-separated sequence of type/name pairs; " { $snippet "type1 arg1, type2 arg2, ..." } } }
{ $description "Defines a new function pointer C type word " { $snippet "type" } ". The newly defined word works both as a C type and as a wrapper for " { $link alien-callback } " for callbacks that accept the given return type and parameters. The ABI of the callback is decided from the ABI of the active " { $link postpone: library: } " declaration." }
{ $examples
    { $code
        "CALLBACK: bool FakeCallback ( int message, void* payload )"
        ": MyFakeCallback ( -- alien )"
        "    [| message payload |"
        "        \"message #\" write"
        "        message number>string write"
        "        \" received\" write nl"
        "        t"
        "    ] FakeCallback ;"
    }
} ;

HELP: &:
{ $syntax "&: symbol" }
{ $values { "symbol" "A C global variable name" } }
{ $description "Pushes the address of a symbol named " { $snippet "symbol" } " from the current library, set with " { $link postpone: library: } "." } ;

HELP: typedef
{ $values { "old" "a C type" } { "new" "a C type" } }
{ $description "Aliases the C type " { $snippet "old" } " under the name " { $snippet "new" } "." }
{ $notes "Using this word in the same source file which defines C bindings can cause problems, because words are compiled before top-level forms are run. Use the " { $link postpone: TYPEDEF: } " word instead." } ;

{ postpone: TYPEDEF: typedef } related-words

HELP: C-GLOBAL:
{ $syntax "C-GLOBAL: type name ;" }
{ $values { "type" "a C type" } { "name" "a C global variable name" } }
{ $description "Defines a getter " { $snippet "name" } " and setter " { $snippet "set-name" } " for the global value in the current library, set with " { $link postpone: library: } "." } ;

ARTICLE: "alien.enums" "Enumeration types"
"The " { $vocab-link "alien.enums" } " vocab contains the implementation for " { $link postpone: ENUM: } " C types, and provides words for converting between enum singletons and integers. It is possible to dispatch off of members of an enum."
$nl
"Defining enums:"
{ $subsection postpone: ENUM: }
"Defining enums at run-time:"
{ $subsection define-enum }
"Conversions between enums and integers:"
{ $subsections enum>number number>enum } ;