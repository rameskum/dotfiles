# Checks an applied PowerShell 7 setup (Windows, or macOS/Linux applied with
# DOTFILES_POWERSHELL=1). Run it with pwsh after `chezmoi init --apply`:
#
#   pwsh -NoProfile -File tests/verify-pwsh.ps1
#
# $env:DOTFILES_SRC is the chezmoi source checkout (default: this repo).
$ErrorActionPreference = 'Stop'

$src = if ($env:DOTFILES_SRC) { $env:DOTFILES_SRC } else { Split-Path -Parent $PSScriptRoot }
$home_ = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
$failures = 0

function Pass($msg) { Write-Host "ok   $msg" }
function Fail($msg) { Write-Host "FAIL $msg"; $script:failures++ }
function Same($a, $b) { (Get-FileHash $a).Hash -eq (Get-FileHash $b).Hash }

# The profile lives where each OS looks for it.
$profilePath = if ($IsWindows) {
    Join-Path $home_ 'Documents/PowerShell/profile.ps1'
} else {
    Join-Path $home_ '.config/powershell/profile.ps1'
}
if (-not (Test-Path $profilePath)) { Write-Host "FAIL $profilePath missing"; exit 1 }
Pass "profile present at $profilePath"

# Files: same bytes as the source, so every OS gets the same terminal and prompt.
if (Same "$src/chezmoi/dot_wezterm.lua" (Join-Path $home_ '.wezterm.lua')) { Pass '.wezterm.lua matches source' } else { Fail '.wezterm.lua differs from source' }
if (Same "$src/chezmoi/dot_config/starship.toml" (Join-Path $home_ '.config/starship.toml')) { Pass 'starship.toml matches source' } else { Fail 'starship.toml differs from source' }
if (Test-Path (Join-Path $home_ '.agents/.skill-lock.json')) { Pass 'skill lockfile present' } else { Fail 'skill lockfile missing' }

# Aliases that apply here, and the command each one needs.
$aliases = Get-Content -Raw "$src/tests/aliases.tmpl" | chezmoi --source $src execute-template |
    Where-Object { $_ } |
    ForEach-Object { $name, $requires = $_ -split "`t"; [pscustomobject]@{ Name = $name; Requires = $requires } }

# Load the profile in a clean child shell, the way a new terminal would, and
# print what it defined.
$probeFile = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-probe-$PID.ps1"
@'
$ErrorActionPreference = 'Stop'
. $args[0]
foreach ($a in ($args[1] -split ',')) {
    $c = Get-Command $a -ErrorAction SilentlyContinue | Select-Object -First 1
    "alias`t$a`t$($c.CommandType)"
}
"prompt`t$((Get-Command prompt).Definition.Contains('starship'))"
"infisical`t$env:INFISICAL_DOMAIN"
'@ | Set-Content -Path $probeFile
$names = ($aliases | ForEach-Object Name) -join ','
$out = & pwsh -NoProfile -NonInteractive -File $probeFile $profilePath $names 2>&1
Remove-Item $probeFile -Force
if ($LASTEXITCODE -ne 0) { Fail "profile failed to load: $out" } else { Pass 'profile loads with no errors' }

foreach ($a in $aliases) {
    $line = $out | Where-Object { $_ -like "alias`t$($a.Name)`t*" }
    $type = ($line -split "`t")[2]
    if ($a.Requires -and -not (Get-Command $a.Requires -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Host "skip alias $($a.Name) ($($a.Requires) not installed)"
    } elseif ($type -eq 'Function') {
        Pass "alias $($a.Name)"
    } else {
        Fail "alias $($a.Name) is '$type', expected Function"
    }
}

if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
    if ($out -contains "prompt`tTrue") { Pass 'starship prompt hooked in' } else { Fail 'prompt function is not starship' }
    $prompt = & starship prompt 2>&1 | Out-String
    if ($prompt.Contains([string][char]0x276F)) { Pass 'starship prompt renders' } else { Fail "starship prompt has no prompt character: $prompt" }
} else {
    Fail 'starship not installed'
}
if ($out -contains "infisical`thttps://secrets.labgrid.dev/api") { Pass 'INFISICAL_DOMAIN set' } else { Fail 'INFISICAL_DOMAIN not set' }
foreach ($tool in 'fzf', 'zoxide') {
    if (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue) { Pass "$tool installed" } else { Fail "$tool not installed" }
}

# A real interactive session in a pseudo-terminal (PSReadLine suggestions, Tab
# menu, prompt). Needs a pty, so macOS and Linux only; on Windows this is the
# manual check in the README.
if (-not $IsWindows -and (Get-Command python3 -CommandType Application -ErrorAction SilentlyContinue)) {
    & python3 "$src/tests/shell-pty.py" pwsh
    if ($LASTEXITCODE -eq 0) { Pass 'interactive pwsh session' } else { Fail 'interactive pwsh session' }
}

if ($failures -ne 0) { Write-Host "$failures check(s) failed"; exit 1 }
Write-Host 'all PowerShell checks passed'
