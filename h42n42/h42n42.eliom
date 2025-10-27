[%%server]
open Eliom_lib
open Eliom_content
open Html.D

(* ----------------------------- *)
(* Application principale Eliom  *)
(* ----------------------------- *)
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

(* ----------------------------- *)
(* Page HTML renvoyée au client  *)
(* ----------------------------- *)
let page =
  Html.F.(body [
    h1 [ txt "h42n42" ];
    div ~a:[ a_class [ "gameboard" ] ] [
      div ~a:[ a_class [ "river" ] ] [];
      Playground.elt;  (* ← conteneur partagé du jeu *)
      div ~a:[ a_class [ "hospital" ] ] [];
    ];
  ])

(* ----------------------------- *)
(* Enregistrement du service     *)
(* ----------------------------- *)
let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       (* Lancement automatique de la fonction play côté client *)
       let _ = [%client (Playground.play () : unit)] in
       Lwt.return
         (Eliom_tools.F.html
            ~title:"h42n42"
            ~css:[ ["css"; "h42n42.css"] ]
            page))
