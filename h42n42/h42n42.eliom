(* =========================== *)
(* ======   SHARED   ========= *)
(* =========================== *)

[%%shared]
open Eliom_lib
open Eliom_content
open Html.D

(* Conteneur partagé du terrain (inséré côté serveur, manipulé côté client) *)
let playground_elt = div ~a:[ a_class ["playground"] ] []

type creet_state = Healthy | Sick | Berserk | Mean

type creet = {
  elt : Html_types.div elt;
  mutable speed : float;
  mutable top : float;
  mutable left : float;
  mutable state : creet_state;
}

module Creet = struct
  let create (_global_speed : float ref) =
    let elt = div ~a:[ a_class [ "creet" ] ] [] in
    {
      elt;
      speed = 1.0;
      top = 0.;
      left = 0.;
      state = Healthy;
    }
end

type playground = {
  global_speed : float ref;
  mutable creets : creet list;
}

(* =========================== *)
(* ======   CLIENT   ========= *)
(* =========================== *)

[%%client]
open Js_of_ocaml

let _add_creet (pg : playground) =
  let c = Creet.create pg.global_speed in
  (* insertion visuelle dans le conteneur partagé *)
  Html.Manip.appendChild ~%playground_elt c.elt;
  pg.creets <- c :: pg.creets

let play () =
  Random.self_init ();
  let pg = { global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do
    _add_creet pg
  done

(* lancer play() au chargement de la page *)
let () =
  Dom_html.window##.onload := Dom_html.handler (fun _ ->
    play (); Js._false)

(* =========================== *)
(* ======   SERVER   ========= *)
(* =========================== *)

[%%server]

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

let page =
  Html.F.(body [
    h1 [txt "h42n42"];
    div ~a:[ a_class ["gameboard"]] [
      div ~a:[ a_class ["river"] ] [];
      playground_elt;  (* pas de ~% côté serveur *)
      div ~a:[ a_class ["hospital"] ] [];
    ];
  ])

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"h42n42"
            ~css:[["css"; "h42n42.css"]]
            page))
