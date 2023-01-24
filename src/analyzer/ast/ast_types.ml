(* Identifier *)
type id = string
type loc = Lexing.position

(* TODO: add auth config, app config, and db config *)

type scalar_type =
  | String
  | Int
  | Boolean
  | Bytes
  | Json
  | DateTime
  | CustomType of string

type composite_type =
  | List of scalar_type
  | Optional of scalar_type
  | OptionalList of scalar_type

type typ = Scalar of scalar_type | Composite of composite_type

type literal =
  | StringLiteral of scalar_type * string
  | IntLiteral of scalar_type * int
  | BooleanLiteral of scalar_type * bool

(* TODO: add enums to data models *)
module Model = struct
  type attr_arg =
    | AttrArgString of loc * literal
    | AttrArgBoolean of loc * literal
    | AttrArgInt of loc * literal
    | AttrArgNow of loc
    | AttrArgRef of loc * id

  type attribute = Attribute of loc * id * attr_arg list
  type field = Field of loc * id * typ * attribute list
  type body = field list
end

module Query = struct
  type typ = FindUnique | FindAll | Create | Update | Delete

  type arg =
    | Where of loc * string
    | Filter of loc * string list
    | Data of loc * string list

  type model = loc * id
  type permission = loc * id
  type body = typ * arg list * model list * permission list
end

type declaration_type = ModelType | QueryType
type model_declaration = loc * id * Model.body
type query_declaration = loc * id * Query.body

(* The different types of declarations in the language *)
type declaration = Model of model_declaration | Query of query_declaration

type filtered_ast = {
  model_declarations : model_declaration list;
  query_declarations : query_declaration list;
}

(* Ast type *)
type ast = Ast of declaration list
