local

fun find_delete (removed, _, []) = (removed, [])
  | find_delete (removed, y, x::xs) = 
    if y=x then
       find_delete(true, y, xs)
    else
       let
           val (r, l) = find_delete(removed, y, xs)
       in
            (r, x::l)
       end;

in

fun collect_singles [] = []
  | collect_singles (x::xs) =
    let
    	val (removed, l) = find_delete(false, x, xs)
    in
        if removed then collect_singles(l)
	           else x::collect_singles(l)
    end

end;

collect_singles([1,1,2,1,1,2,3,3]);
collect_singles([1,2,1,1,2,3,1,2,7,1,1,2,8,3,1]);
