(* h42n42/h42n42.eliom *)
open Eliom_content.Html5.D

(* --------- Données côté serveur (le texte vient d'OCaml) --------- *)
let message_from_ocaml = "Bonjour 👋 — clique sur ce texte pour changer la couleur !"

(* Petit helper pour lier notre CSS statique *)
let css_link =
  link ~rel:[`Stylesheet]
       ~href:(Xml.uri_of_string "/h42n42/static/css/app.css")
       ()

(* --------- Service principal (HTML généré côté serveur) --------- *)
let main_service =
  Eliom_registration.Html5.register
    ~path:[]
    ~get_params:Eliom_parameter.unit
    (fun () ->
      let msg = span ~a:[a_id "msg"] [pcdata message_from_ocaml] in
      Lwt.return
        (html
           (head (title (pcdata "H42N42 — Demo couleur")) [css_link])
           (body [div ~a:[a_class ["container"]] [msg]])))

(* --------- Code client : écoute le clic et toggle une classe CSS --------- *)
let%client _ =
  let open Js_of_ocaml in
  let elt = Dom_html.getElementById_exn "msg" in
  (* on branche un handler de clic en Lwt *)
  Lwt.async (fun () ->
      Lwt_js_events.clicks elt (fun _evt _target ->
          ignore (elt##.classList##toggle (Js.string "alt"));
          Lwt.return_unit));
  Lwt.return_unit
