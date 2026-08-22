let
  # our beloved lookup tables
  xlat1 =
    "+b(29e*j1VMEKLyC})8&m#~W>qxdRp0wkrUo[D7,XTcA\"lI"
    + ".v%{gJh4G\\-=O@5`_3i<?Z';FNQuY]szf$!BS/|t:Pn6^Ha";

  xlat2 =
    "5z]&gqtyfr$(we4{WP)H-Zn,[%\\3dL+Q;>U!pJS72FhOA1C"
    + "B6v^=I_0/8|jsb9m<.TVac`uY*MK'X~xDl}REokN:#?G\"i@";

  # create character arrays
  xlat1List = builtins.stringToCharacters xlat1;
  xlat2List = builtins.stringToCharacters xlat2;

  decode =
    charValue: c:
    let
      index = builtins.mod (charValue - 33 + c) 94;
    in
    builtins.elemAt xlat1List index;

  mutate = charValue: builtins.elemAt xlat2List (charValue - 33);
in
{
  inherit decode mutate;
}
