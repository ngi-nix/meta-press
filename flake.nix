{
  description =
    "Decentralized search engine & automatized press reviews - firefox extension";

  # Nixpkgs pinned to a commit with that allows overriding the source of firefox addons
  # Change this to the release after 21.05 when released
  inputs.nixpkgs.url = "nixpkgs/dacaba9b9a886bad92d25ba1d87a84a65cc1298b";

  inputs.meta-press-src = {
    url = "https://framagit.org/Siltaar/meta-press-ext";
    flake = false;
    submodules = true;
    type = "git";
  };

  outputs = { self, nixpkgs, meta-press-src }:
    let
      version = "1.7.7";

      # System types to support.
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });

      meta-press = { src, lib, stdenv, p7zip }:
        stdenv.mkDerivation {
          name = "meta-press-${version}";

          src = meta-press-src;

          buildInputs = [ p7zip ];

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
            mkdir -p $out
            ZIP=$(find ../ -type f -name "*.zip")
            mv -- "$ZIP" "$(basename -- "$ZIP" .zip).xpi"
            XPI=$(find ../ -type f -name "*.xpi")
            mv $XPI $out/firefox_addon.xpi
          '';

          meta = {
            homepage = "https://www.meta-press.es";
            description =
              "Decentralized search engine & automatized press reviews";
            license = with lib.licenses; [ mit gpl3 ];
          };
        };

    in {

      overlay = final: prev: {
        meta-press = final.callPackage meta-press { };

        firefox-meta-press-pinned =
          let inherit (final) wrapFirefox firefox-esr-unwrapped fetchFirefoxAddon;
          in wrapFirefox firefox-esr-unwrapped {
            nixExtensions = [
              (fetchFirefoxAddon {
                name = "meta-press-es"; # Has to be unique!
                url = "https://addons.mozilla.org/firefox/downloads/file/3759736/meta_presses-${version}-an+fx.xpi";
                sha256 = "02glmx9qmra39mpsrsk09wdgx8wgdg45j00ls4gcibmi2n5d4dxi";
              })
            ];
          };

        firefox-meta-press = let
          inherit (final)
            lib meta-press stdenv wrapFirefox firefox-esr-unwrapped
            fetchFirefoxAddon;
        in wrapFirefox firefox-esr-unwrapped {
          nixExtensions = [
            ((fetchFirefoxAddon {
              name = "meta-press-es"; # Has to be unique!
              src = "${meta-press.outPath}/firefox_addon.xpi";
            }))
          ];
        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system})
          meta-press firefox-meta-press firefox-meta-press-pinned;
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.meta-press);
    };
}
