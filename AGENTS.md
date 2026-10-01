# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.cleanup = true` in `home.nix` is intentional: every Homebrew formula must be declared, and ad-hoc `brew install`s are removed on rebuild.
- Software comes only from Nix (`home.packages`) or Homebrew formulae. Apps that can't (Brave, 1Password, ...) are installed by hand; don't add apt/system layers for them.
- The only apt packages this repo installs are the prerequisites in `bootstrap.sh`.
- Homebrew casks are macOS-only; don't add a `casks` option.
- The repo can be cloned anywhere; `~/.dotfiles` is a symlink to the clone and all `mkOutOfStoreSymlink` paths go through it.
