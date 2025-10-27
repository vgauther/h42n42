[%%server
open Eliom_lib
open Eliom_content
open Html.D

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
    h1 [ txt "h42n42" ];
    div ~a:[ a_class [ "gameboard" ] ] [
      div ~a:[ a_class [ "river" ] ] [];
      Playground.elt;  (* conteneur partagé inséré dans la page *)
      div ~a:[ a_class [ "hospital" ] ] [];
    ];
  ])

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       (* Force l’inclusion du JS client et lance play() dans le navigateur *)
       let _ = [%client (Playground.play () : unit)] in
       Lwt.return
         (Eliom_tools.F.html
            ~title:"h42n42"
            ~css:[ ["css"; "h42n42.css"] ]
            page))
]
