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
  let create global_speed =
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

let _add_creet playground =
  let creet = Creet.create playground.global_speed in
  playground.creets <- creet :: playground.creets

let play () =
  let playground = { global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do
    _add_creet playground
  done

(* -------------------------- *)
(* Service principal (page)   *)
(* -------------------------- *)
[%%server]

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"h42n42"
            ~css:[["css"; "h42n42.css"]]
            Html.F.(body [
              h1 [txt "h42n42"];
              div ~a:[ a_class ["gameboard"]] [
                div ~a:[ a_class ["river"] ] [];
                div ~a:[ a_class ["playground"] ] [];
                div ~a:[ a_class ["hospital"] ] [];
              ];
            ])))
