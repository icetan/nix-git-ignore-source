{ pkgs ? (import <nixpkgs> {}) }: with pkgs; let
  match = re: x: builtins.match re x != null;
  nmatch = re: x: ! (match re x);
  globToRegex = x: "^" + (builtins.replaceStrings ["." "*"] ["\\." "[^/]*"] x) + "$";
  drop = x: builtins.substring 0 ((lib.stringLength x) - 1) x;
  lastChar = x: builtins.substring ((lib.stringLength x) - 1) 1 x;
  isDir = x: lastChar x == "/";

  gitIgnoreFilter = gitignore: path: type: let
    baseName = baseNameOf (toString path);
    relPath = lib.removePrefix (dirOf (toString gitignore) + "/") (toString path);
    ignoreGlob = lib.filter
      (nmatch "^\\s*($|#.*)")
      (lib.splitString "\n" (builtins.readFile gitignore));
    ignoreRegex = map globToRegex ignoreGlob;
  in (
    (lib.sources.cleanSourceFilter path type) &&
    (type != "symlink") &&
    ! (lib.any (re: let
      ifDir = lib.optionalString ( (isDir (drop re)) && (type == "directory") ) "/";
    in
      ( (match re (relPath + ifDir)) || (match re (baseName + ifDir)) )
    ) ignoreRegex)
  );

  gitIgnoreSource = src: let
    gitignore = (toString src) + "/.gitignore";
  in
    builtins.filterSource (p: t: let
      pass = gitIgnoreFilter gitignore p t;
    in
      builtins.trace "${if pass then "o" else "x"} ${p} ${t}" pass
    ) src;
in {
  inherit gitIgnoreSource gitIgnoreFilter;
}
