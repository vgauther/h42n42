[%%shared
module Html  = Eliom_content.Html
module Tools = Eliom_tools
]

[%%client
module Playground = struct
  (* Initialisation côté client, appelée depuis le serveur via [%client]. *)
  let play () : unit = ()
end
]

[%%server

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

(* Élément placeholder manipulé côté client *)
let playground_elt =
  Html.D.div ~a:[ Html.D.a_id "playground" ] []

(* Corps de page *)
let body_content =
  Html.D.body [
    Html.D.h1 [ Html.D.txt "h42n42" ];
    Html.D.div ~a:[ Html.D.a_class [ "gameboard" ] ] [
      Html.D.div ~a:[ Html.D.a_class [ "river" ] ] [];
      playground_elt;
      Html.D.div ~a:[ Html.D.a_class [ "hospital" ] ] [];
    ];
  ]

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       let _ = [%client (Playground.play () : unit)] in
       Lwt.return
         (Tools.D.html
            ~title:"h42n42"
            ~css:[ ["css"; "h42n42.css"] ]
            body_content))
]
