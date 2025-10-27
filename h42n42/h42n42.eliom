[%%shared]
open Eliom_lib
open Eliom_content
open Html.D


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

let () =
  H42n42_app.register
    ~service:main_service
    (fun () () ->
       Lwt.return
         (Eliom_tools.F.html
            ~title:"h42n42"
            ~css:[["css";"h42n42.css"]]
            Html.F.(body [
              h1 [txt "h42n42"];
              div ~a:[ a_class["gameboard"]] [
                div ~a:[a_class ["river"]] [];
                div ~a:[ a_class [ "playground" ] ] [];
                div ~a:[ a_class [ "hospital" ] ] [];
              ];
            ])))

  type creet_state = Healthy | Sick | Berserk | Mean

  type creet = {
    elt : Html_types.div elt;
    mutable speed : float;
    mutable top : float;
    mutable left : float;
    mutable state: creet_state;
  }

  let create global_speed =
    let elt = div ~a:[ a_class [ "creet" ] ] [] in
    let creet =
      {
        elt;
        top = 0.;
        left = 0.;
        state = Healthy;
      }
    creet

  let _add_creet playground =
    let creet = Creet.create playground.global_speed in
    Html.Manip.appendChild ~%elt creet.elt;
    playground.creets <- creet :: playground.creets;

  let play () =
    let playground =
      { global_speed = ref 0.; creets = [] }
    in
    for _ 1 to 3 do
      _add_creet playground
    done;
