{ pkgs ? import <nixpkgs> {},
  name,
}:

 with import ../. {};

let
  abs = root: p: "${toString root}/${p}";
  src = abs ./. name;
  ignorefile = abs src "ignorefile";
  src' = gitIgnoreSourceFile { inherit src ignorefile; };
in pkgs.runCommand "gis-test-run-${name}" {} ''
  (cd ${src'} && find *) | sort > $out
''
