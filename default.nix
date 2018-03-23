{ pkgs ? (import <nixpkgs> {}) }: with pkgs; let
  inherit (builtins) trace match replaceStrings substring readFile filterSource
    getEnv;
  inherit (lib) stringLength filter removePrefix optionalString splitString any
    sources;

  debug = message: value: if (getEnv "NIX_DEBUG" != "") then (trace message value) else value;

  match' = re: x: match re x != null;
  nmatch' = re: x: ! (match' re x);
  globToRegex = x: "^" + (replaceStrings ["." "*"] ["\\." "[^/]*"] x) + "$";
  drop = x: substring 0 ((stringLength x) - 1) x;
  lastChar = x: substring ((stringLength x) - 1) 1 x;
  isDir = x: lastChar x == "/";

  gitIgnoreFilter = gitignore: path: type: let
    baseName = baseNameOf (toString path);
    relPath = removePrefix (dirOf (toString gitignore) + "/") (toString path);
    ignoreGlob = filter
      (nmatch' "^[:space:]*($|#.*)")
      (splitString "\n" (readFile gitignore));
    ignoreRegex = map globToRegex ignoreGlob;
  in (
    (sources.cleanSourceFilter path type) &&
    (type != "symlink") &&
    ! (any (re: let
      ifDir = optionalString ( (isDir (drop re)) && (type == "directory") ) "/";
    in
      ( (match' re (relPath + ifDir)) || (match' re (baseName + ifDir)) )
    ) ignoreRegex)
  );

  gitIgnoreSource = src: let
    gitignore = (toString src) + "/.gitignore";
  in
    filterSource (p: t: let
      pass = gitIgnoreFilter gitignore p t;
    in
      debug "${if pass then "o" else "x"} ${p} ${t}" pass
    ) src;
in {
  inherit gitIgnoreSource gitIgnoreFilter;
}
