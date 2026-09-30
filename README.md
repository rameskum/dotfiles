# dotfiles

My Ubuntu setup, managed with Nix and Home Manager.
One repo, one command, and a fresh Ubuntu machine ends up configured the same way every time.

Modeled on [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) (macOS, nix-darwin), adapted for Ubuntu with only what I need.

## What you get

Running `./rebuild.sh` builds:

- Nix packages: ripgrep, fd, jq, htop, uv, git, Hack Nerd Font
- Apps from Nix: Brave, WezTerm
- Homebrew formulae: nvm, wget, gh
- Shell: zsh as the login shell, with a Starship prompt, autosuggestions, syntax highlighting, history substring search, fzf (`Ctrl+R`, `Ctrl+T`), zoxide (`z`), eza (`ls`, `ll`, `lt`), bat, and aliases
- Terminal: WezTerm config with Catppuccin Mocha and Hack Nerd Font
- apt apps: 1Password (the one app that can't run properly from Nix, see below)

## Prerequisites

- Ubuntu 24.04 (x86_64). Other recent Ubuntu releases should work.
- A normal user with `sudo` rights.

## Fresh-machine setup

```sh
sudo apt-get install -y git
git clone https://github.com/rameskum/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Review "Make it yours" below first, especially the Homebrew cleanup warning.

```sh
./bootstrap.sh
```

`bootstrap.sh` does six things, in order, and is safe to re-run:

1. Checks the `user` in `flake.nix` against your Linux username, and offers to fix it if they differ.
2. Installs apt prerequisites: `curl git gpg zsh build-essential procps file`.
3. Installs Determinate Nix, if it isn't already installed.
4. Installs Homebrew to `/home/linuxbrew/.linuxbrew`, if it isn't already installed.
5. Runs `./rebuild.sh` (below).
6. Makes `/usr/bin/zsh` your login shell.

Log out and back in afterwards. That picks up zsh and makes Brave and WezTerm appear in the app launcher.

### Validate without applying

```sh
nix flake check
nix build .#homeConfigurations.ubuntu.activationPackage --dry-run
```

## Daily use

Edit the config, then apply:

```sh
./rebuild.sh        # or just `rebuild` from anywhere
```

`rebuild.sh` does two things:

1. `home-manager switch`: packages, apps, zsh, dotfiles, and Homebrew formulae.
   Files it would overwrite, such as Ubuntu's default `~/.bashrc`, are moved to `*.hm-backup`.
2. `system/sync.sh`: the root-level bits Home Manager can't do on Ubuntu (apt apps, GPU drivers, AppArmor).
   It asks for sudo only when something needs to change.

Nix flakes only see files tracked by git, so `git add` new files before rebuilding.

Updating:

```sh
nix flake update && ./rebuild.sh   # newer nixpkgs: Brave, WezTerm, CLI tools
brew upgrade                       # brew formulae (never upgraded automatically)
sudo apt update && sudo apt upgrade   # 1Password
```

## Adding and removing software

Pick the first place that works:

| Where | For | Add | Remove |
| --- | --- | --- | --- |
| `home.packages` in `home.nix` | CLI tools and GUI apps ([search](https://search.nixos.org/packages)) | add a line | delete the line |
| `homebrew.formulae` in `home.nix` | CLI tools not in nixpkgs, or ones you prefer from brew | add a line | delete the line |
| `system/apps.sh` | apps that must be installed system-wide (1Password) | add an `app` block | delete the block |

Then run `./rebuild.sh`. Removal is automatic in all three places:

- **Nix**: anything not listed is gone from your profile.
- **Homebrew**: every formula and tap not listed is uninstalled, **including anything you installed by hand with `brew install`**.
- **apt**: apps deleted from `system/apps.sh` are purged, along with their repo and signing key. Packages you installed yourself with `apt install` are never touched.
  Remove those with `sudo apt purge --autoremove <pkg>`.

To try something without installing it: `nix shell nixpkgs#<pkg>`.

Unfree Nix packages (VS Code, Slack, Discord, ...) need `nixpkgs.config.allowUnfree = true;` in `home.nix`.
Chromium- and Electron-based apps from Nix (Slack, Discord, VS Code, ...) also need an AppArmor profile on Ubuntu 24.04, like `system/apparmor/nix-brave`.
Copy that file and change the name and the binary path.

To add a brew tap:

```nix
homebrew.taps = [ "hashicorp/tap" ];
homebrew.formulae = [ "hashicorp/tap/terraform" ];
```

## Why not brew casks, and why is 1Password on apt?

- **Homebrew casks are macOS-only.** `brew install --cask wezterm` on Linux fails with "This cask requires macOS". On Ubuntu, brew is for formulae (CLI tools) only.
- **GUI apps come from Nix**, which plays the role casks play on a Mac.
  On Ubuntu they need two one-time system tweaks, which `system/sync.sh` handles:
  - **GPU drivers**: Nix apps can't use Ubuntu's graphics libraries.
    Home Manager's `targets.genericLinux.gpu` provides `non-nixos-gpu-setup`, which links `/run/opengl-driver` to matching Mesa drivers.
  - **AppArmor**: Ubuntu 24.04 blocks unprivileged user namespaces, which Chromium's sandbox needs.
    Ubuntu ships profiles that allow it for `/opt/brave.com/brave/brave`, but not for a path in `/nix/store`.
    `system/apparmor/nix-brave` is the same profile, pointed at the Nix path.
- **1Password is the exception.** Its browser integration needs a setgid helper, and unlocking with your system password needs a polkit policy.
  Neither can be installed from `/nix/store` outside NixOS.
  The official `.deb` sets both up, and the Brave extension connects to it as usual.

## Make it yours

- **Username**: `./bootstrap.sh` detects your Linux username and offers to set it, or change the single `user = "rameskum"` line in `flake.nix`.
- **Git identity**: `gitName` and `gitEmail` in `flake.nix`.
- **Host label** `"ubuntu"`: in `flake.nix` (`homeConfigurations."ubuntu"`) and in `rebuild.sh` (`#ubuntu`).
- **CPU architecture**: `system = "x86_64-linux"` in `flake.nix` (`aarch64-linux` for ARM).

**Homebrew cleanup warning:** `homebrew.cleanup = true` in `home.nix` means every rebuild uninstalls any formula not listed in `homebrew.formulae`.
If you already have Homebrew packages, add the ones you want to keep before your first rebuild.
`brew bundle cleanup --file ~/.config/homebrew/Brewfile --formula --tap` previews what would be removed.

**Heads-up:** the `cc` and `co` aliases are high-agency shortcuts (`claude --dangerously-skip-permissions`, `codex --full-auto`).

## Repo tour

- `flake.nix`: the entry point.
  Wires up nixpkgs and home-manager, holds the `user` and git identity, and declares the `ubuntu` configuration.
- `home.nix`: user-level config: packages, apps, Homebrew formulae, git, zsh, prompt, and the symlinks below.
- `modules/homebrew.nix`: implements `homebrew.*`.
  It writes `~/.config/homebrew/Brewfile`, then runs `brew bundle install` and `brew bundle cleanup` during the switch.
- `system/`: root-level setup Home Manager can't do on Ubuntu.
  - `sync.sh`: run by `rebuild.sh`.
  - `apps.sh`: the apt app list.
  - `apparmor/`: AppArmor profiles.
- `home/`: the actual config files that get symlinked into place.
- `bootstrap.sh`: first-time setup.
- `rebuild.sh`: applies the config.
  Run it every time you change something that isn't a symlinked file.

## How the symlinks work

The files under `home/` are the real files.
Editing them here edits your live config, with no rebuild needed.
`home.nix` uses `mkOutOfStoreSymlink` to point `~/.config/wezterm` straight at `home/.config/wezterm` in this repo (through `~/.dotfiles`, which `rebuild.sh` creates), so the two never drift apart.
WezTerm reloads its config as soon as you save.

To add another app's config the same way, put it under `home/` and add a line to `home.nix`:

```nix
home.file.".config/<app>".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/<app>";
```

## Troubleshooting

- **`error: path '...' does not exist`**: a new file isn't `git add`-ed.
- **`Existing file '...' is in the way`**: a `*.hm-backup` from an earlier run already exists. Delete it and re-run.
- **Brave or WezTerm missing from the launcher**: log out and back in (Home Manager sets `XDG_DATA_DIRS` at login).
- **WezTerm fails with an EGL error, or Brave is slow**: the GPU link is stale. Run `./rebuild.sh`, or run `sudo non-nixos-gpu-setup` directly.
- **Brave: "No usable sandbox"**: the AppArmor profile isn't loaded. Run `./rebuild.sh`, then check with `sudo aa-status | grep nix-brave`.
- **1Password extension can't connect to the app**: add `brave` to `/etc/1password/custom_allowed_browsers`, then restart 1Password.
- **apt: "Conflicting values set for option Signed-By"**: the same repo is configured twice, usually from an earlier manual install.
  Delete the extra file in `/etc/apt/sources.list.d/`.
