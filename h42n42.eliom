[%%shared
open Eliom_lib
open Eliom_content
open Html.D
open Tyxml
]

module H42n42_app =
  Eliom_registration.App (
  struct
    let application_name = "h42n42"
    let global_data_path = None
  end)

let main_service =
  Eliom_service.create
    ~path:(Eliom_service.Path [])
    ~meth:(Eliom_service.Get Eliom_parameter.unit)
    ()

let game_page =
  div ~a:[a_class ["game-container"] ; a_id "game-container"] [
    div ~a:[a_class ["river"] ; a_id "river"] [];
    div ~a:[a_class ["hospital"] ; a_id "hospital"] [];
  ]

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
      Lwt.return
      (Eliom_tools.F.html
         ~title:"H42N42"
         ~css:[["css";"h42n42.css"]]
         (body [game_page])))