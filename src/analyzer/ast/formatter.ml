open Core
open Ast_types

let string_of_loc loc =
  Fmt.str "Line:%d, Position:%d" loc.Lexing.pos_lnum
    (loc.Lexing.pos_cnum - loc.Lexing.pos_bol + 1)

let string_of_scalar_type scalar_type =
  match scalar_type with
  | String -> "String"
  | Int -> "Int"
  | Boolean -> "Boolean"
  | DateTime -> "DateTime"
  | Reference -> "Reference"
  | Nil -> "Nil"
  | Assoc -> "Assoc"
  | CustomType custom_type -> custom_type

let string_of_composite_type composite_type =
  match composite_type with
  | List scalar_type -> Fmt.str "%s[]" (string_of_scalar_type scalar_type)
  | Optional scalar_type -> Fmt.str "%s?" (string_of_scalar_type scalar_type)
  | OptionalList scalar_type ->
      Fmt.str "%s[]?" (string_of_scalar_type scalar_type)

let string_of_type typ =
  match typ with
  | Scalar scalar_type -> string_of_scalar_type scalar_type
  | Composite composite_type -> string_of_composite_type composite_type

let string_of_literal literal =
  match literal with
  | StringLiteral (_, str) -> Fmt.str "'%s'" str
  | BooleanLiteral (_, boolean) -> Fmt.str "%b" boolean
  | IntLiteral (_, num) -> Fmt.str "%d" num

module ModelFormatter = struct
  let string_of_field_unique_type field_unique_type =
    match field_unique_type with
    | Model.UniqueField -> "UniqueField"
    | Model.NonUniqueField -> "NonUniqueField"

  let string_of_field_attr_arg arg =
    match arg with
    | Model.AttrArgLiteral literal ->
        Fmt.str "\"%s\"" (string_of_literal literal)
    | Model.AttrArgRef (_, ref) -> Fmt.str "%s" ref
    | Model.AttrArgNow _ -> "now()"

  let rec string_of_field_attr_args args =
    match args with
    | [] -> ""
    | [ arg ] -> string_of_field_attr_arg arg
    | arg :: args ->
        string_of_field_attr_arg arg ^ ", " ^ string_of_field_attr_args args

  let string_of_field_attr attr =
    match attr with
    | Model.Attribute (_, id, args) ->
        Fmt.str "%s(%s)" id (string_of_field_attr_args args)

  let rec string_of_field_attrs attrs =
    match attrs with
    | [] -> ""
    | [ attr ] -> string_of_field_attr attr
    | attr :: attrs ->
        string_of_field_attr attr ^ ", " ^ string_of_field_attrs attrs

  let string_of_field field =
    match field with
    | Model.Field (_, id, field_type, attrs) ->
        if List.length attrs > 0 then
          Fmt.str "\"%s\", %s, %s" id
            (string_of_type field_type)
            (string_of_field_attrs attrs)
        else Fmt.str "\"%s\", %s" id (string_of_type field_type)

  let rec string_of_fields fields =
    match fields with
    | [] -> ""
    | [ field ] -> Fmt.str "\n      Field(%s)" (string_of_field field)
    | field :: fields ->
        Fmt.str "\n      Field(%s)" (string_of_field field)
        ^ string_of_fields fields
end

module QueryFormatter = struct
  let string_of_query_argument_type argument_type =
    match argument_type with
    | Query.DataArgument -> "Data"
    | Query.WhereArgument -> "Where"
    | Query.SearchArgument -> "Search"

  let string_of_query_type query_type =
    match query_type with
    | Query.Create -> "create"
    | Query.Update -> "update"
    | Query.Delete -> "delete"
    | Query.FindUnique -> "findUnique"
    | Query.FindMany -> "findMany"
end

module ComponentFormatter = struct
  let string_form_field_type field_type =
    match field_type with
    | Component.TextField -> "text"
    | Component.NumberField -> "number"
    | Component.EmailField -> "email"
    | Component.PasswordField -> "password"
end

let string_of_declaration_type declaration_type =
  match declaration_type with
  | ModelDeclaration -> "Model"
  | QueryDeclaration -> "Query"
  | ComponentDeclaration -> "Component"
  | PageDeclaration -> "Page"

let string_of_declaration declaration =
  match declaration with
  | Model (_, id, body) ->
      Fmt.str "  Model(\n    \"%s\",\n    [%s\n    ]\n  )" id
        (ModelFormatter.string_of_fields body)
  | Query _ -> ""
  | Component _ -> ""
  | Page _ -> ""

let rec string_of_declarations declarations =
  match declarations with
  | [] -> ""
  | [ declaration ] -> string_of_declaration declaration
  | declaration :: declarations ->
      string_of_declaration declaration
      ^ ",\n"
      ^ string_of_declarations declarations

let string_of_ast (_, declarations) =
  Fmt.str "Ast(\n%s\n)" (string_of_declarations declarations)