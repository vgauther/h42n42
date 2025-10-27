[%%shared]
open Eliom_lib
open Eliom_content
open Html.D

(* Conteneur PARTAGÉ où s'affichent les creets *)
let elt = div ~a:[ a_class [ "playground" ] ] []

type playground_state = {
  mutable iter : int;
  global_speed : float ref;
  mutable creets : Creet.creet list;
}

[%%client]
open Js_of_ocaml

let _add_creet (pg : playground_state) =
  let c = Creet.Creet.create pg.global_speed in
  (* Affichage du creet dans le conteneur partagé *)
  Html.Manip.appendChild ~%elt c.elt;
  pg.creets <- c :: pg.creets

let play () =
  Random.self_init ();
  let pg = { iter = 0; global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do
    _add_creet pg
  done
