# nix-git-ignore-source

Use a `.gitignore` file to filter out source files from nix derivations.

## API

This expression has two attributes `gitIgnoreSource` and `gitIgnoreFilter`.

`gitIgnoreSource` just takes one argument which is a `path` to a directory with
a `.gitignore` file in it.

`gitIgnoreFilter` is a more general function that plugs into
`builtins.filterSource` by taking first a `path` to a `.gitignore` then the
same two parameters as given by `filterSource`, the path and type of the file to
check if it is ignored by the ignore file.

## Example usage

```nix
{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs)
    stdenv fetchgit;

  gis = import (fetchgit {
    url: "git://github.com/icetan/nix-git-ignore-source";
    rev: "f495761ee217f5481f4305fb90ce8b5219157c73";
    sha256: "0b9ga733mq0ryd7xjsla0ijc9blrj5rw8i2d2g4jazhm31lc350j";
  }) {
    inherit pkgs;
  };

in stdenv.mkDerivation {
  name = "example";
  src = gis.gitIgnoreSource ./.;
}
```
