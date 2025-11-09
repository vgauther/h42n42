[%%client

type creet_kind = Healthy | Sick | Berserk | Mean

let color_of_kind = function
  | Healthy -> "green"
  | Sick -> "orange"
  | Berserk -> "purple"
  | Mean -> "red"

type creet = {
    mutable id : int;
    mutable kind : creet_kind;
    mutable speed : float;
    mutable pos_x : float;
    mutable pos_y : float;
    mutable dir : float;  (* angle en radians *)
}

type game_state = {
    mutable duration : int; (* current timestamp in ms *)
    mutable started_at_timestamp : int; (* game start timestamp in ms *)
    mutable last_time_creet_spawn : int; (* since when the last creet was spawned *)
    mutable last_time_speed_increase : int; (* since when the speed was increased *)
    mutable speed : float;
    mutable nb_healthy_creet : int;
    mutable creets : creet list;
    mutable playing : bool;
}
]