[%%shared
open Eliom_lib
open Eliom_content
open Html.D

(* Conteneur PARTAGÉ où s'affichent les creets *)
let elt = div ~a:[ a_class [ "playground" ] ] []

type creet_state = Healthy | Sick | Berserk | Mean

type creet = {
  elt : Html_types.div elt;
  mutable speed : float;
  mutable top : float;
  mutable left : float;
  mutable state : creet_state;
}
]

[%%client
open Js_of_ocaml
open Eliom_content
open Html.D

module Creet = struct
  let create (_global_speed : float ref) : creet =
    let elt = div ~a:[ a_class [ "creet" ] ] [] in
    { elt; speed = 1.0; top = 0.; left = 0.; state = Healthy }
end

type playground_state = {
  mutable iter : int;
  global_speed : float ref;
  mutable creets : creet list;
}

let _add_creet (pg : playground_state) =
  let c = Creet.create pg.global_speed in
  (* On ouvre un bloc explicite pour éviter toute ambiguïté *)
  begin
    Html.Manip.appendChild ~%elt c.elt;
    pg.creets <- c :: pg.creets;
    Js_of_ocaml.Firebug.console##log (Js_of_ocaml.Js.string "creet ajouté");
  end

let play () =
  Random.self_init ();
  let pg = { iter = 0; global_speed = ref 0.; creets = [] } in
  for _ = 1 to 4 do _add_creet pg done;
  Js_of_ocaml.Firebug.console##log (Js_of_ocaml.Js.string "play lancé");
]
