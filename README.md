# dotfiles

My shell and terminal setup, the same on macOS, Linux (including WSL2) and Windows, applied with [chezmoi](https://www.chezmoi.io).
Aliases, a prompt, autocompletion, a good-looking terminal, a Nerd Font and my agent skills: one repo, one command per machine.

The older Ubuntu-only setup (Nix and Home Manager) still works and is documented at the bottom, under [Legacy: Nix and Home Manager](#legacy-nix-and-home-manager-linux).
It goes away once chezmoi has replaced it.

## What you get

| | macOS | Linux | WSL2 | Windows |
| --- | --- | --- | --- | --- |
| Shell config | `~/.zshrc` | `~/.zshrc` | `~/.zshrc` | PowerShell 7 `profile.ps1` |
| Prompt | starship, `~/.config/starship.toml` (one file, all OSes) | same | same | same |
| Aliases | one list, rendered into the shell config | same | same | same |
| Suggestions | zsh-autosuggestions | same | same | PSReadLine prediction |
| Completion | zsh `compinit`, case-insensitive menu | same | same | PSReadLine `MenuComplete` |
| Highlighting | zsh-syntax-highlighting | same | same | PSReadLine (built in) |
| fzf, zoxide | `Ctrl+R`, `Ctrl+T`, `z` | same | same | same |
| Terminal | WezTerm, `~/.wezterm.lua` (one file, all OSes) | by hand (see below) | the Windows side | WezTerm |
| Font | JetBrainsMono Nerd Font | same | the Windows side | same |
| Agent skills | `~/.agents/.skill-lock.json` and my own skills | same | same | same |

Everything is installed by one `run_once_` script per OS, and nothing else is installed:

- macOS, Linux, WSL2: Homebrew formulae `starship`, `fzf`, `zoxide`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search`; casks `wezterm` (macOS only) and `font-jetbrains-mono-nerd-font` (not on WSL).
- Windows: WinGet packages `wez.wezterm`, `DEVCOM.JetBrainsMonoNerdFont`, `Starship.Starship`, `junegunn.fzf`, `ajeetdsouza.zoxide`.

The lists live in `chezmoi/.chezmoidata/packages.yaml`.

## New machine

Every OS ends with the same command:

```sh
chezmoi init --apply rameskum/dotfiles
```

Open a new terminal afterwards.

### macOS

1. Install Homebrew: <https://brew.sh>.
2. `brew install chezmoi`
3. `chezmoi init --apply rameskum/dotfiles`

zsh is already the login shell.

### Linux (Ubuntu)

1. Prerequisites:

   ```sh
   sudo apt-get install -y curl git zsh build-essential procps file
   ```

2. Install Homebrew: <https://brew.sh> (it lands in `/home/linuxbrew/.linuxbrew`).
3. Install chezmoi and apply:

   ```sh
   sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply rameskum/dotfiles
   ```

4. Make zsh the login shell: `chsh -s "$(command -v zsh)"`, then log out and in.
5. WezTerm has no Homebrew build for Linux, so install it by hand: <https://wezterm.org/install/linux.html>.
   The config in `~/.wezterm.lua` is picked up as soon as it runs.

### Windows (native, PowerShell 7)

1. In any PowerShell:

   ```powershell
   winget install Git.Git Microsoft.PowerShell twpayne.chezmoi
   ```

2. Open a new **PowerShell 7** window (`pwsh`, not "Windows PowerShell") and run:

   ```powershell
   chezmoi init --apply rameskum/dotfiles
   ```

   It installs WezTerm, the Nerd Font, starship, fzf and zoxide with WinGet.
3. Open WezTerm.
   It starts `pwsh` and reads `%USERPROFILE%\.wezterm.lua`.

The profile is written to `Documents\PowerShell\profile.ps1`.
If OneDrive redirects your Documents folder, check where `$PROFILE.CurrentUserAllHosts` points, because Microsoft documents that this can break profiles.

### Windows (WSL2 Ubuntu)

Do the Windows steps above (for WezTerm and the font), then inside the WSL2 Ubuntu shell follow the Linux steps 1 to 4.
On WSL the install script skips WezTerm and the font, because the terminal runs on the Windows side.

## Daily use

chezmoi copies files, it does not symlink them. Edit the source, then apply:

```sh
chezmoi edit --apply ~/.zshrc                # edit the source copy and apply it
chezmoi edit --apply ~/.wezterm.lua
chezmoi cd                                   # shell in the clone, to edit anything else, commit and push
chezmoi update                               # on another machine: pull and apply
chezmoi diff                                 # what an apply would change
```

- `.zshrc` and the PowerShell profile are templates. `chezmoi re-add` skips templates, so always change them with `chezmoi edit`.
- Plain files (`~/.wezterm.lua`, `~/.config/starship.toml`, `~/.agents/.skill-lock.json`) can also be edited in place and pulled back with `chezmoi re-add <file>`.

### Aliases

The alias list is `chezmoi/.chezmoidata/aliases.yaml`, defined once.
`.zshrc` turns each entry into a zsh alias; the PowerShell profile turns each into a function that forwards its arguments.
An entry can have `requires: <command>` (only define it when that command exists) and `os: [linux]` (only on those OSes).
Keep `command` to plain words so it is valid in both shells.

After editing the list: `chezmoi apply`.

### Agent skills

- `~/.agents/.skill-lock.json` is tracked: after installing or updating skills, run `chezmoi re-add ~/.agents/.skill-lock.json`.
- My own skills go in `chezmoi/dot_agents/skills/<name>/SKILL.md` in this repo (`chezmoi cd`), and `chezmoi apply` copies them to `~/.agents/skills/`.
- Third-party skills are not stored here. The lockfile records which ones I have, and the skills tool reinstalls them.

### Changing what gets installed

Edit `chezmoi/.chezmoidata/packages.yaml`.
The install scripts are `run_once_`, so they run once per script content.
To run one again after an edit:

```sh
chezmoi state delete-bucket --bucket=scriptState && chezmoi apply
```

Homebrew is called with `--no-upgrade` and without cleanup, so existing packages are left alone.

### Switches

Set these in the environment of the first `chezmoi init`:

| Variable | Effect |
| --- | --- |
| `DOTFILES_SKIP_INSTALL=1` | Do not run the package install script. |
| `DOTFILES_POWERSHELL=1` | Also write the PowerShell profile on macOS and Linux (`~/.config/powershell/profile.ps1`). Windows always gets it. |

They are stored in `~/.config/chezmoi/chezmoi.toml`; re-run `chezmoi init` to change them.

### Try a change without touching your home

```sh
home=$(mktemp -d)
HOME=$home DOTFILES_SKIP_INSTALL=1 chezmoi init --apply --no-tty --source "$PWD"
```

## What stays manual

- The prerequisites above: Homebrew (and the apt packages on Linux), `git`, PowerShell 7 and chezmoi on Windows, `chsh` to zsh.
- WezTerm on Linux.
- Setting the terminal font in anything other than WezTerm (VS Code, Windows Terminal, GNOME Terminal): choose "JetBrainsMono Nerd Font".
- Secrets. Nothing secret is in this repo and nothing is rendered into a file:
  - SSH keys live in the Bitwarden desktop SSH agent. Install Bitwarden by hand and turn the agent on. On Windows, disable the "OpenSSH Authentication Agent" service so Bitwarden can take over the pipe.
  - Infisical is used at runtime: install the CLI and log in. Both shells export `INFISICAL_DOMAIN`.
- Everything out of scope for this minimal setup: git identity, ssh config, GUI apps, language runtimes, VS Code, Neovim and the other tools under `home/`. On Linux those are still handled by the legacy Nix setup below.
- Third-party agent skills (reinstall from the lockfile).

## Checking it works

CI (`.github/workflows/chezmoi.yml`) runs `chezmoi init --apply` from the checkout on `ubuntu-latest`, `macos-latest` and `windows-latest`, then checks:

- the rendered `.wezterm.lua` and `starship.toml` are byte-identical to the source, so the terminal and prompt are the same on every OS;
- every alias is defined in zsh and in PowerShell;
- the starship prompt renders and is hooked into both shells;
- zsh has completion, autosuggestions, syntax highlighting, history search, fzf and zoxide loaded;
- a real interactive session in a pseudo-terminal (`tests/shell-pty.py`) draws the prompt, completes a path with Tab and offers an earlier command as a suggestion, in zsh and in PowerShell (macOS and Linux; on Windows this is the manual check below);
- the Nerd Font is installed (macOS, Linux).

To run the same checks on a machine where you applied the setup:

```sh
tests/verify-zsh.sh                              # macOS, Linux, WSL
pwsh -NoProfile -File tests/verify-pwsh.ps1      # any OS with the PowerShell profile
```

Manual check on Windows (CI cannot drive a console there): open WezTerm, type a command, start typing it again and see the grey suggestion, press Tab and see the completion menu.

Manual check for the Nerd Font in WezTerm (once per OS, especially Windows): open WezTerm and run

```sh
wezterm ls-fonts --text "$(printf '  ')"
```

or just look at the prompt: the OS logo, the branch icon and the `❯` must show as glyphs, not boxes.

## Repo tour

- `.chezmoiroot` - points chezmoi at the `chezmoi/` directory.
- `chezmoi/` - the chezmoi source state:
  - `dot_zshrc.tmpl`, `Documents/PowerShell/profile.ps1.tmpl`, `dot_config/powershell/profile.ps1.tmpl`, `.chezmoitemplates/profile.ps1` - the shell configs.
  - `dot_config/starship.toml`, `dot_wezterm.lua` - the shared prompt and terminal config.
  - `dot_agents/` - the skill lockfile and my own skills.
  - `.chezmoidata/` - aliases, environment variables and package lists.
  - `.chezmoiscripts/` - the per-OS install scripts.
  - `.chezmoi.toml.tmpl`, `.chezmoiignore` - init-time settings and per-OS file selection.
- `tests/` - the checks CI runs: `verify-zsh.sh`, `verify-pwsh.ps1`, `shell-pty.py` (interactive session), `no-secrets.sh`.
- `.github/workflows/chezmoi.yml` - the CI workflow.
- `flake.nix`, `home.nix`, `modules/`, `home/`, `bootstrap.sh`, `rebuild.sh` - the legacy Nix setup.

## Legacy: Nix and Home Manager (Linux)

My Ubuntu setup, managed with Nix and Home Manager.
One repo, one command, and a fresh Ubuntu machine ends up configured the same way every time.
It keeps working untouched until chezmoi replaces it.

**Do not apply both on one machine.**
Home Manager owns `~/.zshrc`, `~/.config/starship.toml` and `~/.config/wezterm` there, and chezmoi writes the same files.
On a machine that still runs Home Manager, apply chezmoi only after removing those from `home.nix`, or apply selected files, such as `chezmoi apply ~/.agents/.skill-lock.json`.

Modeled on [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) (macOS, nix-darwin), adapted for Ubuntu with only what I need.

### What you get

Running the switch builds:

- Nix packages: git, ripgrep, fd, jq, htop, uv, WezTerm, VS Code, JetBrains Mono, Hack Nerd Font
- Homebrew formulae: nvm, wget, gh, opencode, bun, openjdk@25 (`java` and `javac`; the formula is keg-only, so the shell config adds it to `PATH`)
- Shell: zsh (login shell), aliases, and a Starship prompt, plus autosuggestions, syntax highlighting, history substring search, fzf (`Ctrl+R`, `Ctrl+T`), zoxide (`z`), eza (`ls`, `ll`, `lt`), and bat
- Terminal: WezTerm with the Batman color scheme, JetBrains Mono at 13px, and Hack Nerd Font Mono as the icon fallback
- Editor: VS Code with the Docker extension (Container Tools, `ms-azuretools.vscode-containers`) and the same fonts, ligatures on

Anything that can't come from Nix or Homebrew (Brave, 1Password, ...) I install by hand.

### Prerequisites

- Ubuntu 24.04 on x86_64.
- A normal user with `sudo` rights, and `git`: `sudo apt-get install -y git`.

### Fresh-machine setup

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

#### Validate without applying

```sh
nix flake check
nix build ~/.dotfiles#homeConfigurations.ubuntu.activationPackage --dry-run
```

### Daily use

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

### Adding and removing software

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

### Make it yours

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

### Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs and home-manager, holds `user` and the git identity, and declares the `ubuntu` config.
- `home.nix` - user-level config: packages, Homebrew formulae, git, zsh, prompt, and the symlinks described below.
- `modules/homebrew.nix` - implements the `homebrew.*` options.
  It writes `~/.config/homebrew/Brewfile`, then runs `brew bundle install` and `brew bundle cleanup` during the switch.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `bootstrap.sh` - first-time setup.
- `home/` - the actual config files that get symlinked into place.

### How the symlinks work

The files under `home/` are the real files.
Editing them here edits your live config, with no rebuild needed to see the change.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/wezterm` at `~/.dotfiles/home/.config/wezterm`, and `~/.dotfiles` is a symlink to wherever you cloned the repo.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list.

To link another app's config the same way, put it under `home/` and add to `home.nix`:

```nix
home.file.".config/<app>".source =
  config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/<app>";
```

### Troubleshooting

- **`error: path '...' does not exist`**: a new file isn't `git add`-ed.
- **`Existing file '...' would be clobbered`**: move that file out of the way, or keep a backup with `./rebuild.sh -b backup`.
- **WezTerm fails with an EGL/OpenGL error**: the GPU link is stale.
  Run `./rebuild.sh`, which relinks it.
- **WezTerm missing from the app launcher**: log out and back in.
- **`zsh: command not found: java`**: `openjdk@25` installs, but Homebrew does not link versioned JDKs. Open a new terminal after `./rebuild.sh`. `JAVA_HOME` points at the keg's `libexec`.
- **`zsh: command not found: code`**: a VS Code you installed by hand is picked up from `~/.local/bin`, `/usr/share/code/bin`, or `/snap/bin`. Open a new terminal after `./rebuild.sh`.
