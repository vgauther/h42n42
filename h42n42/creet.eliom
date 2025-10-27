[%%shared]
open Eliom_lib
open Eliom_content
open Html.D

type creet_state = Healthy | Sick | Berserk | Mean

type creet = {
  elt : Html_types.div elt;
  mutable speed : float;
  mutable top : float;
  mutable left : float;
  mutable state : creet_state;
}

[%%client]
module Creet = struct
  let create (_global_speed : float ref) : creet =
    let elt = div ~a:[ a_class [ "creet" ] ] [] in
    { elt; speed = 1.0; top = 0.; left = 0.; state = Healthy }
end
