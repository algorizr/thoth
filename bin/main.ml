open Core
open Analyzer
open Type_checker
(* open App_specs *)
(* open Generator *)

let print_error_position (lexbuf : Lexing.lexbuf) =
  let pos = lexbuf.lex_curr_p in
  Fmt.str "Line:%d Position:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let parse_with_error (lexbuf : Lexing.lexbuf) =
  try Ok (Parser.ast Lexer.token lexbuf) with
  | Error.SyntaxError msg ->
      let error_msg = Fmt.str "%s: %s@." (print_error_position lexbuf) msg in
      Error (Core.Error.of_string error_msg)
  | Parser.Error ->
      let error_msg =
        Fmt.str "%s: Syntax error@." (print_error_position lexbuf)
      in
      Error (Core.Error.of_string error_msg)

let parse_file (filename : string) =
  let file_content = In_channel.read_all filename in
  let lexbuf = Lexing.from_string file_content in
  parse_with_error lexbuf

let () =
  let filename = "./examples/test.ra" in
  print_string (Fmt.str "Parsing %s\n" filename);
  match parse_file filename with
  | Ok ast ->
      TypeChecker.run ast;
      print_string (Pprinter.string_of_ast ast)
      (* let db_specs = Db_specs.generate_db_specs ast in
         print_string (Db_generator.generate_db db_specs) *)
  | Error error -> print_string (Core.Error.to_string_hum error)
