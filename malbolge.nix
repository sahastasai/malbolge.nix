# TODO: Migrate all char usages to int
# TODO: rewrite memory structure to be attribute-set based
{ pkgs, lib, path ? ./main.mb, ... }: let
  malbolgeLength = 59049;
  stdout = x : builtins.trace "output: ${x}";
  # stdout = x: let
#	scriptFile = pkgs.writeTextFile {name="out"; executable=true; destination="/bin/out"; text=''#!/usr/bin/env bash
 # echo ${toString x};'';};
#	in 
#	pkgs.runCommand "capture-stdout" {} ''
#		${scriptFile}/bin/out > $out
#	'';
  filein = x: (builtins.readFile x);
  fileinChars = x: builtins.stringToCharacters (filein x);
  fileinInts = x: map lib.strings.charToInt (fileinChars x);
  fileinCharsNoSpace = x: builtins.filter (y: y != " " && y != "\n" && y != "\t" && y != "\r") (fileinChars x);
  fileinIntsNoSpace = x: map lib.strings.charToInt (fileinCharsNoSpace x); # use EVERYWHERE
  mem = builtins.genList(x : { a = false; b = false; }) malbolgeLength;
  stdin_path = "./stdin.txt"; # add to function call eventually
  stdin_parsed = fileinInts stdin_path;
  fileLength = builtins.length (fileinCharsNoSpace path); # use EVERYWHERE
  rawFileLength = builtins.length (fileinChars path);
  initialMemory = builtins.genList(i : (if i < fileLength then (builtins.elemAt (fileinIntsNoSpace path) i) else 0)) malbolgeLength;
  transformedMemory = lib.lists.imap0 (i : v : if i < fileLength then v else (op (builtins.elemAt transformedMemory (i - 1)) (builtins.elemAt transformedMemory (i - 2)))) initialMemory;
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
    intValue: c:
    let
      index = lib.trivial.mod (intValue - 33 + c) 94;
    in
    builtins.elemAt xlat1List index;
  # determine element at index 1-94 for xlat2
  mutate = intValue: (builtins.elemAt xlat2List (intValue - 33)); # fixes one character string addition to memory
  pvm = index : builtins.elemAt (lib.lists.imap0 (i : v : if v > 33 && v < 127 then (decode v i) else 0) (fileinIntsNoSpace path)) index; # potentially problematic line 
    validMap = lib.lists.imap0 (i : v : ((pvm i) == "j" || (pvm i) == "i" || (pvm i) == "*" || (pvm i) == "p" || (pvm i) == "<" || (pvm i) == "/" || (pvm i) == "v" || (pvm i) == "o")) (builtins.genList (i : i) fileLength); # this line could use some cleaning. using `fileLength` everywhere 
  # checks if the file is valid
  validFile = builtins.foldl' (acc: x: acc && x) true validMap;

   # begin op fn
  # powers of 9 arr
  p9 = [ 1 9 81 729 6561 ];

  # lookup table determining base9 digit from input, base9 to represent 2 trits
  o = [ 
  4 3 3 1 0 0 1 0 0 
  4 3 5 1 0 2 1 0 2 
  5 5 4 2 2 1 2 2 1
  4 3 3 1 0 0 7 6 6 
  4 3 5 1 0 2 7 6 8 
  5 5 4 2 2 1 8 8 7 
  7 6 6 7 6 6 4 3 3 
  7 6 8 7 6 8 4 3 5
  8 8 7 8 8 7 5 5 4 
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

 # begin exec 
  
  exec = state@{ a, c, d, mem, out, instream }:
    let 
      memc = builtins.elemAt mem c;      
      isValid = memc >= 33 && memc <= 126;
      cmd = if isValid then decode memc c else -1;
    in  
      if !isValid then
  	throw "invalid memory value ${toString memc} at C=${toString c}"
      # Integers are required 
      else if cmd == 118 then 
	builtins.break(stdout out) # breakpoint
      else 
	let
	  memd = builtins.break (builtins.elemAt mem d); # breakpoint added for debugging purposes 
	  
	  step = 
	    if cmd == 106 then { d = memd; }
	    else if cmd == 105 then { c = memd; }
	    else if cmd == 42 then 
	      let 
		rot = (memd / 3) + ((lib.trivial.mod memd 3) * 19683);
	      in
		{a = rot; mem = lib.lists.replaceElemAt mem d rot;}
	    else if cmd == 112 then 
	      let 
		res = op a memd;
	      in 
		{a = res; mem = lib.lists.replaceElemAt mem d res;}
	    else if cmd == 60 then {out = out + (lib.strings.charFromInt (lib.trivial.mod a 256));}
	    else if cmd == 47 then 
	      if instream < builtins.length stdin_parsed then { 
		a = builtins.break(builtins.elemAt stdin_parsed instream); # breakpoint
		instream = instream + 1;
	      } else {
		a = 59048;
	      }
	    else {};

	  # prepare next iteration
	  nextA = step.a or a;
	  nextOut = step.out or out;
	  nextInstream = step.instream or instream;	  
	  baseMem = step.mem or mem;
#	  postMem = lib.lists.replaceElemAt baseMem c (mutate memc); # remember: [ mutate memc ] -> (mutate memc). The first is list insertion
	  # modulo resets value to 0 when limit is reached
	  postC = step.c or c;
	  postD = step.d or d;
	  
	  encryptValue = builtins.elemAt baseMem postC;
	  nextMem = if encryptValue >= 33 && encryptValue <= 126 then lib.lists.replaceElemAt baseMem postC (mutate encryptValue) else baseMem; 
	  nextC = lib.trivial.mod (postC + 1) malbolgeLength;
	  nextD = lib.trivial.mod (postD + 1) malbolgeLength;
	in 
	  exec { a = nextA; c = nextC; d = nextD; mem = nextMem; out = nextOut; instream = nextInstream; }
	  
      # end exec
	
in {

  inherit op;
  inherit exec;
  p = exec {
	a = 0; 
	c = 0; 
	d = 0; 
	mem = transformedMemory; 
	out = ""; 
	instream = 0;
  };  
}
