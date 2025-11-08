[%%client
open Js_of_ocaml
open Lwt
open Lwt.Infix
open Js_of_ocaml_lwt
open Eliom_content.Html
open Eliom_content.Html.D
open Eliom_content.Html.To_dom

    let () =  
    Dom_html.window##.onload := Dom_html.handler (fun _ ->
        Js_of_ocaml.Firebug.console##log (Js.string "Hello depuis OCaml !");
        Js._false
    )
]