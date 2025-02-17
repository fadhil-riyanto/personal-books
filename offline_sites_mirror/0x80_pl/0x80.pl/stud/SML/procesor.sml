load "List";
load "Math";

fun get(l,i) = List.nth(l,i-1)
fun put(l,i,x) = List.take(l,i-1) @ ( x:: List.drop(l,i) )

fun zeros(0) = []
  | zeros(i) = 0.0::zeros(i-1);

(*
	A - akumulator
	M - pamiec (tablica)
*)
datatype instrukcja = 
	ADD of int	(* akum := akum + pamiec[i] *)
|	SUB of int	(* and so on *)
|	MULT of int
|	DIV of int
|	SQRT
|	SET of real	(* akum := x *)
|	LOAD of int	(* akum := pamiec[i] *)
|	STORE of int;	(* pamiec[i] := akum *)

fun exec(ADD i, (akum, RAM))	= (akum + get(RAM, i), RAM)
  | exec(SUB i, (akum, RAM))	= (akum - get(RAM, i), RAM)
  | exec(MULT i, (akum, RAM))	= (akum * get(RAM, i), RAM)
  | exec(DIV i, (akum, RAM))	= (akum / get(RAM, i), RAM)
  | exec(SQRT, (akum, RAM))	= (Math.sqrt akum, RAM)
  | exec(SET x, (_, RAM))	= (x, RAM)
  | exec(LOAD i, (_, RAM))	= (get(RAM, i), RAM)
  | exec(STORE i, (akum, RAM))	= (akum, put(RAM, i, akum));
 
fun run(prog, (akum, RAM)) = List.foldl exec (akum, RAM) prog

(* przyk³adowy program *)
val prog = [
	SET 5.0,
	STORE 1,
	MULT  1, (* RAM[1] = 5*5 *)
	STORE 1,
	SET 4.0,
	STORE 2,
	MULT  2, (* akum = 4*4 *)
	ADD   1, (* akum = 4*4 + 5*5 *)
	SQRT	 (* akum ~= 6.403 *)
];

run(prog, (0.0, zeros(10)));
