{ pkgs ? import <nixpkgs> {} }:
let
  inherit (builtins) trace match replaceStrings substring readFile getEnv;
  inherit (pkgs.lib) stringLength filter removePrefix optionalString splitString
     any concatStringsSep;
  inherit (pkgs.lib.sources) cleanSourceWith;

  debug = message: value: if (getEnv "NIX_DEBUG" != "") then (trace message value) else value;
  debugMatch = re: value:
    let matched = match' re value;
    in debug "regex: ${re} ${if matched then "o" else "x"} ${value}" matched;
  debugFilter = filter: name: path: type:
    let pass = filter path type;
    in debug "filter: ${name} ${if pass then "o" else "x"} ${path} ${type}" pass;

  match' = re: x: match re x != null;
  nmatch' = re: x: ! (match' re x);
  globToRegex = x: ".*/${replaceStrings ["." "**" "*" "?"] ["\\." ".*" "[^/]*" "\\?"] x}";
  drop = x: substring 0 ((stringLength x) - 1) x;
  dropFirst = x: substring 1 ((stringLength x) - 1) x;
  lastChar = x: substring ((stringLength x) - 1) 1 x;
  isDir = x: lastChar x == "/";

  getRegex = rootPath: ignorefile:
    let
      ignoreGlob = filter
        (nmatch' "[\t ]*($|#.*)")
        (splitString "\n" ignorefile);
      ignoreRegex =
        let res = map globToRegex (filter (nmatch' "!.*") ignoreGlob);
        in debug "ignore: ${concatStringsSep " " res}" res;
      unignoreRegex =
        let res = map (x: globToRegex (dropFirst x)) (filter (match' "!.*") ignoreGlob);
        in debug "unignore: ${concatStringsSep " " res}" res;
      #rootPath = dirOf (toString ignorefile);
    in { inherit ignoreRegex unignoreRegex; };

  gitIgnoreFilter = rootPath: ignorefile:
    let
      inherit (getRegex rootPath ignorefile) ignoreRegex unignoreRegex;
    in
      path: type:
        let
          relPath = "/" + (removePrefix (rootPath) (toString path));
          matchFile = re:
            let
              isDir' = (type == "directory") && (isDir re);
              ifDir = optionalString isDir' "/";
            in (match' re (relPath + ifDir));
        in (any matchFile unignoreRegex) || (! (any matchFile ignoreRegex));

  gitIgnoreSourceFile = {
    src,
    rootPath ? (toString src),
    ignorefile ? readFile "${rootPath}/.gitignore",
  }:
    cleanSourceWith {
      filter = gitIgnoreFilter rootPath ignorefile;
      inherit src;
    };

  gitIgnoreSource = src: gitIgnoreSourceFile { inherit src; };
in {
  inherit gitIgnoreSource gitIgnoreFilter gitIgnoreSourceFile debugFilter;
  version = "1.0.0";
}
