fun prefix ([],  _) = true
  | prefix ( _, []) = false
  | prefix (x::xs, y::ys) = (x=y) andalso prefix(xs,ys);

(*
prefix([], [1,2,3]);
prefix([1,2], []);
prefix([1,2,3,4,5,6], [1,2,3]);
prefix([1,2,3], [1,2,3,4,5]);
prefix([1,4,3,4,5,6], [1,2,3]);
*)
