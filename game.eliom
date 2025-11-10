[%%client
open Js_of_ocaml
open Lwt
open Lwt.Infix
open Js_of_ocaml_lwt
open Eliom_content.Html
open Eliom_content.Html.D
open Eliom_content.Html.To_dom

let spawn_interval_ms = 13500
let creet_size_px = 35
let creet_speed = 1.0             
let river_ratio = 0.05
let hospital_ratio = 0.05
let contamination_probability = 0.02
let berserk_probability = 0.10
let mean_probability = 0.10
let berserk_growth_duration = 10000.0  (* ms pour atteindre x4 taille *)
let speed_increase_interval_ms = 10000      (* tous les 10s par ex. *)
let speed_increase_factor = 1.20  


let () = Random.self_init ()

type creet_kind = Healthy | Sick | Berserk | Mean

let color_of_kind (kind : creet_kind) =
  if kind = Healthy then "green"
  else if kind = Sick then "orange"
  else if kind = Berserk then "purple"
  else "red"

type creet = {
  mutable id : int;
  mutable kind : creet_kind;
  mutable speed : float;
  mutable pos_x : float;
  mutable pos_y : float;
  mutable dir : float;
  mutable size : float;
  mutable base_size : float;
  mutable infected_at : int;
  mutable grabbed : bool;  (* nouveau : si attrapé par le joueur *)
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

let create_creet () : creet =
  let x, y = random_position () in
  let angle = Random.float (2. *. Float.pi) in
  let base = float_of_int creet_size_px in
  let gs = !game_state in
  {
    id = gen_creet_id ();
    kind = Healthy;
    speed = creet_speed *. gs.speed;  (* tient compte de la vitesse globale *)
    pos_x = x;
    pos_y = y;
    dir = angle;
    size = base;
    base_size = base;
    infected_at = 0;
    grabbed = false;
  }

let apply_speed_increase () =
  let gs = !game_state in
  (* facteur global *)
  gs.speed <- gs.speed *. speed_increase_factor;
  (* on applique aussi aux creets déjà présents *)
  List.iter
    (fun (c : creet) ->
      c.speed <- c.speed *. speed_increase_factor)
    gs.creets;

  Js_of_ocaml.Firebug.console##log
    (Js.string (Printf.sprintf "Speed increased: global=%.3f" gs.speed))


let create_creet_div (c : creet) : unit =
    let div = Dom_html.createDiv Dom_html.document in
    div##.id := Js.string (creet_dom_id c);
    div##.style##.position := Js.string "absolute";
    div##.style##.width := Js.string (Printf.sprintf "%fpx" c.size);
    div##.style##.height := Js.string (Printf.sprintf "%fpx" c.size);
    div##.style##.backgroundColor := Js.string (color_of_kind c.kind);
    div##.style##.left := Js.string (Printf.sprintf "%fpx" c.pos_x);
    div##.style##.top  := Js.string (Printf.sprintf "%fpx" c.pos_y);
    Dom.appendChild Dom_html.document##.body div

let update_mean_direction (c : creet) : unit =
  if c.kind = Mean then begin
    let gs = !game_state in
    let best_dx = ref 0.0 in
    let best_dy = ref 0.0 in
    let best_dist2 = ref max_float in

    let lst = ref gs.creets in
    while !lst <> [] do
      let h = List.hd !lst in
      if h.kind = Healthy then begin
        let dx = h.pos_x -. c.pos_x in
        let dy = h.pos_y -. c.pos_y in
        let d2 = dx *. dx +. dy *. dy in
        if d2 > 0.0001 && d2 < !best_dist2 then begin
          best_dist2 := d2;
          best_dx := dx;
          best_dy := dy
        end
      end;
      lst := List.tl !lst
    done;

    if !best_dist2 < max_float then
      c.dir <- atan2 !best_dy !best_dx
  end

let random_dir_change_probability = 0.002  (* faible proba par tick *)
let maybe_change_direction (c : creet) =
  if c.kind <> Mean then
    if Random.float 1.0 < random_dir_change_probability then
      c.dir <- Random.float (2. *. Float.pi)

let update_creet_position_and_bounce (c : creet) : unit =
    let w, h = get_window_size () in
    let max_x = max 0. (w -. c.size) in
    let max_y = max 0. (h -. c.size) in

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

let infect_creet (c : creet) : unit =
  if (not c.grabbed) && c.kind = Healthy then begin
    let gs = !game_state in
    if gs.nb_healthy_creet > 0 then
      gs.nb_healthy_creet <- gs.nb_healthy_creet - 1;

    c.speed <- c.speed *. 0.85;
    c.infected_at <- now ();

    let r = Random.float 1.0 in
    if r < berserk_probability then
      c.kind <- Berserk
    else if r < berserk_probability +. mean_probability then begin
      c.kind <- Mean;
      c.size <- c.base_size *. 0.85;
    end
    else
      c.kind <- Sick
  end

let update_creet_div (c : creet) : unit =
  let id = Js.string (creet_dom_id c) in
  let div_opt = Dom_html.document##getElementById id in
  Js.Opt.iter div_opt (fun div ->
    let style = div##.style in
    style##.left := Js.string (Printf.sprintf "%fpx" c.pos_x);
    style##.top  := Js.string (Printf.sprintf "%fpx" c.pos_y);
    style##.width := Js.string (Printf.sprintf "%fpx" c.size);
    style##.height := Js.string (Printf.sprintf "%fpx" c.size);
    style##.backgroundColor := Js.string (color_of_kind c.kind);
  )

let heal_creet (c : creet) : unit =
  if c.kind <> Healthy then begin
    let gs = !game_state in
    c.kind <- Healthy;
    c.size <- c.base_size;
    c.infected_at <- 0;
    c.speed <- creet_speed *. gs.speed;
    gs.nb_healthy_creet <- gs.nb_healthy_creet + 1;
    update_creet_div c
  end

let is_in_hospital (c : creet) : bool =
  let _, h = get_window_size () in
  let hospital_top = h *. (1.0 -. hospital_ratio) in
  c.pos_y +. c.size >= hospital_top

let setup_drag_and_drop (c : creet) : unit =
  let doc = Dom_html.document in
  let id = Js.string (creet_dom_id c) in
  let div_opt = doc##getElementById id in

  Js.Opt.iter div_opt (fun div ->
    let offset_x = ref 0. in
    let offset_y = ref 0. in
    let dragging = ref false in

    let rec wait_mousedown () =
      Lwt_js_events.mousedown div >>= fun ev ->
      let gs = !game_state in
      if gs.playing then begin
        dragging := true;
        c.grabbed <- true;

        let mouse_x = float_of_int ev##.clientX in
        let mouse_y = float_of_int ev##.clientY in
        offset_x := mouse_x -. c.pos_x;
        offset_y := mouse_y -. c.pos_y;

        let rec drag_loop () =
          if (not !dragging) || not (!game_state).playing then
            Lwt.return_unit
          else
            Lwt.pick [
              (* Relâchement *)
              (Lwt_js_events.mouseup doc >>= fun _ ->
                Lwt.return `Up);

              (* Mouvement souris *)
              (Lwt_js_events.mousemove doc >>= fun mev ->
                if !dragging then begin
                  let mx = float_of_int mev##.clientX in
                  let my = float_of_int mev##.clientY in

                  c.pos_x <- mx -. !offset_x;
                  c.pos_y <- my -. !offset_y;

                  (* Clamp dans la fenêtre *)
                  let w, h = get_window_size () in
                  if c.pos_x < 0. then c.pos_x <- 0.;
                  if c.pos_y < 0. then c.pos_y <- 0.;
                  if c.pos_x +. c.size > w then
                    c.pos_x <- w -. c.size;
                  if c.pos_y +. c.size > h then
                    c.pos_y <- h -. c.size;

                  update_creet_div c;
                end;
                Lwt.return `Move)
            ] >>= function
            | `Up ->
                dragging := false;
                c.grabbed <- false;

                (* Si déposé dans l'hôpital ET malade -> guéri *)
                if is_in_hospital c then
                  heal_creet c;

                wait_mousedown ()

            | `Move ->
                drag_loop ()
        in
        Lwt.async drag_loop;
        wait_mousedown ()
      end else
        wait_mousedown ()
    in

    Lwt.async wait_mousedown
  )

let check_creet_river_collision (c : creet) : unit =
  let _, h = get_window_size () in
  let river_bottom = h *. river_ratio in
  let top = c.pos_y in
  let bottom = c.pos_y +. c.size in

  if c.kind = Healthy
     && top <= river_bottom
     && bottom >= 0.
  then
    infect_creet c

let update_berserk (c : creet) : unit =
  if c.kind = Berserk && c.infected_at > 0 then begin
    let elapsed = float_of_int (now () - c.infected_at) in
    if elapsed > 0. then begin
      let t = elapsed /. berserk_growth_duration in
      let clamped =
        if t < 0. then 0.
        else if t > 1. then 1.
        else t
      in
      let factor = 1.0 +. 3.0 *. clamped in   (* de 1x à 4x *)
      c.size <- c.base_size *. factor
    end
  end

let creets_overlap (a : creet) (b : creet) : bool =
  let a_left = a.pos_x in
  let a_top = a.pos_y in
  let a_right = a.pos_x +. a.size in
  let a_bottom = a.pos_y +. a.size in

  let b_left = b.pos_x in
  let b_top = b.pos_y in
  let b_right = b.pos_x +. b.size in
  let b_bottom = b.pos_y +. b.size in

  not (
    b_left  > a_right  ||
    b_right < a_left   ||
    b_top   > a_bottom ||
    b_bottom < a_top
  )

let check_creet_pair_infection (c1 : creet) (c2 : creet) : unit =
  if creets_overlap c1 c2 then begin
    let c1_contaminant =
      (c1.kind = Sick) || (c1.kind = Berserk) || (c1.kind = Mean)
    in
    let c2_contaminant =
      (c2.kind = Sick) || (c2.kind = Berserk) || (c2.kind = Mean)
    in

    if c1_contaminant && c2.kind = Healthy then begin
      if Random.float 1.0 < contamination_probability then
        infect_creet c2
    end
    else if c2_contaminant && c1.kind = Healthy then begin
      if Random.float 1.0 < contamination_probability then
        infect_creet c1
    end
  end

let handle_creet_collisions_for (c : creet) : unit =
  let gs = !game_state in
  let rec aux lst =
    match lst with
    | [] -> ()
    | other :: tl ->
      if other.id <> c.id then
        check_creet_pair_infection c other;
      aux tl
  in
  aux gs.creets

let rec creet_loop (c : creet) : unit Lwt.t =
  let rec step () =
    let gs = !game_state in
    if (not gs.playing) || not (List.exists (fun x -> x.id = c.id) gs.creets)
    then
      Lwt.return_unit
    else begin
      (* si pas attrapé par le joueur, le thread contrôle le mouvement *)
      if not c.grabbed then begin
        update_mean_direction c;
        maybe_change_direction c;
        update_creet_position_and_bounce c;
        check_creet_river_collision c;
        update_berserk c;
        handle_creet_collisions_for c;
      end;
      update_creet_div c;

      Lwt_js.sleep 0.016 >>= step
    end
  in
  step ()

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
    setup_drag_and_drop c;
    Lwt.async (fun () -> creet_loop c);  (* <-- thread par Creet *)
  done

let spawn_creet () : unit =
  let gs = !game_state in
  if gs.nb_healthy_creet > 0 && gs.playing then begin
    let c = create_creet () in
    gs.creets <- c :: gs.creets;
    gs.nb_healthy_creet <- gs.nb_healthy_creet + 1;
    create_creet_div c;
    setup_drag_and_drop c;
    Lwt.async (fun () -> creet_loop c);
    Js_of_ocaml.Firebug.console##log
      (Js.string (Printf.sprintf "Spawn creet id=%d" c.id))
  end


let game_over_panel_id = "game-over-panel"

let rec game_loop () : unit Lwt.t =
  if not (!game_state).playing then
    Lwt.return_unit
  else
    let current_time = now () in
    let gs = !game_state in

    gs.duration <- current_time - gs.started_at_timestamp;

    (* spawn périodique *)
    let since_last_spawn = current_time - gs.last_time_creet_spawn in
    if since_last_spawn >= spawn_interval_ms then (
      spawn_creet ();
      gs.last_time_creet_spawn <- current_time;
    );

    (* accélération progressive *)
    let since_last_speed_increase =
      current_time - gs.last_time_speed_increase
    in
    if since_last_speed_increase >= speed_increase_interval_ms then (
      apply_speed_increase ();
      gs.last_time_speed_increase <- current_time;
    );

    (* condition de fin *)
    if gs.nb_healthy_creet = 0 && gs.creets <> [] then begin
      gs.playing <- false;
      show_game_over_panel ();
      Lwt.return_unit
    end else
      Lwt_js.sleep 0.05 >>= fun () ->
      game_loop ()



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