(* Identifier *)
type id = string
type loc = Lexing.position

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

(* Model definition *)
module Model = struct
  type attr_arg =
    | AttrArgString of loc * literal
    | AttrArgBoolean of loc * literal
    | AttrArgInt of loc * literal
    | AttrArgFunc of loc * string
    | AttrArgRef of loc * id

  type attribute = Attribute of loc * id * attr_arg list
  type field = Field of loc * id * typ * attribute list
  type body = field list
end

module Query = struct
  type typ = FindUnique | FindAll | Create | Update | Delete
  type args = Where of string | Filter of string list | Data of string list
  type models = string list
  type permissions = string list
  type body = typ * args list * models * permissions
end

(* The different types of declarations in the language *)
type declaration =
  | Model of loc * id * Model.body
  | Query of loc * id * Query.body

(* Ast type *)
type ast = Ast of declaration list
