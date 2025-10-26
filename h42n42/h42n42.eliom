(* h42n42/h42n42.eliom *)
open Eliom_content.Html5.D

(* --------- Données côté serveur --------- *)
let message_from_ocaml =
  "Bonjour 👋 — clique sur ce texte pour changer la couleur !"

(* --------- Lien CSS (servi à la racine via <static dir=...>) --------- *)
let css_link =
  link ~rel:[`Stylesheet]
       ~href:(Xml.uri_of_string "/css/h42n42.css")
       ()

(* --------- Service principal ("/") --------- *)
let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)

(* --------- Page HTML --------- *)
let page () () =
  let msg = span ~a:[a_id "msg"] [txt message_from_ocaml] in
  Lwt.return
    (html
       (head
          (title (txt "H42N42 — Demo couleur"))
          [
            css_link;
            (* Inclure le JS client généré par Eliom/Js_of_ocaml *)
            script ~a:[a_src (Xml.uri_of_string "/eliom/h42n42.js")] (txt "");
          ])
       (body [div ~a:[a_class ["container"]] [msg]]))

(* --------- Enregistrement du service --------- *)
let () =
  Eliom_registration.Html5.register
    ~service:main_service
    page

(* --------- Code client (JS) --------- *)
let%client _ =
  let open Js_of_ocaml in
  let open Js_of_ocaml_lwt in
  Lwt.async (fun () ->
    (* Attendre que le DOM soit prêt *)
    let%lwt _ = Lwt_js_events.onload () in

    (* Helpers logs (protégés si console absente) *)
    let log s =
      try Firebug.console##log (Js.string s) with _ -> ()
    in
    let error s =
      try Firebug.console##error (Js.string s) with _ -> ()
    in

    log "[h42n42] JS chargé : onload OK";
    match Dom_html.getElementById_opt "msg" with
    | None ->
        error "[h42n42] Élément #msg introuvable";
        Lwt.return_unit
    | Some elt ->
        log "[h42n42] Handler cliqué attaché à #msg";
        Lwt_js_events.clicks elt (fun _ev _target ->
          log "[h42n42] Click détecté sur #msg → toggle .alt";
          ignore (elt##.classList##toggle (Js.string "alt"));
          Lwt.return_unit)
  );
  Lwt.return_unit
