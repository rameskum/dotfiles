# dotfiles

Declarative setup for an Ubuntu desktop. One command (`./rebuild.sh`) makes
the machine match this repo: CLI tools, shell, dotfiles, Homebrew formulae,
and GUI apps. Anything removed from the repo is removed from the machine on the next
rebuild.

macOS support was removed for now; the repo targets Ubuntu (x86_64) only.

## What's in the box

| Layer | Used for | Where it's declared |
| --- | --- | --- |
| [Nix](https://nixos.org) + [Home Manager](https://github.com/nix-community/home-manager) | CLI tools, fonts, dotfiles, zsh | `home/*.nix` |
| [Homebrew](https://brew.sh) (Linuxbrew) | CLI formulae not worth packaging with Nix | `home/homebrew.nix` |
| apt (vendor repos) | GUI apps: Brave, 1Password, WezTerm | `ubuntu/apt-apps.sh` |

Why three? Nix is the default for everything it can do well. Homebrew stays
for formulae you'd rather get from brew. GUI apps come from their vendors'
apt repos, because Nix-built GUI apps on Ubuntu need GPU wrappers, and
1Password's browser integration and system unlock only work with the
official `.deb`. Homebrew casks (GUI apps) are macOS-only, so brew can't do
this on Linux.

Shell: zsh (login shell) with [Starship](https://starship.rs) prompt,
autosuggestions, syntax highlighting, history substring search, fzf
(`Ctrl+R`, `Ctrl+T`), zoxide (`z`), eza (`ls`/`ll`/`lt`), and bat.

## Layout

```
flake.nix             inputs (nixpkgs, home-manager) + your name/email/username
home/
  default.nix         entry point, imports everything below
  packages.nix        Nix packages (CLI tools, fonts)
  homebrew.nix        Homebrew formulae + taps
  shell.nix           zsh, starship, fzf, zoxide, eza, bat, aliases
  git.nix             git identity and settings
  wezterm.nix         WezTerm config (~/.config/wezterm/wezterm.lua)
modules/
  homebrew.nix        the Home Manager module that syncs brew with the list
ubuntu/
  apt-apps.sh         GUI apps + their vendor apt repos
  apt-sync.sh         installs/removes apt apps to match apt-apps.sh
bootstrap.sh          first-time setup on a fresh machine
rebuild.sh            apply changes (run after every edit)
```

## Quick start

```bash
git clone https://github.com/rameskum/dotfiles ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
# log out and back in to get zsh
```

Then edit, `git add`, and run `./rebuild.sh` (or just `rebuild` in zsh).

## Guides

- [Initial setup](docs/setup.md): fresh machine to working desktop, plus troubleshooting
- [Managing software](docs/managing-software.md): add, remove, and update apps in each layer
- [Roadmap](docs/roadmap.md): what changed, and planned improvements
