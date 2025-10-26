(* =========================== *)
(* === PARTIE COMMUNE ======== *)
(* =========================== *)

[%%shared]
open Eliom_lib
open Eliom_content
open Html.D

(* Type du paramètre utilisé pour l'appel client → serveur *)
let count_service =
  Eliom_service.create
    ~path:(Eliom_service.Path ["count"])
    ~meth:(Eliom_service.Post (Eliom_parameter.unit, Eliom_parameter.int))
    ()

(* Le compteur est stocké côté serveur *)
let counter = ref 0

(* =========================== *)
(* === PARTIE SERVEUR ======== *)
(* =========================== *)

[%%server]

(* Enregistrement de l'application *)
module Simple_app = Eliom_registration.App (struct
  let application_name = "simple_app"
  let global_data_path = None
end)

(* Service principal : la page d'accueil *)
let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

(* Contenu HTML principal *)
let main_page =
  body [
    h1 [txt "Exemple Eliom avec client/serveur"];
    p ~a:[a_id "count-text"] [txt "Compteur : 0"];
    button ~a:[a_id "inc-btn"; a_class ["button"]] [txt "Incrémenter"];
  ]

(* Handler du service /count *)
let () =
  Simple_app.register
    ~service:count_service
    (fun () () ->
       (* Incrémentation côté serveur *)
       incr counter;
       let new_val = !counter in
       (* Réponse envoyée au client *)
       Lwt.return new_val)

(* Handler du service principal "/" *)
let () =
  Simple_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"Démo Eliom"
            ~css:[["css"; "main.css"]]
            main_page))

(* =========================== *)
(* === PARTIE CLIENT ========= *)
(* =========================== *)

[%%client]
open Js_of_ocaml
open Js_of_ocaml_lwt

(* Fonction exécutée côté navigateur *)
let () =
  let btn   = Js.Opt.get (Dom_html.document##getElementById (Js.string "inc-btn"))
                (fun () -> failwith "Bouton introuvable") in
  let count_text = Js.Opt.get (Dom_html.document##getElementById (Js.string "count-text"))
                (fun () -> failwith "Texte introuvable") in

  let handler (_:Dom_html.mouseEvent Js.t) =
    (* Appel AJAX vers le service serveur *)
    Lwt.async (fun () ->
      Eliom_client.call
        ~service:count_service
        () ()
      >>= fun new_val ->
      (* Mise à jour du texte DOM avec la nouvelle valeur *)
      count_text##.textContent := Js.some (Js.string (Printf.sprintf "Compteur : %d" new_val));
      Lwt.return_unit);
    Js._true
  in
  btn##.onclick := Dom_html.handler handler
