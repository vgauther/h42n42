[%%shared]
open Eliom_lib
open Eliom_content
open Html.D

(* -------------------------- *)
(* Application Eliom          *)
(* -------------------------- *)
module H42n42_app =
  Eliom_registration.App(struct
    let application_name = "h42n42"
    let global_data_path = None
  end)

let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* -------------------------- *)
(* Conteneur partagé du terrain *)
(* -------------------------- *)
let playground_elt = div ~a:[ a_class ["playground"] ] []

(* -------------------------- *)
(* Types de jeu               *)
(* -------------------------- *)
type creet_state = Healthy | Sick | Berserk | Mean

type creet = {
  elt : Html_types.div elt;
  mutable speed : float;
  mutable top : float;
  mutable left : float;
  mutable state : creet_state;
}

(* -------------------------- *)
(* Module Creet               *)
(* -------------------------- *)
module Creet = struct
  let create (_global_speed : float ref) =
    let elt = div ~a:[ a_class [ "creet" ] ] [] in
    let creet = {
      elt;
      speed = 1.0;
      top = 0.;
      left = 0.;
      state = Healthy;
    } in
    creet
end

(* -------------------------- *)
(* Type playground            *)
(* -------------------------- *)
type playground = {
  global_speed : float ref;
  mutable creets : creet list;
}

(* -------------------------- *)
(* Partie client              *)
(* -------------------------- *)
[%%client]

let _add_creet (pg: playground) =
  let c = Creet.create pg.global_speed in
  Html.Manip.appendChild ~%playground_elt c.elt;  (* ← insertion visuelle *)
  pg.creets <- c :: pg.creets

let play () =
  Random.self_init ();
  let pg = { global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do
    _add_creet pg
  done

(* -------------------------- *)
(* Service principal (page)   *)
(* -------------------------- *)
[%%server]

let page =
  Html.F.(body [
    h1 [txt "h42n42"];
    div ~a:[ a_class ["gameboard"]] [
      div ~a:[ a_class ["river"] ] [];
      playground_elt;                         (* ← on place le conteneur partagé *)
      div ~a:[ a_class ["hospital"] ] [];
    ];
  ])

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       (* lancer play() côté client au chargement *)
       let _ = [%client (play () : unit)] in
       Lwt.return
         (Eliom_tools.F.html
            ~title:"h42n42"
            ~css:[["css"; "h42n42.css"]]
            page))
