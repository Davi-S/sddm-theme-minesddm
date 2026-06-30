{
  description = "MineSSDM - A Minecraft-styled SDDM theme";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # note for settings attr-set:
      # { key = "value"; }     => key = value
      # { key = "\"value\""; } => key = "value"
      packages.default = pkgs.callPackage ({
        lib,
        stdenv,
        settings ? {},
        overwrite ? false,
        ...
      }: stdenv.mkDerivation rec {
        pname = "sddm-theme-minesddm";
        version = "1.0.0";
        src = ./.;

        settingsText =
          (if overwrite then ''
            [general]
          '' else ''
            ${builtins.readFile "${src}/minesddm/theme.conf"}
          '') + ''
            ${lib.generators.toKeyValue
              { mkKeyValue = lib.generators.mkKeyValueDefault {} " = "; }
            settings}
          '';

        passAsFile = [ "settingsText" ];
        dontWrapQtApps = true;

        installPhase = ''
          mkdir -p $out/share/sddm/themes/minesddm
          cp -r minesddm/* $out/share/sddm/themes/minesddm/
          cp $settingsTextPath $out/share/sddm/themes/minesddm/theme.conf
        '';

        meta = with pkgs.lib; {
          description = "A Minecraft-styled SDDM theme";
          license = licenses.agpl3Only;
          platforms = platforms.linux;
        };
      }) {};

    }) // {
      nixosModules.default = { config, pkgs, lib, ... }:
      let
        cfg = config.services.displayManager.sddm;
        isMinesddmTheme = (cfg.theme == "minesddm") ||
                           (cfg.settings.Theme.Current == "minesddm");
      in {
        environment.systemPackages = with pkgs; [
          self.packages.${pkgs.stdenv.hostPlatform.system}.default
        ] ++ lib.optionals isMinesddmTheme [
          qt5.qtbase
          qt5.qtquickcontrols2
          qt5.qtgraphicaleffects
          kdePackages.layer-shell-qt
        ];
      };
    };
}
