# Project notes for agents

Deliberate decisions in this repo. Do NOT silently revert them:

- `homebrew.cleanup = true` in `home.nix` is intentional: every Homebrew formula must be declared, and ad-hoc `brew install`s are removed on rebuild.
- GUI apps come from Nix (`home.packages`), not Homebrew. Casks are macOS-only.
- 1Password stays on apt (`system/apps.sh`). The Nix build can't provide the setgid browser helper or the polkit policy outside NixOS.
- Anything that needs root lives in `system/` and runs from `rebuild.sh`, never from a Home Manager activation script.
- Chromium and Electron apps from Nix need an AppArmor profile in `system/apparmor/` on Ubuntu 24.04+.
