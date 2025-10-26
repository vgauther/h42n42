(* h42n42/h42n42.eliom *)
open Eliom_content.Html.D

(* --------- Données côté serveur --------- *)
let message_from_ocaml =
  "Bonjour 👋 — clique sur ce texte pour changer la couleur !"

let css_link =
  link ~rel:[`Stylesheet]
       ~href:(Xml.uri_of_string "/css/h42n42.css")
       ()

(* --------- Service principal ("/") --------- *)
let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* La page *)
let page () () =
  let msg = span ~a:[a_id "msg"] [txt message_from_ocaml] in
  Lwt.return
    (html
       (head (title (txt "H42N42 — Demo couleur")) [css_link])
       (body [div ~a:[a_class ["container"]] [msg]]))

(* Enregistrement du service *)
let () =
  Eliom_registration.Html.register
    ~service:main_service
    page

(* --------- Code client (JS) --------- *)
let%client _ =
  let open Js_of_ocaml in
  let open Js_of_ocaml_lwt in
  let elt = Dom_html.getElementById_exn "msg" in
  Lwt.async (fun () ->
    Lwt_js_events.clicks elt (fun _ev _target ->
      ignore (elt##.classList##toggle (Js.string "alt"));
      Lwt.return_unit));
  Lwt.return_unit
