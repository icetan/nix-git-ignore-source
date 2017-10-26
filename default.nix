{ pkgs ? (import <nixpkgs> {}) }: with pkgs; let
  match = re: x: builtins.match re x != null;
  nmatch = re: x: ! (match re x);
  globToRegex = x: "^" + (builtins.replaceStrings ["." "*"] ["\\." ".*"] x) + "$";

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
    ! (lib.any (re:
      (match re relPath) ||
      (match re baseName)
    ) ignoreRegex)
  );

  gitIgnoreSource = src: let
    gitignore = (toString src) + "/.gitignore";
  in
    builtins.filterSource (gitIgnoreFilter gitignore) src;
in {
  inherit gitIgnoreSource gitIgnoreFilter;
}
