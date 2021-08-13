{
  description =
    "Decentralized search engine & automatized press reviews - firefox extension";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/21.05";

  inputs.meta-press = {
    url = "https://framagit.org/Siltaar/meta-press-ext";
    flake = false;
    submodules = true;
    type = "git";
  };

  outputs = { self, nixpkgs, meta-press }:
    let
      version = "1.7.7";

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = nixpkgs.lib.attrValues self.overlays;
        });

    in {

      # A Nixpkgs overlay.
      overlays = {
        firefox-meta-press = final: prev: {
          firefox-meta-press = with final;
            wrapFirefox firefox-unwrapped {
              nixExtensions = [
                (fetchFirefoxAddon {
                  name = "meta-press-es"; # Has to be unique!
                  url =
                    "https://addons.mozilla.org/firefox/downloads/file/3759736/meta_presses-${version}-an+fx.xpi";
                  sha256 =
                    "02glmx9qmra39mpsrsk09wdgx8wgdg45j00ls4gcibmi2n5d4dxi";
                })
              ];
            };
        };
        meta-press = final: prev: {
          meta-press = with final;
            stdenv.mkDerivation rec {
              name = "meta-press-${version}";

              src = meta-press;

              buildInputs = with final; [ p7zip zip ];

              # The Make file moves the output to the enclosing folder
              # This makes use of the fact that mv ignores dotfiles
              buildPhase = ''
                mkdir .build
                mv * .build
                cd .build
                make
              '';

              # An xpi is just a renamed zip for firefox extensions
              installPhase = ''
                mkdir $out
                ZIP=$(find ../ -type f -name "*.zip")
                mv -- "$ZIP" "$(basename -- "$ZIP" .zip).xpi"
                XPI=$(find ../ -type f -name "*.xpi")
                mv $XPI $out
              '';

              meta = {
                homepage = "https://www.meta-press.es";
                description =
                  "Decentralized search engine & automatized press reviews";
              };
            };
        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) firefox-meta-press;
        inherit (nixpkgsFor.${system}) meta-press;
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.firefox-meta-press);
    };
}
