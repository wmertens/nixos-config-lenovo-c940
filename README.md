# nixos-config

Flake-based NixOS and home-manager configuration for the host `wmertens-nixos`
(a Lenovo laptop, currently using the Yoga 7 Pro profile; the older Lenovo C940
profile is kept in `lenovo-c940.nix`).

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs, overlays, the `nixosConfigurations.wmertens-nixos` system, the `homeConfigurations.wmertens` home, and the `nixos` / `home-manager` helper scripts |
| `configuration.nix` | Top-level system config; imports the modules below |
| `common.nix`, `laptop.nix`, `gui.nix`, `sound.nix`, `fonts.nix`, `keyboard.nix`, `ollama.nix` | Feature modules |
| `lenovo-yoga-7-pro.nix`, `lenovo-c940.nix`, `hardware-configuration.nix` | Hardware-specific settings |
| `btrfs.nix` | Filesystem settings |
| `keyd.conf` | keyd key remapping |
| `bcachefs-swap.patch` | Patch adding swap file support to bcachefs-tools |
| `home/` | home-manager config: dotfiles, Hyprland config, scripts (`home/scripts`), GNOME extension |
| `nixos/`, `nixpkgs/` | Local package/service customisations on top of nixpkgs |
| `secrets/` | Host-specific secrets (e.g. extra hosts) |
| `disk-pw.jwe` | Encrypted disk password |

## Usage

The flake path is hardcoded in `flake.nix` (`flakePath`) to
`/home/wmertens/Projects/wout-config`; adjust it if the checkout lives elsewhere.

```sh
# Rebuild the system (default action: switch)
nixos            # or: nixos boot | test | build

# Apply the home-manager config
home-manager switch

# Update inputs
nix flake update
```

Both helper wrappers show a closure diff (`nix store diff-closures`) after a
successful change. They are installed system-wide by the configuration, and
also available without installation via `nix run . -- switch`.

Equivalent plain commands:

```sh
sudo nixos-rebuild switch --flake .#wmertens-nixos
home-manager switch --flake .#wmertens
```

## Notes

- Uses the Determinate Nix module and `nixos-unstable`.
- `keyd` is pinned to 2.5.0 via an overlay because 2.6.0 drops spaces.
- Some files (`secrets/`, `home/secrets/`) are not meant to be public; check
  what is committed before sharing the repo.
