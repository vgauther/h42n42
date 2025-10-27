[%%shared
open Eliom_content
open Html.D

let elt = div ~a:[ a_class [ "playground" ] ] []
]

[%%client
open Js_of_ocaml
open Eliom_content
open Html.D

let () = Js_of_ocaml.Firebug.console##log (Js_of_ocaml.Js.string "Playground: client bundle chargé")

type playground_state = {
  mutable iter : int;
  global_speed : float ref;
  mutable creets : Creet.creet list;
}

let _add_creet (pg : playground_state) =
  let c = Creet.create pg.global_speed in
  Html.Manip.appendChild ~%elt c.elt;
  pg.creets <- c :: pg.creets;
  Js_of_ocaml.Firebug.console##log (Js_of_ocaml.Js.string "creet ajouté")

let play () =
  Js_of_ocaml.Firebug.console##log (Js_of_ocaml.Js.string "play démarré");
  Random.self_init ();
  let pg = { iter = 0; global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do _add_creet pg done;
  Js_of_ocaml.Firebug.console##log
    (Js_of_ocaml.Js.string (Printf.sprintf "play terminé (%d creets)" (List.length pg.creets)))
]
