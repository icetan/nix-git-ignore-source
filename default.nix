{ pkgs ? (import <nixpkgs> {}) }: with pkgs; let
  match = re: x: builtins.match re x != null;
  nmatch = re: x: ! (match re x);
  globToRegex = x: "^" + (builtins.replaceStrings ["." "*"] ["\\." ".*"] x) + "$";
  gitIgnoreSource = src: let
    relPath = path: lib.removePrefix (toString src + "/") (toString path);
    gitignore = (toString src) + "/.gitignore";
    ignoreGlob = lib.filter
      (nmatch "^\\s*($|#.*)")
      (lib.splitString "\n" (builtins.readFile gitignore));
    ignoreRegex = map globToRegex ignoreGlob;
  in
    builtins.filterSource (path: type: let
      baseName = baseNameOf (toString path);
      relPath' = relPath path;
    in (
      (lib.sources.cleanSourceFilter path type) &&
      (type != "symlink") &&
      ! (lib.any (re:
           (match re relPath') ||
           (match re baseName)
      ) ignoreRegex)
    )) src;
in {
  inherit gitIgnoreSource;
}
