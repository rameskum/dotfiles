# Initial setup

Tested on Ubuntu 24.04 (x86_64). You need a normal user with `sudo` rights.

## 1. Clone

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/rameskum/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

## 2. Personal details

Open `flake.nix` and set:

```nix
username = "rameskum";               # your Linux login name (`whoami`)
gitName = "Ramesh Kumar";
gitEmail = "rameskum.ms@outlook.com";
```

If you skip `username`, `bootstrap.sh` detects the mismatch and offers to
fix it for you.

## 3. Bootstrap

```bash
./bootstrap.sh
```

It asks for your sudo password and then, in order:

1. Checks `username` in `flake.nix` matches `whoami`.
2. Installs apt prerequisites: `curl git gpg zsh build-essential procps file`.
3. Installs [Determinate Nix](https://determinate.systems/nix) (skipped if `nix` exists).
4. Installs Homebrew to `/home/linuxbrew/.linuxbrew` (skipped if present).
5. Runs `./rebuild.sh`:
   - `home-manager switch` builds and activates `home/`. Dotfiles it would
     overwrite (Ubuntu ships a default `~/.bashrc` and `~/.profile`) are
     renamed to `*.hm-backup`.
   - Home Manager's activation runs `brew bundle` to install the formulae.
   - `ubuntu/apt-sync.sh` adds the Brave, 1Password and WezTerm apt repos and
     installs them.
6. Makes `/usr/bin/zsh` your login shell (`chsh`).

Every step is safe to re-run.

## 4. Log out and back in

The new login shell and desktop entries take effect after a new session.
Then:

- Open **WezTerm**. You should see the Starship prompt in the Hack Nerd Font.
- Open **1Password**, sign in, then install the 1Password extension in
  **Brave**. They connect automatically because both come from the official
  `.deb` packages.

## Day-to-day

```bash
cd ~/.dotfiles
$EDITOR home/packages.nix   # or any other file
git add -A                  # flakes only see files tracked by git
./rebuild.sh                # or `rebuild` from any directory
```

Update everything:

```bash
nix flake update && ./rebuild.sh   # newer nixpkgs / home-manager
brew upgrade                       # brew formulae
sudo apt update && sudo apt upgrade   # apt apps (also done by Ubuntu's updater)
```

Roll back a bad Home Manager change:

```bash
home-manager generations            # list
/nix/store/<hash>-home-manager-generation/activate   # activate an older one
```

## Troubleshooting

**`error: path '.../foo.nix' does not exist`**: you created a file but didn't
`git add` it. Nix flakes ignore untracked files.

**`Existing file '...' is in the way`**: something outside Home Manager
created that file. `rebuild.sh` moves such files to `*.hm-backup`; if a
backup with that name already exists, delete the old backup and re-run.

**`Homebrew not found ... skipping formulae`**: brew isn't installed at
`/home/linuxbrew/.linuxbrew`. Re-run `./bootstrap.sh`.

**zsh isn't the shell after bootstrap**: log out fully (not just close the
terminal). Check with `getent passwd $USER | cut -d: -f7`.

**`nix: command not found` in a new terminal**: open a new login session.
The Nix installer hooks `/etc/profile.d` and `/etc/zsh/zshrc`.

**apt says `Conflicting values set for option Signed-By`**: the same repo is
configured twice, usually from an earlier manual install. Remove the
duplicate file in `/etc/apt/sources.list.d/` (keep the one named in
`ubuntu/apt-apps.sh`) and re-run `./rebuild.sh`.
