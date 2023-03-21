open Jingoo
open Core
open Core_unix
open Error_handler.Handler
open Specs.Server_specs
open File_generator
open Ast.Ast_types

let string_of_option = function Some str -> str | None -> ""
let list_of_option = function Some lst -> lst | None -> []

let generate_controller name imports controller_functions
    find_unique_requires_owns_entry find_many_requires_owns_entry =
  let controller_template =
    getcwd () ^ "/templates/server/src/controllers/template.jinja"
  in
  let controller_code =
    Jg_template.from_file controller_template
      ~models:
        [
          ("name", Jg_types.Tstr (String.uncapitalize name));
          ( "imports",
            Jg_types.Tlist
              (List.map imports ~f:(fun import -> Jg_types.Tstr import)) );
          ( "find_unique_requires_owns_entry",
            Jg_types.Tbool find_unique_requires_owns_entry );
          ( "find_many_requires_owns_entry",
            Jg_types.Tbool find_many_requires_owns_entry );
          ( "functions",
            Jg_types.Tlist
              (List.map controller_functions ~f:(fun controller_function ->
                   let {
                     function_id;
                     function_type;
                     required_args;
                     middlewares;
                     custom_fn;
                     includes;
                   } =
                     controller_function
                   in
                   match function_type with
                   | "custom" ->
                       Jg_types.Tobj
                         [
                           ("id", Jg_types.Tstr function_id);
                           ("type", Jg_types.Tstr function_type);
                           ( "custom_fn",
                             Jg_types.Tstr (Option.value_exn custom_fn) );
                         ]
                   | _ ->
                       let ownsEntry =
                         match
                           List.filter middlewares ~f:(fun middleware ->
                               if String.equal middleware "OwnsEntry" then true
                               else false)
                           |> List.hd
                         with
                         | Some _ -> true
                         | None -> false
                       in
                       let { requires_where; requires_search; requires_data } =
                         required_args
                       in
                       Jg_types.Tobj
                         [
                           ("id", Jg_types.Tstr function_id);
                           ("type", Jg_types.Tstr function_type);
                           ("owns_entry", Jg_types.Tbool ownsEntry);
                           ( "includes",
                             Jg_types.Tlist
                               (match includes with
                               | Some includes ->
                                   List.map includes ~f:(fun field ->
                                       Jg_types.Tstr field)
                               | None -> []) );
                           ("requires_where", Jg_types.Tbool requires_where);
                           ("requires_search", Jg_types.Tbool requires_search);
                           ("requires_data", Jg_types.Tbool requires_data);
                         ])) );
        ]
  in
  let controller_file =
    getcwd () ^ "/.out/server/src/controllers/" ^ String.uncapitalize name
    ^ ".ts"
  in
  write_file controller_file controller_code

let generate_controllers controllers_specs auth_specs =
  Hashtbl.iteri controllers_specs ~f:(fun ~key ~data ->
      let ( imports,
            find_unique_requires_owns_entry,
            find_many_requires_owns_entry,
            funcs ) =
        data
      in
      generate_controller key imports funcs find_unique_requires_owns_entry
        find_many_requires_owns_entry);
  let names =
    let names =
      List.map (Hashtbl.keys controllers_specs) ~f:(fun name ->
          Jg_types.Tstr (String.uncapitalize name))
    in
    match auth_specs with
    | Some _ -> names @ [ Jg_types.Tstr "auth" ]
    | None -> names
  in
  let controllers_index_template =
    getcwd () ^ "/templates/server/src/controllers/index.jinja"
  in
  let controllers_index_code =
    Jg_template.from_file controllers_index_template
      ~models:[ ("names", Jg_types.Tlist names) ]
  in
  let controller_index_file =
    getcwd () ^ "/.out/server/src/controllers/index.ts"
  in
  write_file controller_index_file controllers_index_code

