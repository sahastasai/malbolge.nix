let

# powers of 9 arr
p9 = [ 1 9 81 729 6561 ];

# lookup table determining base9 digit from input, base9 to represent 2 trits
o = [ 
  4 3 3 1 0 0 1 0 0 4 
  3 5 1 0 2 1 0 2 5 5 
  4 2 2 1 2 2 1 4 3 3 
  1 0 0 7 6 6 4 3 5 1 
  0 2 7 6 6 4 3 5 1 0 
  2 7 6 8 5 5 4 2 2 1 
  8 8 7 7 6 6 7 6 6 4 
  3 3 7 6 8 7 6 8 4 3 
  5 8 8 7 8 8 7 5 5 4 ];

# actual crazy op; convert digit to base9 using lut
op = x: y:
  builtins.foldl'
    (acc: p:
      let
        oy = (y / p) - ((y / p) / 9) * 9;
        ox = (x / p) - ((x / p) / 9) * 9;
        result = builtins.elemAt o (oy * 9 + ox);
      in
      acc + (result * p)
    ) 0 p9;
in 
{
  inherit op;
  example = op 0 0; 
}
