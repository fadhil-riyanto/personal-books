fun intpow (x, 1) = x
  | intpow (x, n) =
    if n mod 2 = 1 then
    	x * intpow(x*x, n div 2)
    else
    	intpow(x*x, n div 2);

intpow(2, 20)
