{
  pkgs,
  lib,
  ...
}:
let
  malbolgeLength = 59048;
  stdout = x: builtins.trace "${toString x}" x;
  filein = x: (builtins.readFile x);
  fileinChars = x: builtins.stringToCharacters (filein x);
  fileinInts = x: map (y: lib.strings.charToInt y) (fileinChars x);
  fileinCharsNoSpace = x: builtins.filter (y: y != " ") (fileinChars x);
  fileinIntsNoSpace = x: map (y: lib.strings.charToInt y) (fileinCharsNoSpace x);
  mem = builtins.genList (x: {
    a = false;
    b = false;
  }) malbolgeLength;
  path = "./main.mb";
  stdin_path = "./stdin.txt";
  # main.mbstdin is a stdin replicator
  stdin_parsed = fileinInts stdin_path;
  fileLength = builtins.stringLength (fileinCharsNoSpace path);
  rawFileLength = builtins.stringLength (fileinChars path);
  initialMemory = builtins.genList (
    i: (if i < fileLength then (builtins.elemAt (fileinIntsNoSpace path) i) else 0)
  ) malbolgeLength;
  transformedMemory = lib.lists.imap0 (
    i: v:
    if i < fileLength then
      v
    else
      (op (builtins.elemAt transformedMemory (i - 1)) (builtins.elemAt transformedMemory (i - 2)))
  ) initialMemory;
  xlat1 =
    "+b(29e*j1VMEKLyC})8&m#~W>qxdRp0wkrUo[D7,XTcA\"lI"
    + ".v%{gJh4G\\-=O@5`_3i<?Z';FNQuY]szf$!BS/|t:Pn6^Ha";
  xlat2 =
    "5z]&gqtyfr$(we4{WP)H-Zn,[%\\3dL+Q;>U!pJS72FhOA1C"
    + "B6v^=I_0/8|jsb9m<.TVac`uY*MK'X~xDl}REokN:#?G\"i@";
  # create character arrays
  xlat1List = builtins.stringToCharacters xlat1;
  xlat2List = builtins.stringToCharacters xlat2;
  # determine element at index 1-94 for xlat1
  decode =
    charValue: c:
    let
      index = lib.trivial.mod (charValue - 33 + c) 94;
    in
    builtins.elemAt xlat1List index;
  # determine element at index 1-94 for xlat2
  mutate = charValue: builtins.elemAt xlat2List (charValue - 33);
  pvm =
    index:
    builtins.elemAt (lib.lists.imap0 (i: v: if v > 33 && v < 127 then (decode v i) else 0) (
      fileinChars path
    )) index; # is 0 messing us up?
  validMap = lib.lists.imap0 (
    i: v:
    (
      (pvm i) == "j"
      || (pvm i) == "i"
      || (pvm i) == "*"
      || (pvm i) == "p"
      || (pvm i) == "<"
      || (pvm i) == "/"
      || (pvm i) == "v"
      || (pvm i) == "o"
    )
  ) (builtins.genList (i: i) rawFileLength);
  # checks if the file is valid
  validFile = builtins.foldl' (acc: x: acc && x) true validMap;
  # a, c, d storage
  acid = [
    0
    0
    0
  ];
  # TODO: write exec function

  # begin op fn
  # powers of 9 arr
  p9 = [
    1
    9
    81
    729
    6561
  ];

  # lookup table determining base9 digit from input, base9 to represent 2 trits
  o = [
    4
    3
    3
    1
    0
    0
    1
    0
    0
    4
    3
    5
    1
    0
    2
    1
    0
    2
    5
    5
    4
    2
    2
    1
    2
    2
    1
    4
    3
    3
    1
    0
    0
    7
    6
    6
    4
    3
    5
    1
    0
    2
    7
    6
    6
    4
    3
    5
    1
    0
    2
    7
    6
    8
    5
    5
    4
    2
    2
    1
    8
    8
    7
    7
    6
    6
    7
    6
    6
    4
    3
    3
    7
    6
    8
    7
    6
    8
    4
    3
    5
    8
    8
    7
    8
    8
    7
    5
    5
    4
  ];

  # actual crazy op; convert digit to base9 using lut
  op =
    x: y:
    builtins.foldl' (
      acc: p:
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
  # inherit exec;
}
