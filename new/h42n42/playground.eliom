[%%shared
module Html = Eliom_content.Html
]

(* Élément partagé inséré côté serveur et manipulé côté client *)
[%%shared]
let elt = Html.D.div ~a:[ Html.D.a_class [ "playground" ] ] []

[%%client
let log (s : string) = Js_of_ocaml.Js.log s
]

[%%client]
let make_creet () =
  Html.D.div ~a:[ Html.D.a_class [ "creet" ] ] []

[%%client]
let play () =
  log "Playground: play() start";
  let parent = ~%elt in              (* récupère le nœud DOM réel associé à elt *)
  for _i = 1 to 12 do
    Html.Manip.appendChild parent (make_creet ())
  done;
  log "Playground: play() end"