let generate_route name routes =
  let route_template =
    getcwd () ^ "/templates/server/src/routes/template.jinja"
  in
  let route_code =
    Jg_template.from_file route_template
      ~models:
        [
          ("name", Jg_types.Tstr (String.uncapitalize name));
          ( "list",
            Jg_types.Tlist
              (List.map routes ~f:(fun route ->
                   let {
                     route_id;
                     http_method;
                     custom_route;
                     route_param;
                     middlewares;
                     route_type;
                     _;
                   } =
                     route
                   in
                   Jg_types.Tobj
                     [
                       ("id", Jg_types.Tstr route_id);
                       ("http_method", Jg_types.Tstr http_method);
                       ( "custom_route",
                         match custom_route with
                         | Some custom_route -> Jg_types.Tstr custom_route
                         | None -> Jg_types.Tnull );
                       ("route_type", Jg_types.Tstr route_type);
                       ( "middlewares",
                         Jg_types.Tlist
                           (List.map middlewares ~f:(fun middleware ->
                                Jg_types.Tstr (String.uncapitalize middleware)))
                       );
                       ( "where",
                         match route_param with
                         | Some id -> Jg_types.Tstr id
                         | None -> Jg_types.Tnull );
                     ])) );
        ]
  in
  let route_file =
    getcwd () ^ "/.out/server/src/routes/" ^ String.uncapitalize name ^ ".ts"
  in
  write_file route_file route_code

let generate_routes routes_specs auth_specs =
  Hashtbl.iteri routes_specs ~f:(fun ~key ~data -> generate_route key data);
  let names =
    let names =
      List.map (Hashtbl.keys routes_specs) ~f:(fun name ->
          Jg_types.Tstr (String.uncapitalize name))
    in
    match auth_specs with
    | Some _ -> names @ [ Jg_types.Tstr "auth" ]
    | None -> names
  in
  let routes_index_template =
    getcwd () ^ "/templates/server/src/routes/index.jinja"
  in
  let routes_index_code =
    Jg_template.from_file routes_index_template
      ~models:[ ("names", Jg_types.Tlist names) ]
  in
  let routes_index_file = getcwd () ^ "/.out/server/src/routes/index.ts" in
  write_file routes_index_file routes_index_code

let generate_validator name validators =
  let validator_template =
    getcwd () ^ "/templates/server/src/validators/template.jinja"
  in
  let validator_code =
    Jg_template.from_file validator_template
      ~models:
        [
          ("name", Jg_types.Tstr (String.uncapitalize name));
          ( "list",
            Jg_types.Tlist
              (List.map validators ~f:(fun validator ->
                   let { validator_id; fields } = validator in
                   let { where; search; data; _ } = fields in
                   Jg_types.Tobj
                     [
                       ("id", Jg_types.Tstr validator_id);
                       ( "where",
                         match where with
                         | Some fields ->
                             Jg_types.Tlist
                               (List.map fields ~f:(fun field ->
                                    let id, types = field in
                                    Jg_types.Tobj
                                      [
                                        ("id", Jg_types.Tstr id);
                                        ( "type",
                                          Jg_types.Tlist
                                            (List.map types ~f:(fun typ ->
                                                 Jg_types.Tstr typ)) );
                                      ]))
                         | None -> Jg_types.Tnull );
                       ( "search",
                         match search with
                         | Some fields ->
                             Jg_types.Tlist
                               (List.map fields ~f:(fun field ->
                                    let id, types = field in
                                    Jg_types.Tobj
                                      [
                                        ("id", Jg_types.Tstr id);
                                        ( "type",
                                          Jg_types.Tlist
                                            (List.map types ~f:(fun typ ->
                                                 Jg_types.Tstr typ)) );
                                      ]))
                         | None -> Jg_types.Tnull );
                       ( "data",
                         match data with
                         | Some fields ->
                             Jg_types.Tlist
                               (List.map fields ~f:(fun field ->
                                    match field with
                                    | Field (id, types) ->
                                        Jg_types.Tobj
                                          [
                                            ( "field",
                                              Jg_types.Tobj
                                                [
                                                  ("id", Jg_types.Tstr id);
                                                  ( "type",
                                                    Jg_types.Tlist
                                                      (List.map types
                                                         ~f:(fun typ ->
                                                           Jg_types.Tstr typ))
                                                  );
                                                ] );
                                          ]
                                    | Object (id, Field (sub_id, types)) ->
                                        Jg_types.Tobj
                                          [
                                            ( "object",
                                              Jg_types.Tobj
                                                [
                                                  ("id", Jg_types.Tstr id);
                                                  ( "field",
                                                    Jg_types.Tobj
                                                      [
                                                        ( "id",
                                                          Jg_types.Tstr sub_id
                                                        );
                                                        ( "type",
                                                          Jg_types.Tlist
                                                            (List.map types
                                                               ~f:(fun typ ->
                                                                 Jg_types.Tstr
                                                                   typ)) );
                                                      ] );
                                                ] );
                                          ]
                                    | _ -> raise_compiler_error ()))
                         | None -> Jg_types.Tnull );
                     ])) );
        ]
  in
  let validator_file =
    getcwd () ^ "/.out/server/src/validators/" ^ String.uncapitalize name
    ^ ".ts"
  in
  write_file validator_file validator_code

