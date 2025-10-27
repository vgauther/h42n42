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
  Html.Manip.appendChild ~%elt c.elt;   (* ~% OK car on est en [%client] *)
  pg.creets <- c :: pg.creets;


let play () =
  Random.self_init ();
  let pg = { iter = 0; global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do _add_creet pg done

]
