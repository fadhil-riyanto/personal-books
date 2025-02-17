fun remove_odd  [] = []
  | remove_odd [_] = []
  | remove_odd (_::x::xs) = x::remove_odd(xs);

(*
remove_odd [];
remove_odd [1,2];
remove_odd [1,2,3,4,5,6];
remove_odd [1,2,3];
*)
