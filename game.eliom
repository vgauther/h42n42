[%%client
open Js_of_ocaml
open Lwt
open Lwt.Infix
open Js_of_ocaml_lwt
open Eliom_content.Html
open Eliom_content.Html.D
open Eliom_content.Html.To_dom
open Struct
open Creets

let spawn_interval_ms = 13500
let creet_size_px = 15
let creet_speed = 1.0             
let river_ratio = 0.05
let hospital_ratio = 0.05
let contamination_probability = 0.02

let () = Random.self_init ()

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

  (* simple compteur d'id *)
let next_creet_id = ref 0
let gen_creet_id () =
  let id = !next_creet_id in
  incr next_creet_id;
  id

let creet_dom_id (c : creet) =
  Printf.sprintf "creet-%d" c.id

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

let remove_all_creets_dom () =
  let doc = Dom_html.document in
  List.iter (fun c ->
    let id = Js.string (creet_dom_id c) in
    let div_opt = doc##getElementById id in
    Js.Opt.iter div_opt (fun div ->
      Js.Opt.iter div##.parentNode (fun parent ->
        Dom.removeChild parent div
      )
    )
  ) (!game_state).creets

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
  };

  let gs = !game_state in
  for _ = 1 to 10 do
    let c = create_creet () in
    gs.creets <- c :: gs.creets;
    gs.nb_healthy_creet <- gs.nb_healthy_creet + 1;
    create_creet_div c;
  done

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

let check_creet_river_collision (c : creet) : unit =
  let _, h = get_window_size () in
  let river_bottom = h *. river_ratio in
  let top = c.pos_y in
  let bottom = c.pos_y +. float_of_int creet_size_px in

  if c.kind = Healthy
     && top <= river_bottom
     && bottom >= 0.
  then begin
    c.kind <- Sick;
    c.speed <- c.speed *. 0.85;
    let gs = !game_state in
    if gs.nb_healthy_creet > 0 then
      gs.nb_healthy_creet <- gs.nb_healthy_creet - 1;
  end

let infect_creet (c : creet) : unit =
  if c.kind = Healthy then begin
    c.kind <- Sick;
    c.speed <- c.speed *. 0.85;
    let gs = !game_state in
    if gs.nb_healthy_creet > 0 then
      gs.nb_healthy_creet <- gs.nb_healthy_creet - 1;
  end

let check_creet_pair_infection (c1 : creet) (c2 : creet) : unit =
  if creets_overlap c1 c2 then
    match c1.kind, c2.kind with
    | Sick, Healthy ->
        if Random.float 1.0 < contamination_probability then
          infect_creet c2
    | Healthy, Sick ->
        if Random.float 1.0 < contamination_probability then
          infect_creet c1
    | _ ->
        ()

let handle_creets_collisions () : unit =
  let rec aux = function
    | [] -> ()
    | c :: rest ->
        List.iter (fun other -> check_creet_pair_infection c other) rest;
        aux rest
  in
  aux (!game_state).creets

let game_over_panel_id = "game-over-panel"

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
        check_creet_river_collision c;
        ) gs.creets;

        handle_creets_collisions ();

        List.iter update_creet_div gs.creets;
        if gs.nb_healthy_creet = 0 && gs.playing && gs.creets <> [] then begin
            gs.playing <- false;
            show_game_over_panel ();
            Lwt.return_unit
        end else
            Lwt_js.sleep 0.016 >>= fun () ->
            game_loop ()
    )

and show_game_over_panel () =
  let doc = Dom_html.document in

  let existing = doc##getElementById (Js.string game_over_panel_id) in
  if Js.Opt.test existing then ()
  else
    let overlay = Dom_html.createDiv doc in
    overlay##.id := Js.string game_over_panel_id;

    let style = overlay##.style in
    style##.position := Js.string "fixed";
    style##.left := Js.string "0";
    style##.top := Js.string "0";
    style##.width := Js.string "100%";
    style##.height := Js.string "100%";
    style##.backgroundColor := Js.string "rgba(0,0,0,0.7)";
    style##.display := Js.string "flex";
    (* propriétés flex via setProperty *)
    style##setProperty
        (Js.string "justify-content")
        (Js.string "center")
        Js.Optdef.empty;

    style##setProperty
        (Js.string "align-items")
        (Js.string "center")
        Js.Optdef.empty;
    style##.zIndex := Js.string "9999";

    let box = Dom_html.createDiv doc in
    let bstyle = box##.style in
    bstyle##.backgroundColor := Js.string "#ffffff";
    bstyle##.padding := Js.string "20px 40px";
    bstyle##.borderRadius := Js.string "8px";
    bstyle##.textAlign := Js.string "center";

    let title = Dom_html.createDiv doc in
    title##.innerHTML := Js.string "Game Over";

    let btn = Dom_html.createButton doc in
    btn##.innerHTML := Js.string "Rejouer";

    btn##.onclick := Dom_html.handler (fun _ ->
    (* supprime tous les creets du DOM *)
    remove_all_creets_dom ();

    (* supprime le panneau s'il existe *)
    let overlay_opt = doc##getElementById (Js.string game_over_panel_id) in
    Js.Opt.iter overlay_opt (fun o ->
        Js.Opt.iter o##.parentNode (fun parent ->
        Dom.removeChild parent o
        )
    );

    (* reset et relance *)
    init_game_state ();
    Lwt.async (fun () -> game_loop ());
    Js._false
    );

    Dom.appendChild box title;
    Dom.appendChild box btn;
    Dom.appendChild overlay box;
    Dom.appendChild doc##.body overlay

let () =  
    Dom_html.window##.onload := Dom_html.handler (fun _ ->
        Js_of_ocaml.Firebug.console##log (Js.string "Hello depuis OCaml !");
        init_game_state ();               (* initialise l’état du jeu *)
        Lwt.async (fun () -> game_loop ());
        Js._false
    )
]