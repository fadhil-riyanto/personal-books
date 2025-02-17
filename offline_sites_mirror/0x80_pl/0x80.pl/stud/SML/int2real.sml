fun int2real 0 = 0.0
  | int2real 1 = 1.0
  | int2real x =
  let
  	val LSB = x mod 2
	val x2  = x div 2
  in
  	if LSB = 1 then
		1.0 + 2.0*int2real(x2)
	else
		2.0*int2real(x2)
  end;
