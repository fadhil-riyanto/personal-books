(*
	Liczby s³abo rosn±ce
	a_1, a_2, a_3,..., an gdzie a_2 >= a_1, a_3 >= a_2, ..., a_n >= a_n-1
 *)

fun isok []      = true
 |  isok (x::xs) =
 	let
		fun helper(_,       []) = true
		 |  helper(prev, x::xs) =
			if prev > x then
				false
			else
				helper(x, xs)
	in
		helper(x, xs)
	end;

fun insert (v, []) = [v]
 |  insert (v, x::xs) =
 	if v >= x then
		x::insert(v, xs)
	else
		v::x::xs;
		

fun merge ([],  b) = b
 |  merge ( a, []) = a
 |  merge ( a,  b) =
	let
		fun helper (   [], b) = b
		 |  helper (x::xs, b) =
			helper(xs, insert(x, b));
	in
		helper(a, b)
	end;
