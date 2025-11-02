[%%shared
module Html  = Eliom_content.Html
module Tools = Eliom_tools
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

let body_content =
  Html.D.body [
    Html.D.h1 [ Html.D.txt "h42n42" ];
    Html.D.div ~a:[ Html.D.a_class [ "gameboard" ] ] [
      Html.D.div ~a:[ Html.D.a_class [ "river" ] ] [];
      Playground.elt;  (* IMPORTANT: élément partagé, identique côté client *)
      Html.D.div ~a:[ Html.D.a_class [ "hospital" ] ] [];
    ];
  ]

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       (* Injection explicite du code client + exécution *)
       let _ = [%client (Playground.play () : unit)] in
       Lwt.return
         (Tools.D.html
            ~title:"h42n42"
            ~css:[ ["css"; "h42n42.css"] ]   (* attendu sous static/css/h42n42.css *)
            body_content))
]
