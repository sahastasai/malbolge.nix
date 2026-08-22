let
  p9 = [ 1 9 81 729 6561 ];

  # 9x9 truth table flattened (Row = y digit, Column = x digit)
  oTable = [
    4 3 3  1 0 0  1 0 0
    4 3 5  1 0 2  1 0 2
    5 5 4  2 2 1  2 2 1
    4 3 3  1 0 0  7 6 6
    4 3 5  1 0 2  7 6 8
    5 5 4  2 2 1  8 8 7
    7 6 6  7 6 6  4 3 3
    7 6 8  7 6 8  4 3 5
    8 8 7  8 8 7  5 5 4
  ];

  op = x: y:
    builtins.foldl' (acc: p:
      let
        digitY = builtins.mod (y / p) 9;
        digitX = builtins.mod (x / p) 9;
        resultDigit = builtins.elemAt oTable (digitY * 9 + digitX);
      in
        acc + (resultDigit * p)
    ) 0 p9;
in
{
  inherit op;

  # Example test: op 0 0 evaluates to 29524
  example = op 0 0;
}
