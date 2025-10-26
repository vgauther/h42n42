(* h42n42/h42n42.eliom *)
open Eliom_content.Html.D

(* ---------- Page HTML ---------- *)
let page () () =
  let msg = span ~a:[a_id "msg"] [txt "Bonjour 👋 — clique sur ce texte !"] in
  Lwt.return
    (html
       (head
          (title (txt "Test Eliom + js_of_ocaml + Lwt"))
          [
            (* CSS : servi depuis le <static dir="..."> à la racine *)
            link ~rel:[`Stylesheet] ~href:(Xml.uri_of_string "/css/h42n42.css") ();
            (* JS généré par js_of_ocaml (client) : servi par Eliom sous /eliom/... *)
            script ~a:[a_defer (); a_src (Xml.uri_of_string "/eliom/h42n42.js")] (txt "");
          ])
       (body [div ~a:[a_class ["container"]] [msg]]))

(* ---------- Enregistrement du service (évite les soucis de types) ---------- *)
let () =
  Eliom_registration.Html.register_service
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    page

(* ---------- Code client (js_of_ocaml + Lwt) ---------- *)
let%client _ =
  let open Js_of_ocaml in
  let open Js_of_ocaml_lwt in
  Lwt.async (fun () ->
    (* Attendre que le DOM soit prêt *)
    let%lwt _ = Lwt_js_events.onload () in

    (* Logs protégés si console absente *)
    let log s = try Firebug.console##log (Js.string s) with _ -> () in
    let err s = try Firebug.console##error (Js.string s) with _ -> () in

    log "[h42n42] JS chargé (onload OK)";
    match Dom_html.getElementById_opt "msg" with
    | None ->
        err "[h42n42] Élément #msg introuvable";
        Lwt.return_unit
    | Some elt ->
        log "[h42n42] Handler cliqué attaché à #msg";
        Lwt_js_events.clicks elt (fun _ev _target ->
          log "[h42n42] Clic → toggle .alt";
          ignore (elt##.classList##toggle (Js.string "alt"));
          Lwt.return_unit)
  );
  Lwt.return_unit
