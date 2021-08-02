# [Meta-Press.es](https://www.meta-press.es/)

_Meta-Press.es is a press search engine, in the shape of a browser add-on._

## Nix

* [ngi-issue](https://github.com/ngi-nix/ngi/issues/165)

As this is a firefox extension there are no dependencies but firefox itself.

This flake provides an overlay for firefox that includes this extension, as shown in the [firefox.section.md](https://github.com/NixOS/nixpkgs/blob/master/doc/builders/packages/firefox.section.md) of nixpkgs, that shows a snapshot in time when firefox was built with this extension enabled.
