# MineSDDM Theme

MineSDDM is a custom theme for [SDDM](https://wiki.archlinux.org/title/SDDM) inspired by Minecraft’s retro 1.8 version and by the [Minecraft GRUB Theme](https://github.com/Lxtharia/minegrub-theme) by Lxtharia

![Preview of the MinesDDM theme](screenshots/minesddm_preview_3.png)
---

## Installation

### Prerequisites

- **SDDM**: Ensure that SDDM is installed and set as your system’s display manager.
- **Qt**: Requires Qt 5.15 or later.
- **Dependencies**: Confirm that your system has all SDDM, QT, and other system-specific dependencies installed. For example `qt5-quickcontrols2`, `layer-shell-qt5`, and `layer-shell-qt`.

### Manual Installation

Should work on most systems

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/Samsu-F/sddm-theme-minesddm.git
   ```

2. **Copy the Theme Folder**:
   ```sh
   sudo cp -r sddm-theme-minesddm/minesddm /usr/share/sddm/themes/
   ```

3. **Set the Theme in SDDM**:
   Edit the SDDM configuration file (usually located at `/etc/sddm.conf` or a file in the `/etc/sddm.conf.d/` directory):
   ```ini
   [Theme]
   Current=minesddm
   ```

3. **Logout of your session**:
   Logout and you will (probably) see the new theme

### NixOS Installation

<details>
<summary>Installation with flakes</summary>

```nix
{
   # ...

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    minesddm = {
      url = "github:Samsu-F/sddm-theme-minesddm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, minesddm }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
            # ...

            minesddm.nixosModules.default

            # or in your configuration.nix
            ({ config, pkgs, ... }: {
               services.displayManager.sddm = {
                  enable = true;
                  theme = "minesddm";
               };
            });
        ];
      };
    };
  };
}
```
</details>

---

## Theme Customization

To override settings in the `theme.conf` configuration file, create a custom `theme.conf.user` file in the same directory and add the settings you want to override. ([Reference](https://wiki.archlinux.org/title/SDDM#Customizing_a_theme))

---

## Screenshots

### MineSDDM
![Preview of the MinesDDM theme](screenshots/minesddm_preview_1.png)
![Preview of the MinesDDM theme](screenshots/minesddm_preview_2.png)
![Preview of the MinesDDM theme](screenshots/minesddm_preview_3.png)

### Minecraft (for comparison)
![Preview of the Minecraft 1.8 menu](screenshots/minecraft_preview_1.jpeg)
![Preview of the Minecraft 1.8 menu](screenshots/minecraft_preview_2.jpeg)
![Preview of the Minecraft 1.8 menu](screenshots/minecraft_preview_3.jpeg)

---

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE).

---

## Contributions

Contributions are welcome! Feel free to open issues or submit pull requests to improve this project.

---
