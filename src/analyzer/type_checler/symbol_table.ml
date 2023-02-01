open Core
open Ast
open Ast.Ast_types
open Error_handler.Handler

module LocalSymbolTable = struct
  type 'a t = (string, 'a) Hashtbl.t

  let create () : 'a t = Hashtbl.create ~size:10 (module String)

  let allocate (table : 'a t) ~key:(symbol : string) ~data:(value : 'a) : unit =
    Hashtbl.add_exn table ~key:symbol ~data:value

  let lookup (table : 'a t) ~key:(symbol : string) : 'a =
    Hashtbl.find_exn table symbol

  let contains (table : 'a t) ~key:(symbol : string) : bool =
    Hashtbl.mem table symbol
end

type field_info = {
  typ : typ;
  field_attrs_table : Model.attr_arg list LocalSymbolTable.t;
}

type query_info = {
  typ : Query.typ;
  args : Query.arg list;
  models : Query.model list;
  permissions : permission list option;
}

type component_info = { args : string LocalSymbolTable.t }
type page_info = { route : Page.route; permissions : permission list option }

module GlobalSymbolTable = struct
  type declaration_info =
    | ModelInfo of field_info
    | QueryInfo of query_info
    | ComponentInfo of component_info
    | PageInfo of page_info

  type value_record = {
    declaration_type : declaration_type;
    table : declaration_info LocalSymbolTable.t;
  }

  type 'a t = (string, value_record) Hashtbl.t

  let create () : 'a t = Hashtbl.create ~size:10 (module String)

  let allocate (table : 'a t) ~key:(symbol : string)
      ~data:(value : value_record) : unit =
    Hashtbl.add_exn table ~key:symbol ~data:value

  let get_table (table : 'a t) ~key:(symbol : string) =
    (Hashtbl.find_exn table symbol).table

  let get_declaration_type (table : 'a t) ~key:(symbol : string) :
      declaration_type =
    (Hashtbl.find_exn table symbol).declaration_type

  let contains (table : 'a t) ~key:(symbol : string) : bool =
    Hashtbl.mem table symbol

  let check_type (table : 'a t) ~key:(symbol : string)
      (declaration_type : declaration_type) : bool =
    if phys_equal (get_declaration_type table ~key:symbol) declaration_type then
      true
    else false
end

module ModelManager = struct
  let rec allocate_field_attrs
      (local_table : Model.attr_arg list LocalSymbolTable.t) (field_id : string)
      (attrs : Model.attribute list) : unit =
    match attrs with
    | [] -> ()
    | attr :: attrs ->
        (match attr with
        | Model.Attribute (loc, id, args) ->
            if LocalSymbolTable.contains local_table ~key:id then
              raise_multi_definitions_error (Pprinter.string_of_loc loc) id;
            LocalSymbolTable.allocate local_table ~key:id ~data:args);
        allocate_field_attrs local_table field_id attrs

  let rec allocate_fields
      (local_table : GlobalSymbolTable.declaration_info LocalSymbolTable.t)
      (body : Model.body) : unit =
    match body with
    | [] -> ()
    | field :: fields ->
        (match field with
        | Model.Field (loc, id, typ, field_attrs) ->
            if LocalSymbolTable.contains local_table ~key:id then
              raise_multi_definitions_error (Pprinter.string_of_loc loc) id;
            let field_attrs_table = LocalSymbolTable.create () in
            allocate_field_attrs field_attrs_table id field_attrs;
            let field =
              GlobalSymbolTable.ModelInfo { typ; field_attrs_table }
            in
            LocalSymbolTable.allocate local_table ~key:id ~data:field);
        allocate_fields local_table fields

  let allocate_model (global_table : 'a GlobalSymbolTable.t) (loc, id, body) :
      unit =
    if GlobalSymbolTable.contains global_table ~key:id then
      raise_multi_definitions_error (Pprinter.string_of_loc loc) id;
    let table = LocalSymbolTable.create () in
    let declaration_type = ModelType in
    allocate_fields table body;
    GlobalSymbolTable.allocate global_table ~key:id
      ~data:{ declaration_type; table }
end

module QueryManager = struct
  let allocation_body (local_table : 'a LocalSymbolTable.t) (id : id) info :
      unit =
    let typ, args, models, permissions = info in
    let query_body =
      GlobalSymbolTable.QueryInfo { typ; args; models; permissions }
    in
    LocalSymbolTable.allocate local_table ~key:id ~data:query_body

  let allocate_query (global_table : 'a GlobalSymbolTable.t)
      (query : query_declaration) : unit =
    let loc, id, typ, args, models, permissions = query in
    if GlobalSymbolTable.contains global_table ~key:id then
      raise_multi_definitions_error (Pprinter.string_of_loc loc) id;
    let table = LocalSymbolTable.create () in
    let declaration_type = QueryType in
    allocation_body table id (typ, args, models, permissions);
    GlobalSymbolTable.allocate global_table ~key:id
      ~data:{ declaration_type; table }
end

module ComponentManager = struct
  let allocate_component (global_table : 'a GlobalSymbolTable.t)
      (component : component_declaration) : unit =
    let loc, id, _, _ = component in
    if GlobalSymbolTable.contains global_table ~key:id then
      raise_multi_definitions_error (Pprinter.string_of_loc loc) id;
    let table = LocalSymbolTable.create () in
    let declaration_type = ComponentType in
    GlobalSymbolTable.allocate global_table ~key:id
      ~data:{ declaration_type; table }
end

module PageManager = struct
  let allocate_page (global_table : 'a GlobalSymbolTable.t)
      (page : page_declaration) : unit =
    let loc, id, _, _, _ = page in
    if GlobalSymbolTable.contains global_table ~key:id then
      raise_multi_definitions_error (Pprinter.string_of_loc loc) id;
    let table = LocalSymbolTable.create () in
    let declaration_type = ComponentType in
    GlobalSymbolTable.allocate global_table ~key:id
      ~data:{ declaration_type; table }
end

module SymbolTableManager = struct
  let get_model_info (declaration_info : GlobalSymbolTable.declaration_info) :
      field_info =
    (match declaration_info with
    | ModelInfo field_info -> Some field_info
    | _ -> None)
    |> Option.value_exn

  let get_query_info (declaration_info : GlobalSymbolTable.declaration_info) :
      query_info =
    (match declaration_info with
    | QueryInfo field_info -> Some field_info
    | _ -> None)
    |> Option.value_exn

  let get_component_info (declaration_info : GlobalSymbolTable.declaration_info)
      : component_info =
    (match declaration_info with
    | ComponentInfo component_info -> Some component_info
    | _ -> None)
    |> Option.value_exn

  let get_page_info (declaration_info : GlobalSymbolTable.declaration_info) :
      page_info =
    (match declaration_info with
    | PageInfo page_info -> Some page_info
    | _ -> None)
    |> Option.value_exn

  let populate (global_table : 'a GlobalSymbolTable.t) (Ast declarations) : unit
      =
    let populate_declaration global_table declaration =
      match declaration with
      | Model model -> ModelManager.allocate_model global_table model
      | Query query -> QueryManager.allocate_query global_table query
      | Component component ->
          ComponentManager.allocate_component global_table component
      | Page page -> PageManager.allocate_page global_table page
    in
    List.iter
      ~f:(fun declaration -> populate_declaration global_table declaration)
      declarations
end
