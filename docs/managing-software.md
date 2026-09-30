# Managing software

Each app belongs to exactly one layer. Decide which with this order:

1. **Nix** (`home/packages.nix`): the default for CLI tools and fonts.
   Search on [search.nixos.org](https://search.nixos.org/packages).
2. **Homebrew** (`home/homebrew.nix`): CLI tools that aren't in nixpkgs, are
   outdated there, or that you prefer from brew. Formulae only; casks don't
   work on Linux.
3. **apt** (`ubuntu/apt-apps.sh`): GUI desktop apps, ideally from the
   vendor's own apt repo.

After any change: `git add -A && ./rebuild.sh`.

## What gets removed automatically

| Layer | Removed on rebuild |
| --- | --- |
| Nix | Everything not listed. Nothing survives outside the config. |
| Homebrew | Every formula and tap not listed, **including ones you installed by hand with `brew install`**. Dependencies of listed formulae are kept. |
| apt | Apps you removed from `apt-apps.sh`, with their repo and key. Packages you installed yourself with `apt install` are **never** touched. |

To try a brew formula without it being wiped on the next rebuild, add it to
`home/homebrew.nix` first. For a one-off, use `nix shell nixpkgs#<pkg>`,
which installs nothing permanently.

---

## Nix packages

Add, in `home/packages.nix`:

```nix
home.packages = with pkgs; [
  git
  ripgrep
  btop        # new
];
```

Remove: delete the line and rebuild. Home Manager also has `programs.<name>`
modules that install **and** configure a tool (see `home/shell.nix` for
`programs.fzf`, `programs.eza`, …). Prefer those when one exists; search
options at [home-manager-options.extranix.com](https://home-manager-options.extranix.com).

Unfree packages (e.g. `vscode`, `slack`) need this in `home/default.nix`:

```nix
nixpkgs.config.allowUnfree = true;
```

## Homebrew formulae

Add, in `home/homebrew.nix`:

```nix
formulae = [
  "nvm"
  "wget"
  "gh"
  "terraform"      # new
];
```

From a tap:

```nix
taps = [ "hashicorp/tap" ];
formulae = [ "hashicorp/tap/terraform" ];
```

Remove: delete the line and rebuild. The activation runs
`brew bundle cleanup --formula --tap --force` against the generated Brewfile
(`~/.config/homebrew/Brewfile`), which uninstalls it.

Preview what cleanup would remove without doing it:

```bash
brew bundle cleanup --file ~/.config/homebrew/Brewfile --formula --tap
```

To stop brew from removing unlisted formulae, set `homebrew.cleanup = false;`.

Upgrading is never automatic, so rebuilds stay fast. Run `brew upgrade`
when you want new versions.

## apt apps (GUI)

Brave, 1Password and WezTerm live in `ubuntu/apt-apps.sh`:

```bash
app wezterm \
  --key https://apt.fury.io/wez/gpg.key \
  --keyring /usr/share/keyrings/wezterm-fury.gpg \
  --source wezterm.sources \
  --repo "https://apt.fury.io/wez/ * *"
```

`apt-sync.sh` writes each repo as a deb822 file,
`/etc/apt/sources.list.d/<--source>`, signed by `<--keyring>`.

### Add an app from a vendor repo

Find the vendor's "install on Debian/Ubuntu" instructions. They always give
a signing-key URL and a repo (either a `deb [...] URI suite component` line
or a `.sources` file with `URIs:`/`Suites:`/`Components:`). Copy them
into a new block, keeping the vendor's keyring path and sources file name.
Some packages rewrite their own repo file on install (1Password does), and
apt fails if the same repo appears twice with different keys. Example,
VS Code (tested):

```bash
app code \
  --key https://packages.microsoft.com/keys/microsoft.asc \
  --keyring /usr/share/keyrings/microsoft.gpg \
  --source vscode.sources \
  --repo "https://packages.microsoft.com/repos/code stable main"
```

Use `$ARCH` in `--repo` where the vendor URL contains `amd64`/`arm64`.

### Add an app from Ubuntu's own archive

```bash
app vlc
```

### Remove an app

Delete its block and rebuild. `apt-sync.sh` runs
`apt-get purge --autoremove <pkg>`, deletes the repo's sources file and
signing key, and runs `apt update`. It only removes apps it installed
(tracked in `~/.local/state/dotfiles/apt-apps.tsv`).

### Remove something installed by hand

These aren't tracked, so remove them yourself:

```bash
sudo apt purge --autoremove <package>
ls /etc/apt/sources.list.d/        # delete the repo file if it added one
snap list && sudo snap remove <name>
flatpak list && flatpak uninstall <app-id>
```

## Config for apps

App config (dotfiles) belongs in Home Manager even when the app comes from
apt. WezTerm is the example: `home/wezterm.nix` writes
`~/.config/wezterm/wezterm.lua`. Add more with:

```nix
xdg.configFile."myapp/config.toml".text = ''
  ...
'';
```
