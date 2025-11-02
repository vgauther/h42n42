[%%server
open Eliom_lib

module Html  = Eliom_content.Html
module Tools = Eliom_tools

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

(* Contenu du body : liste d'éléments Html.D *)
let body_content =
  Html.D.
    [ h1 [ pcdata "h42n42" ];
      div ~a:[ a_class [ "gameboard" ] ] [
        div ~a:[ a_class [ "river" ] ] [];
        Playground.elt; (* Assure-toi que Playground.elt est bien un Html.D.elt *)
        div ~a:[ a_class [ "hospital" ] ] [];
      ];
    ]

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       (* force l’inclusion du JS client + lance play() *)
       let _ = [%client (Playground.play () : unit)] in
       Lwt.return
         (Tools.D.html               (* Variante D, cohérente avec Html.D *)
            ~title:"h42n42"
            ~css:[ ["css"; "h42n42.css"] ]
            body_content))
]
