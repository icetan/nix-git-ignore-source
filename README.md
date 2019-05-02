**For a more mature project that solves the same problem have a look here:
https://github.com/siers/nix-gitignore**

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
{
  pkgs ? import <nixpkgs> {},
  gis ? import (fetchTarball {
    url = https://github.com/icetan/nix-git-ignore-source/archive/v1.0.0.tar.gz;
    sha256 = "1mnpab6x0bnshpp0acddylpa3dslhzd2m1kk3n0k23jqf9ddz57k";
  }) {},
}:

pkgs.stdenv.mkDerivation {
  name = "example";
  src = gis.gitIgnoreSource ./.;
}
```
