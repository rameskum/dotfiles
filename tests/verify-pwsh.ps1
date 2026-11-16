# Checks an applied PowerShell 7 setup on Windows. Run it with pwsh after
# `chezmoi init --apply`:
#
#   pwsh -NoProfile -File tests/verify-pwsh.ps1
#
# $env:DOTFILES_SRC is the chezmoi source checkout (default: this repo).
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()

$src =if ($env:DOTFILES_SRC) { $env:DOTFILES_SRC } else { Split-Path -Parent $PSScriptRoot }
$failures = 0

function Pass($msg) { Write-Host "ok   $msg" }
function Fail($msg) { Write-Host "FAIL $msg"; $script:failures++ }
function Same($a, $b) { (Get-FileHash $a).Hash -eq (Get-FileHash $b).Hash }

$profilePath = Join-Path $HOME 'Documents/PowerShell/profile.ps1'
if (-not (Test-Path $profilePath)) { Write-Host "FAIL $profilePath missing"; exit 1 }
Pass "profile present at $profilePath"

# Files: same bytes as the source, so every OS gets the same terminal and prompt.
if (Same "$src/chezmoi/dot_wezterm.lua" (Join-Path $HOME '.wezterm.lua')) { Pass '.wezterm.lua matches source' } else { Fail '.wezterm.lua differs from source' }
if (Same "$src/chezmoi/dot_config/starship.toml" (Join-Path $HOME '.config/starship.toml')) { Pass 'starship.toml matches source' } else { Fail 'starship.toml differs from source' }
if (Test-Path (Join-Path $HOME '.agents/.skill-lock.json')) { Pass 'skill lockfile present' } else { Fail 'skill lockfile missing' }

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
    # The Windows logo comes from the os module, which is off in starship's
    # defaults, so it proves starship.toml took effect.
    $prompt = & starship prompt 2>&1 | Out-String
    if ($prompt.Contains([string][char]0xF17A)) { Pass 'starship prompt uses starship.toml (OS symbol)' } else { Fail "starship prompt has no OS symbol from starship.toml: $prompt" }
} else {
    Fail 'starship not installed'
}
if ($out -contains "infisical`thttps://secrets.labgrid.dev/api") { Pass 'INFISICAL_DOMAIN set' } else { Fail 'INFISICAL_DOMAIN not set' }
foreach ($tool in 'fzf', 'zoxide') {
    if (Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue) { Pass "$tool installed" } else { Fail "$tool not installed" }
}

if ($failures -ne 0) { Write-Host "$failures check(s) failed"; exit 1 }
Write-Host 'all PowerShell checks passed'
