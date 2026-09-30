# GUI apps installed from their vendors' official apt repositories.
# Sourced by ubuntu/apt-sync.sh, which ./rebuild.sh runs after Home Manager.
#
#   Add an app:    add an `app` block below, then run ./rebuild.sh
#   Remove an app: delete its block, then run ./rebuild.sh
#                  (the package is purged and its repo + key are deleted)
#
# app <apt package>
#     --key     <URL of the repo signing key, armored or binary>
#     --keyring <where the key is stored>
#     --source  <file in /etc/apt/sources.list.d/>
#     --repo    <"URI suite component..." part of the deb line>
#
# Use the keyring and source paths from the vendor's install docs: some
# packages rewrite their own repo entry on upgrade, and apt refuses to run
# if the same repo appears twice with different keys.
# $ARCH is the dpkg architecture (amd64, arm64).
# Packages from Ubuntu's own archive only need `app <package>`.

app brave-browser \
  --key https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
  --keyring /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  --source brave-browser-release.list \
  --repo "https://brave-browser-apt-release.s3.brave.com/ stable main"

app 1password \
  --key https://downloads.1password.com/linux/keys/1password.asc \
  --keyring /usr/share/keyrings/1password-archive-keyring.gpg \
  --source 1password.list \
  --repo "https://downloads.1password.com/linux/debian/$ARCH stable main"

app wezterm \
  --key https://apt.fury.io/wez/gpg.key \
  --keyring /usr/share/keyrings/wezterm-fury.gpg \
  --source wezterm.list \
  --repo "https://apt.fury.io/wez/ * *"
