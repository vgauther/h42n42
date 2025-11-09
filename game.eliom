[%%client
open Js_of_ocaml
open Lwt
open Lwt.Infix
open Js_of_ocaml_lwt
open Eliom_content.Html
open Eliom_content.Html.D
open Eliom_content.Html.To_dom


let spawn_interval_ms = 500      (* un creet toutes les 1000 ms *)
let creet_size_px = 15
let creet_speed = 1.0             (* pour plus tard *)
let () = Random.self_init ()      (* init RNG *)
let river_ratio = 0.05
let hospital_ratio = 0.05

type creet_kind = Healthy | Sick | Berserk | Mean

type creet = {
    mutable id : int;
    mutable kind : creet_kind;
    mutable speed : float;
    mutable pos_x : float;
    mutable pos_y : float;
    mutable dir : float;  (* angle en radians *)
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

  (* simple compteur d'id *)
let next_creet_id = ref 0
let gen_creet_id () =
  let id = !next_creet_id in
  incr next_creet_id;
  id

let get_window_size () =
  let width = float_of_int Dom_html.window##.innerWidth in
  let height = float_of_int Dom_html.window##.innerHeight in
  (width, height)


let random_position () : float * float =
  let w, h = get_window_size () in
  let creet_size = float_of_int creet_size_px in

  let river_bottom = h *. river_ratio in              (* fin de la rivière *)
  let hospital_top = h *. (1. -. hospital_ratio) in  (* début de l'hôpital *)

  let max_x = max 0. (w -. creet_size) in

  let min_y = river_bottom in
  let max_y = max 0. (hospital_top -. creet_size) in

  let y =
    if max_y <= min_y then
      (* cas extrême: plus de place, on le met au milieu *)
      h /. 2.
    else
      min_y +. Random.float (max_y -. min_y)
  in

  let x = Random.float max_x in
  (x, y)

let create_creet () : creet =
    let x, y = random_position () in
    let angle = Random.float (2. *. Float.pi) in
    {
        id = gen_creet_id ();
        kind = Healthy;
        speed = creet_speed;
        pos_x = x;
        pos_y = y;
        dir = angle;
    }

let create_creet_div (c : creet) : unit =
  let div = Dom_html.createDiv Dom_html.document in
  div##.id := Js.string (Printf.sprintf "creet-%d" c.id);

  (* style de base : vert, carré, position absolue *)
  div##.style##.position := Js.string "absolute";
  div##.style##.width := Js.string (Printf.sprintf "%dpx" creet_size_px);
  div##.style##.height := Js.string (Printf.sprintf "%dpx" creet_size_px);
  div##.style##.backgroundColor := Js.string "green";

  div##.style##.left := Js.string (Printf.sprintf "%fpx" c.pos_x);
  div##.style##.top  := Js.string (Printf.sprintf "%fpx" c.pos_y);

  Dom.appendChild Dom_html.document##.body div

let creet_dom_id (c : creet) =
  Printf.sprintf "creet-%d" c.id

let update_creet_div (c : creet) : unit =
  let id = Js.string (creet_dom_id c) in
  let div_opt = Dom_html.document##getElementById id in

  (* Js.Opt.iter applique la fonction seulement si la valeur existe *)
  Js.Opt.iter div_opt (fun div ->
    let style = div##.style in
    style##.left := Js.string (Printf.sprintf "%fpx" c.pos_x);
    style##.top  := Js.string (Printf.sprintf "%fpx" c.pos_y);
  )

let update_creet_position_and_bounce (c : creet) : unit =
  let w, h = get_window_size () in
  let max_x = max 0. (w -. float_of_int creet_size_px) in
  let max_y = max 0. (h -. float_of_int creet_size_px) in

  (* déplacement selon l'angle *)
  let dx = cos c.dir *. c.speed in
  let dy = sin c.dir *. c.speed in
  let new_x = c.pos_x +. dx in
  let new_y = c.pos_y +. dy in

  (* on fait rebondir sur les bords :
     - bord gauche/droite -> on inverse l'angle horizontal (pi -. dir)
     - bord haut/bas      -> on inverse l'angle vertical (-. dir)
  *)
  let x = ref new_x in
  let y = ref new_y in
  let dir = ref c.dir in

  (* gauche *)
  if !x < 0. then begin
    x := 0.;
    dir := Float.pi -. !dir;
  end;

  (* droite *)
  if !x > max_x then begin
    x := max_x;
    dir := Float.pi -. !dir;
  end;

  (* haut *)
  if !y < 0. then begin
    y := 0.;
    dir := -. !dir;
  end;

  (* bas *)
  if !y > max_y then begin
    y := max_y;
    dir := -. !dir;
  end;

  c.pos_x <- !x;
  c.pos_y <- !y;
  c.dir <- !dir

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

let spawn_creet () : unit =
  let c = create_creet () in
  let gs = !game_state in
  gs.creets <- c :: gs.creets;
  gs.nb_healthy_creet <- gs.nb_healthy_creet + 1;
  create_creet_div c;
  Js_of_ocaml.Firebug.console##log
    (Js.string (Printf.sprintf "Spawn creet id=%d" c.id))

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
        (* let now = now () in *)
        let current_time = now () in

        let gs = !game_state in  (* raccourci pour éviter de répéter !game_state *)
        gs.duration <- current_time - gs.started_at_timestamp;

        Js_of_ocaml.Firebug.console##log (Js.string ("duration = " ^ string_of_int gs.duration ^ " ms"));

        let since_last_spawn = current_time - gs.last_time_creet_spawn in
        if since_last_spawn >= spawn_interval_ms then (
            spawn_creet ();
            gs.last_time_creet_spawn <- current_time;
        );

        List.iter (fun c ->
            update_creet_position_and_bounce c;
            update_creet_div c
        ) gs.creets;

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