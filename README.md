# dotfiles

My Ubuntu setup, managed with Nix and Home Manager.
One repo, one command, and a fresh Ubuntu machine ends up configured the same way every time.

Modeled on [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) (macOS, nix-darwin), adapted for Ubuntu with only what I need.

## What you get

Running the switch builds:

- Nix packages: git, ripgrep, fd, jq, htop, uv, WezTerm, VS Code, JetBrains Mono, Hack Nerd Font
- Homebrew formulae: nvm, wget, gh
- Shell: zsh (login shell), aliases, and a Starship prompt, plus autosuggestions, syntax highlighting, history substring search, fzf (`Ctrl+R`, `Ctrl+T`), zoxide (`z`), eza (`ls`, `ll`, `lt`), and bat
- Terminal: WezTerm with the Batman color scheme, JetBrains Mono at 13px, and Hack Nerd Font Mono as the icon fallback
- Editor: VS Code with the Docker extension (Container Tools, `ms-azuretools.vscode-containers`) and the same fonts, ligatures on

Anything that can't come from Nix or Homebrew (Brave, 1Password, ...) I install by hand.

## Prerequisites

- Ubuntu 24.04 on x86_64.
- A normal user with `sudo` rights, and `git`: `sudo apt-get install -y git`.

## Fresh-machine setup

Clone anywhere you like:

```sh
git clone https://github.com/rameskum/dotfiles.git ~/github/rameskum/dotfiles
cd ~/github/rameskum/dotfiles
```

Before you run it, review "Make it yours" below and read the Homebrew cleanup warning.

```sh
./bootstrap.sh
```

`bootstrap.sh` does seven things, in order:

1. Installs the apt prerequisites: `curl git gpg zsh build-essential procps file`.
   These are the only apt packages this repo installs.
2. Installs Determinate Nix, if it isn't already installed.
3. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
4. Checks the `user` configured in `flake.nix` against your Linux username, and offers to fix it if they differ.
5. Installs Homebrew into `/home/linuxbrew/.linuxbrew`, if it isn't already installed.
6. Runs `./rebuild.sh` for the first switch.
7. Makes `/usr/bin/zsh` your login shell.

Log out and back in afterwards to get zsh and to see WezTerm and VS Code in the app launcher.

### Validate without applying

```sh
nix flake check
nix build ~/.dotfiles#homeConfigurations.ubuntu.activationPackage --dry-run
```

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh        # or `rebuild` from anywhere
```

`rebuild.sh` re-points `~/.dotfiles` at this clone and runs `home-manager switch`.
It then asks for sudo only if the GPU drivers for Nix apps need (re)linking, which happens on first run and after some flake updates.

Nix flakes only see files tracked by git, so `git add` new files before rebuilding.

Update things:

```sh
nix flake update && ./rebuild.sh   # newer nixpkgs and home-manager
brew upgrade                       # formulae are never upgraded automatically
```

## Adding and removing software

| Kind | Where | Removed on rebuild when deleted from the list |
| --- | --- | --- |
| CLI tools and GUI apps from nixpkgs ([search](https://search.nixos.org/packages)) | `home.packages` in `home.nix` | yes |
| CLI tools from Homebrew ([search](https://formulae.brew.sh)) | `homebrew.formulae` in `home.nix` | yes |
| Everything else | install by hand | no, remove by hand |

Homebrew formulae live in `home.nix`:

```nix
homebrew = {
  enable = true;
  cleanup = true;
  taps = [ "hashicorp/tap" ];                  # optional third-party taps
  formulae = [
    "nvm"
    "wget"
    "gh"
    "hashicorp/tap/terraform"                  # formula from a tap
  ];
};
```

Add a line and run `./rebuild.sh` to install.
Delete the line and run `./rebuild.sh` to uninstall.

**Homebrew casks don't work on Linux.** Every GUI cask ships a macOS `.app`/`.dmg`, and `brew install --cask ...` fails with "This cask requires macOS".
Use Nix for GUI apps, or install them by hand.

`home.nix` sets `nixpkgs.config.allowUnfree = true;` so VS Code can be installed. Other unfree packages (Slack, ...) can go in `home.packages` the same way.

To try something without installing it: `nix shell nixpkgs#<pkg>`.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh`, which detects your Linux username and offers to set it.
  Or change the single `user = "rameskum"` line in `flake.nix` yourself.
- **Git identity**: `gitName` and `gitEmail` in `flake.nix`.
- **Config label** `"ubuntu"`, in two places: `flake.nix` (`homeConfigurations."ubuntu"`) and `rebuild.sh` (`#ubuntu`).
  It's a config name, not your hostname, so the same config works on any machine.
- **CPU architecture**: `system = "x86_64-linux"` in `flake.nix` (use `aarch64-linux` for ARM).

**Homebrew cleanup warning:** `home.nix` sets `homebrew.cleanup = true`.
Every time you switch, Homebrew uninstalls any formula or tap that isn't listed in `homebrew.formulae` / `homebrew.taps`, including anything you installed with `brew install`.
If you already have Homebrew packages you want to keep, add them to the list first.
Preview what would be removed with `brew bundle cleanup --file ~/.config/homebrew/Brewfile --formula --tap`.

**Heads-up:** the `cc` and `co` aliases are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs and home-manager, holds `user` and the git identity, and declares the `ubuntu` config.
- `home.nix` - user-level config: packages, Homebrew formulae, git, zsh, prompt, and the symlinks described below.
- `modules/homebrew.nix` - implements the `homebrew.*` options.
  It writes `~/.config/homebrew/Brewfile`, then runs `brew bundle install` and `brew bundle cleanup` during the switch.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `bootstrap.sh` - first-time setup.
- `home/` - the actual config files that get symlinked into place.

## How the symlinks work

The files under `home/` are the real files.
Editing them here edits your live config, with no rebuild needed to see the change.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/wezterm` at `~/.dotfiles/home/.config/wezterm`, and `~/.dotfiles` is a symlink to wherever you cloned the repo.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list.

To link another app's config the same way, put it under `home/` and add to `home.nix`:

```nix
home.file.".config/<app>".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/<app>";
```

## Troubleshooting

- **`error: path '...' does not exist`**: a new file isn't `git add`-ed.
- **`Existing file '...' would be clobbered`**: move that file out of the way, or keep a backup with `./rebuild.sh -b backup`.
- **WezTerm fails with an EGL/OpenGL error**: the GPU link is stale.
  Run `./rebuild.sh`, which relinks it.
- **WezTerm missing from the app launcher**: log out and back in.