let generate_validators validators_specs =
  Hashtbl.iteri validators_specs ~f:(fun ~key ~data ->
      generate_validator key data);
  let names =
    List.map (Hashtbl.keys validators_specs) ~f:(fun name ->
        Jg_types.Tstr (String.uncapitalize name))
  in
  let validators_index_template =
    getcwd () ^ "/templates/server/src/validators/index.jinja"
  in
  let validators_index_code =
    Jg_template.from_file validators_index_template
      ~models:[ ("names", Jg_types.Tlist names) ]
  in
  let validators_index_file =
    getcwd () ^ "/.out/server/src/validators/index.ts"
  in
  write_file validators_index_file validators_index_code

let generate_auth auth_specs =
  match auth_specs with
  | Some
      {
        user_model;
        id_field;
        username_field;
        password_field;
        is_online_field;
        last_active_field;
        _;
      } ->
      List.iter [ "controllers"; "routes"; "validators"; "utils" ]
        ~f:(fun component ->
          if not (String.equal component "validators") then
            let template =
              Fmt.str "%s/templates/server/src/%s/auth.jinja" (getcwd ())
                component
            in
            let code =
              Jg_template.from_file template
                ~models:
                  [
                    ( "user_model",
                      Jg_types.Tstr (String.uncapitalize user_model) );
                    ("id_field", Jg_types.Tstr id_field);
                    ("username_field", Jg_types.Tstr username_field);
                    ("password_field", Jg_types.Tstr password_field);
                    ("is_online_field", Jg_types.Tstr is_online_field);
                    ("last_active_field", Jg_types.Tstr last_active_field);
                  ]
            in
            let output_file =
              Fmt.str "%s/.out/server/src/%s/auth.ts" (getcwd ()) component
            in
            write_file output_file code)
  | None -> ()

let generate_server_file auth_specs =
  let template = Fmt.str "%s/templates/server/src/app.jinja" (getcwd ()) in
  let code =
    match auth_specs with
    | Some _ ->
        Jg_template.from_file template
          ~models:[ ("requires_auth", Jg_types.Tbool true) ]
    | None ->
        Jg_template.from_file template
          ~models:[ ("requires_auth", Jg_types.Tbool false) ]
  in
  let output_file = Fmt.str "%s/.out/server/src/app.ts" (getcwd ()) in
  write_file output_file code

let setup_server_folder =
  let destination = getcwd () ^ "/templates/server" in
  create_folder destination;
  system (Fmt.str "rm %s/.out/server/src/controllers/*" (getcwd ())) |> ignore;
  system (Fmt.str "rm %s/.out/server/src/routes/*" (getcwd ())) |> ignore;
  system (Fmt.str "rm %s/.out/server/src/validators/*" (getcwd ())) |> ignore;
  system (Fmt.str "rm %s/.out/server/src/utils/auth.jinja" (getcwd ()))
  |> ignore;
  system (Fmt.str "rm %s/.out/server/src/app.jinja" (getcwd ())) |> ignore

let generate_server server_specs =
  setup_server_folder;
  let { controllers_specs; routes_specs; validators_specs; auth_specs } =
    server_specs
  in
  generate_server_file auth_specs;
  generate_controllers controllers_specs auth_specs;
  generate_validators validators_specs;
  generate_routes routes_specs auth_specs;
  generate_auth auth_specs
