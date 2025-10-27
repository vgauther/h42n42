(* =========================== *)
(* ======   SHARED   ========= *)
(* =========================== *)

[%%shared]
open Eliom_lib
open Eliom_content
open Html.D

type creet_state = Healthy | Sick | Berserk | Mean

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
    div ~a:[a_class ["gameboard"]] [
      div ~a:[a_class ["river"]] [];
      (* IMPORTANT: ID playground pour le client *)
      div ~a:[a_class ["playground"]; a_id "playground"] [];
      div ~a:[a_class ["hospital"]] [];
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

(* =========================== *)
(* ======   CLIENT   ========= *)
(* =========================== *)

[%%client]
open Js_of_ocaml

(* Record de la créature: uniquement côté client (DOM requis) *)
type creet = {
  elt      : Html_types.div elt;              (* noeud TyXML *)
  dom_elt  : Dom_html.divElement Js.t;        (* noeud DOM réel *)
  mutable speed : float;
  mutable top   : float;
  mutable left  : float;
  mutable state : creet_state;
}

module Creet = struct
  let create (_global_speed : float ref) : creet =
    let elt = div ~a:[a_class ["creet"]] [] in
    let dom_elt = Eliom_content.Html.To_dom.of_div elt in
    { elt; dom_elt; speed = 1.0; top = 0.; left = 0.; state = Healthy }
end

type playground = {
  container    : Dom_html.element Js.t;
  global_speed : float ref;
  mutable creets : creet list;
}

let by_id_exn (id:string) : Dom_html.element Js.t =
  Js.Opt.get (Dom_html.document##getElementById (Js.string id))
    (fun () -> failwith ("#id introuvable: "^id))

let _add_creet (pg:playground) : unit =
  let c = Creet.create pg.global_speed in
  (* Ajout DOM côté client: PAS de ~%elt côté serveur *)
  Dom.appendChild pg.container (c.dom_elt :> Dom.node Js.t);
  pg.creets <- c :: pg.creets

let play () : unit =
  let container = by_id_exn "playground" in
  let pg = { container; global_speed = ref 0.; creets = [] } in
  for _ = 1 to 3 do
    _add_creet pg
  done

(* Lance automatiquement play() au chargement *)
let () =
  Dom_html.window##.onload := Dom_html.handler (fun _ ->
    play (); Js._false)
