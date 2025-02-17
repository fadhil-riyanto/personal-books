(*
  
  Operacje na listach w SML-u

  Wojciech Mu³a
  
  $Revision: 1.1.1.1 $
  $Date: 2006-04-03 18:20:35 $

*)

infix @

fun      [] @ ys = ys
 |  (x::xs) @ ys = x::(xs @ ys)

fun rev      [] = []
 |  rev (x::xs) = rev xs @ [x];

fun length      [] = 0
 |  length (x::xs) = 1 + length xs;

fun maxint	[] = raise Empty
 |  maxint (x::xs) = 
 	let
		fun max(m, [])    = m
		 |  max(m, x::xs) = 
		 	if (m > x) then max(m, xs)
			           else max(x, xs)
	in
		max(x, xs)
	end;

fun map (_, [])      = []
 |  map (f, (x::xs)) = f(x)::map(f,xs);

fun null l = l=nil;

fun head     [] = raise Empty
 |  head (x::_) = x;

fun tail      [] = raise Empty
 |  tail (_::xs) = xs;

fun nth (l, n) = 
	let
		fun helper(_,    []) = raise Subscript
		 |  helper(k, x::xs) = if (k=n) then x else helper(k+1, xs)
	in
		if (n < 0)
		then
			raise Subscript
		else
			helper(0, l)
	end;

fun last []      = raise Empty
 |  last [x]     = x
 |  last (x::xs) = last(xs);

fun take ([],_) = []
 |  take ( l,n) =
 	let
		fun helper(_, [])    = raise Subscript
		 |  helper(k, x::xs) = 
		 	if k < n then
				x::helper(k+1, xs)
			else
				[]
	in
		helper(0, l)
	end;

fun drop ([],_) = []
 |  drop ( l,n) =
 	let
		fun helper(_, [])    = raise Subscript
		 |  helper(k, x::xs) = 
		 	if k < n then
				helper(k+1, xs)
			else
				xs
	in
		helper(0, l)
	end;

fun concat []      = []
 |  concat (x::xs) = x @ concat(xs);

fun member (_, []) = false
 |  member (e, (x::xs)) = e=x orelse member(e,xs);

fun filter (_, []) = []
 |  filter (f, (x::xs)) = 
 	if f(x) = true then
		x::filter(f, xs)
	else
		filter(f, xs);

fun partition (f, l) =
	let 
		fun ftrue  x = f(x)=true;
		fun ffalse x = f(x)=false;
	in
		(filter(ftrue, l), filter(ffalse, l))
	end;

fun partition2 (_, []) = ([], [])
 |  partition2 (f,  l) =
	let 
		fun helper(a,b,   []) = (a,b)
		 |  helper(a,b,x::xs) = 
		 	if f(x) then
				helper(a @ [x], b, xs)
			else
				helper(a, b @ [x], xs)

	in
		helper([], [], l)
	end;

fun zip (_, []) = []
 |  zip ([], _) = []
 |  zip ((x::xs), (y::ys)) = (x,y)::zip(xs,ys);

fun unzip [] = ([], [])
 |  unzip  l = 
	let
		fun helper(a,b,   []) = (a,b)
		 |  helper(a,b,x::xs : ('a*'b) list) = 
		 	helper((#1 x)::a, (#2 x)::b, xs)
	in
		helper([], [], l)
	end;

fun foldl (_, _,    []) = raise Empty
 |  foldl (f, b,   [x]) = f(x, b)
 |  foldl (f, b, x::xs) = f(x, foldl(f,b,xs));

fun remove(_,    []) = []
 |  remove(y, x::xs) =
	if x=y then
		remove(y,xs)
	else
		x::remove(y,xs);

fun removedup      [] = []
 |  removedup (x::xs) = x::removedup(remove(x, xs));

# vim ts=8
