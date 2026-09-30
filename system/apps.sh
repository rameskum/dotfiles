# apt apps: only for software that can't work properly from Nix. Everything
# else goes in home.nix. Sourced by system/sync.sh, which ./rebuild.sh runs.
#
#   Add an app:    add an `app` block below, then run ./rebuild.sh
#   Remove an app: delete its block, then run ./rebuild.sh
#                  (the package is purged and its repo + key are deleted)
#
# app <apt package>
#     --key     <URL of the repo signing key, armored or binary>
#     --keyring <where the key is stored>
#     --source  <deb822 .sources file in /etc/apt/sources.list.d/>
#     --repo    <"URI suite components..." as in a `deb` line>
#
# Use the keyring and .sources names from the vendor's install docs: some
# packages rewrite their own repo file on install/upgrade, and apt refuses to
# run if the same repo is configured twice with different keys.
# $ARCH is the dpkg architecture (amd64, arm64).
# Packages from Ubuntu's own archive only need `app <package>`.

# Browser integration needs a setgid helper and system unlock needs a polkit
# policy, neither of which Home Manager can install outside NixOS.
app 1password \
  --key https://downloads.1password.com/linux/keys/1password.asc \
  --keyring /usr/share/keyrings/1password-archive-keyring.gpg \
  --source 1password.sources \
  --repo "https://downloads.1password.com/linux/debian/$ARCH stable main"
