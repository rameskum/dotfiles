# Roadmap

## Where the repo started

- One flake with two outputs: a nix-darwin config for macOS and a standalone
  Home Manager config for Ubuntu, sharing `hosts/common.nix`.
- Homebrew was managed by the third-party `koalalorenzo/home-manager-brew`
  module.

Problems found:

| Problem | Effect |
| --- | --- |
| The brew module always adds the `mas` formula (Mac App Store CLI) to the Brewfile. | `mas` is macOS-only, so `brew bundle install` failed on Ubuntu and the whole brew step broke. |
| The brew module silently drops `casks` on Linux. | `visual-studio-code` (and any GUI app) was never installed. Casks only exist on macOS. |
| The brew module installs Homebrew with `curl \| bash` from inside `home-manager switch` and runs `brew update` + `brew upgrade --greedy` on every switch. | Interactive sudo prompts mid-activation, and slow rebuilds that change versions without being asked. |
| `bootstrap.sh` was written for macOS: `sed -i ''` (BSD syntax, breaks GNU sed) and matched `user = "` while `flake.nix` says `username = "`. | The username rewrite never worked on Ubuntu. |
| Brave came from nixpkgs. | Nix GUI apps on Ubuntu need GPU wrappers (nixGL), and 1Password can't trust a browser binary in `/nix/store` for its extension integration. |
| `zsh` was in `home.packages` but never set as the login shell. | The configured zsh was only used if you started it by hand. |
| No README or docs. | Setup and conventions lived in your head. |

## What this change does

- **Ubuntu only.** Removed nix-darwin, `hosts/darwin.nix`, `isMac`, and the
  darwin flake inputs.
- **Split config** into `home/{packages,homebrew,shell,git,wezterm}.nix`.
- **Homebrew fixed.** A small local module (`modules/homebrew.nix`) replaces
  the third-party one:
  - formulae + taps only, rendered to `~/.config/homebrew/Brewfile`
  - `brew bundle install` only when `brew bundle check` says something's missing
  - `brew bundle cleanup --formula --tap --force` removes anything installed
    by hand
  - no auto-update/upgrade; Homebrew itself is installed by `bootstrap.sh`
- **GUI apps via apt.** `ubuntu/apt-apps.sh` lists Brave, 1Password and
  WezTerm with their vendor repos. `ubuntu/apt-sync.sh` installs them, and
  purges apps (plus repo and key) you delete from the list.
- **zsh by default.** `bootstrap.sh` sets `/usr/bin/zsh` as login shell.
  Home Manager configures Starship, autosuggestions, syntax highlighting,
  history substring search, fzf, zoxide, eza, bat, and completion styling.
  WezTerm gets a matching Catppuccin Mocha theme with Hack Nerd Font.
- **Docs.** README, setup guide, software management guide, and this roadmap.

Verified end to end on a clean Ubuntu 24.04 VM: bootstrap, rebuild,
removing and re-adding an apt app, and a hand-installed brew formula being
removed on rebuild.

## Next steps

Roughly in priority order.

1. **CI**: a GitHub Action running `nix flake check` and
   `nix build .#homeConfigurations.ubuntu.activationPackage` on each PR, plus
   `shellcheck` on the scripts.
2. **Secrets**: [sops-nix](https://github.com/Mic92/sops-nix) or
   [agenix](https://github.com/ryantm/agenix) for SSH config and tokens. Or
   lean on 1Password: `op` CLI plus the 1Password SSH agent
   (`IdentityAgent ~/.1password/agent.sock`) and git commit signing.
3. **Editor**: manage Neovim or VS Code settings and extensions
   declaratively (`programs.neovim` / `programs.vscode` with
   `package = null`-style config-only setup).
4. **GNOME settings**: `dconf.settings` for keyboard shortcuts, dock
   favorites, dark mode, and making WezTerm the default terminal.
5. **Runtimes**: consider replacing brew `nvm` with `fnm` or `mise` from
   nixpkgs for faster shell startup and one less brew formula.
6. **Multiple machines**: turn `homeConfigurations.ubuntu` into one per host
   (`work`, `personal`) sharing `home/` and overriding only what differs.
7. **Auto-updates**: a weekly GitHub Action that runs `nix flake update` and
   opens a PR.
8. **macOS again (later)**: add a `darwinConfigurations` output reusing
   `home/`, with nix-darwin's native `homebrew` module for casks.
