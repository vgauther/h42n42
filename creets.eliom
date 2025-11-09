[%%client
open Struct  (* importe creet, creet_kind, etc. *)
open Js_of_ocaml
open Lwt
open Lwt.Infix
open Js_of_ocaml_lwt
open Eliom_content.Html
open Eliom_content.Html.D
open Eliom_content.Html.To_dom
open Game

let create_creet_div (c : creet) : unit =
  let div = Dom_html.createDiv Dom_html.document in
  div##.id := Js.string (creet_dom_id c);
  div##.style##.position := Js.string "absolute";
  div##.style##.width := Js.string (Printf.sprintf "%dpx" creet_size_px);
  div##.style##.height := Js.string (Printf.sprintf "%dpx" creet_size_px);
  div##.style##.backgroundColor := Js.string (color_of_kind c.kind);
  div##.style##.left := Js.string (Printf.sprintf "%fpx" c.pos_x);
  div##.style##.top  := Js.string (Printf.sprintf "%fpx" c.pos_y);
  Dom.appendChild Dom_html.document##.body div

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

let spawn_creet () : unit =
  let c = create_creet () in
  let gs = !game_state in
  gs.creets <- c :: gs.creets;
  gs.nb_healthy_creet <- gs.nb_healthy_creet + 1;
  create_creet_div c;
  Js_of_ocaml.Firebug.console##log
    (Js.string (Printf.sprintf "Spawn creet id=%d" c.id))

let creets_overlap (a : creet) (b : creet) : bool =
  let size = float_of_int creet_size_px in

  let a_left   = a.pos_x
  and a_right  = a.pos_x +. size
  and a_top    = a.pos_y
  and a_bottom = a.pos_y +. size in

  let b_left   = b.pos_x
  and b_right  = b.pos_x +. size
  and b_top    = b.pos_y
  and b_bottom = b.pos_y +. size in

  not (
    b_left  > a_right  ||
    b_right < a_left   ||
    b_top   > a_bottom ||
    b_bottom < a_top
  )

let update_creet_div (c : creet) : unit =
  let id = Js.string (creet_dom_id c) in
  let div_opt = Dom_html.document##getElementById id in
  Js.Opt.iter div_opt (fun div ->
    let style = div##.style in
    style##.left := Js.string (Printf.sprintf "%fpx" c.pos_x);
    style##.top  := Js.string (Printf.sprintf "%fpx" c.pos_y);
    style##.backgroundColor := Js.string (color_of_kind c.kind);
  )


]
