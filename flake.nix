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
      packages.default = pkgs.stdenv.mkDerivation {
        pname = "sddm-theme-minesddm";
        version = "1.0.0";
        src = ./.;

        dontWrapQtApps = true;

        installPhase = ''
          mkdir -p $out/share/sddm/themes/minesddm
          cp -r minesddm/* $out/share/sddm/themes/minesddm/
        '';

        meta = with pkgs.lib; {
          description = "A Minecraft-styled SDDM theme";
          license = licenses.agpl3Only;
          platforms = platforms.linux;
        };
      };
    }) // {
      nixosModules.default = { config, pkgs, lib, ... }:
      let
        cfg = config.services.displayManager.sddm;
        isMinesddmTheme = (cfg.theme == "minesddm") ||
                           (cfg.settings.Theme.Current == "minesddm");
      in {
        environment.systemPackages = with pkgs; [
          self.packages.${pkgs.system}.default
        ] ++ lib.optionals isMinesddmTheme [
          qt5.qtbase
          qt5.qtquickcontrols2
          qt5.qtgraphicaleffects
          kdePackages.layer-shell-qt
        ];
      };
    };
}
