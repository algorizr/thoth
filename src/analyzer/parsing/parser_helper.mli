val parse_id : Lexing.position -> string -> string
val parse_field_type : string -> Ast.Ast_types.scalar_type

val parse_query_arg :
  Lexing.position -> string -> string list -> Ast.Ast_types.Query.arg

val parse_query_type : Lexing.position -> string -> Ast.Ast_types.Query.typ

val parse_permissions :
  Lexing.position -> string list -> Ast.Ast_types.permission list

val parse_xra_element :
  Lexing.position ->
  string ->
  string ->
  Ast.Ast_types.XRA.xra_expression list option ->
  Ast.Ast_types.XRA.xra_expression list option ->
  Ast.Ast_types.XRA.xra_expression
