{
  description =
    "Decentralized search engine & automatized press reviews - firefox extension";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/21.05";

  outputs = { self, nixpkgs }:
    let
      version = "1.7.6";

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });

    in {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        firefox-meta-press = with final;
          wrapFirefox firefox-unwrapped {
            nixExtensions = [
              (fetchFirefoxAddon {
                name = "meta-press-es"; # Has to be unique!
                url =
                  "https://addons.mozilla.org/firefox/downloads/file/3759736/meta_presses-${version}-an+fx.xpi";
                sha256 = "02glmx9qmra39mpsrsk09wdgx8wgdg45j00ls4gcibmi2n5d4dxi";
              })
            ];
          };
      };

      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) firefox-meta-press; });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.firefox-meta-press);
    };
}
