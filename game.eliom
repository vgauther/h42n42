[%%client
open Js_of_ocaml
open Lwt
open Lwt.Infix
open Js_of_ocaml_lwt
open Eliom_content.Html
open Eliom_content.Html.D
open Eliom_content.Html.To_dom


type creet_kind = Healthy | Sick | Berserk | Mean

type creet = {
  mutable id : int;
  mutable kind : creet_kind;
  mutable speed : float;
  mutable pos_x : float;
  mutable pos_y : float;
}

type game_state = {
  mutable duration : int; (* current timestamp in ms *)
  mutable started_at_timestamp : int; (* game start timestamp in ms *)
  mutable last_time_creet_spawn : int; (* since when the last creet was spawned *)
  mutable last_time_speed_increase : int; (* since when the speed was increased *)
  mutable speed : float;
  mutable nb_healthy_creet : int;
  mutable creets : creet list;
  mutable playing : bool;
}

(* state global *)
let game_state =
  ref {
    duration = 0;
    started_at_timestamp = 0;
    last_time_creet_spawn = 0;
    last_time_speed_increase = 0;
    speed = 1.;
    nb_healthy_creet = 0;
    creets = [];
    playing = false;
  }

let now () : int =
  let js_value = Js.Unsafe.eval_string "Date.now()" in
  let time_float = Js.float_of_number js_value in
  let time_int = int_of_float time_float in
  time_int

let init_game_state () =
  let t = now () in
  game_state := {
    duration = 0;
    started_at_timestamp = t;
    last_time_creet_spawn = t;
    last_time_speed_increase = t;
    speed = 1.;
    nb_healthy_creet = 0;
    creets = [];
    playing = true;
  }

let rec game_loop () : unit Lwt.t =
    if not (!game_state).playing then (
        Js_of_ocaml.Firebug.console##log (Js.string "Game stopped");
        Lwt.return_unit   (* fin de la boucle *)
    ) else (
        (* Code exécuté à chaque tour *)
        let now = now () in
        let gs = !game_state in  (* raccourci pour éviter de répéter !game_state *)
        gs.duration <- now - gs.started_at_timestamp;

        Js_of_ocaml.Firebug.console##log (Js.string ("duration = " ^ string_of_int gs.duration ^ " ms"));

        (* On attend 16 millisecondes (~60 FPS) *)
        Lwt_js.sleep 0.016 >>= fun () ->
        game_loop ()
    )

let () =  
    Dom_html.window##.onload := Dom_html.handler (fun _ ->
        Js_of_ocaml.Firebug.console##log (Js.string "Hello depuis OCaml !");
        init_game_state ();               (* initialise l’état du jeu *)
        Lwt.async (fun () -> game_loop ());
        Js._false
    )
]