fun collect_dup  [] = []
  | collect_dup [_] = []
  | collect_dup (x::xs) =
  let
  	fun remove(_, []) = []
  	  | remove(y, x::xs) =
	  	if (x=y) then remove(y, xs)
		         else x::remove(y, xs)
	
	fun exists(_, []) = false
	  | exists(y, x::xs) =
	  	if (x=y) then true
		         else exists(y, xs)
  in
  	if exists(x, xs) then
		x::collect_dup( remove(x, xs) )
	else
		collect_dup(xs)
  end;


(*
collect_dup([1,2,3,4,5]);
collect_dup([1,2,1,1,2,3,4,1]);
*)
