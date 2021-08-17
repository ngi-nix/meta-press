{
  description =
    "Decentralized search engine & automatized press reviews - firefox extension";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/21.05";

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
          overlays = self.overlays;
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

      # A Nixpkgs overlay.
      overlays = [
        (final: prev: {
          meta-press = final.callPackage meta-press {};
        })

        (final: prev: {
          firefox-meta-press-pinned =
            let inherit (final) wrapFirefox firefox-unwrapped fetchFirefoxAddon;
            in wrapFirefox firefox-unwrapped {
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
        })
        (final: prev: {
          firefox-meta-press = let
            inherit (final)
              lib meta-press stdenv wrapFirefox firefox-unwrapped fetchFirefoxAddon;
          in wrapFirefox firefox-unwrapped {
            nixExtensions = [
              # Waiting for a pull request to be merged into nixpkgs
              # https://github.com/NixOS/nixpkgs/pull/134427
              # ((fetchFirefoxAddon {
              # name = "meta-press-es"; # Has to be unique!
              # src = "${meta-press.outPath}/firefox_addon.xpi";
              # }))
              (stdenv.mkDerivation rec {
                name = "meta-press-es";
                extid = "nixos@${name}";
                passthru = { inherit extid; };
                nativeBuildInputs = with prev.pkgs; [ coreutils unzip zip jq ];
                src = "${meta-press.outPath}/firefox_addon.xpi";
                builder = prev.writeScript "xpibuilder" ''
                  source $stdenv/setup

                  header "firefox addon $name into $out"

                  UUID="${extid}"
                  mkdir -p "$out/$UUID"
                  unzip -q ${src} -d "$out/$UUID"
                  NEW_MANIFEST=$(jq '. + {"applications": { "gecko": { "id": "${extid}" }}, "browser_specific_settings":{"gecko":{"id": "${extid}"}}}' "$out/$UUID/manifest.json")
                  echo "$NEW_MANIFEST" > "$out/$UUID/manifest.json"
                  cd "$out/$UUID"
                  zip -r -q -FS "$out/$UUID.xpi" *
                  rm -r "$out/$UUID"
                '';
              })
            ];
          };
        })
      ];

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) meta-press;
        inherit (nixpkgsFor.${system}) firefox-meta-press;
        inherit (nixpkgsFor.${system}) firefox-meta-press-pinned;
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.firefox-meta-press);
    };
}
