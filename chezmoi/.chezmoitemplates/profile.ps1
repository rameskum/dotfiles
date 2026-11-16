# Managed by chezmoi (rameskum/dotfiles). Edit with `chezmoi edit --apply <this file>`.
# PowerShell 7 profile. The zsh equivalent is ~/.zshrc; both read the same alias
# list (chezmoi/.chezmoidata/aliases.yaml) and the same ~/.config/starship.toml.

{{ range $name, $value := .env -}}
$env:{{ $name }} = {{ $value | squote }}
{{ end }}
# Suggestions from history, Tab opens a completion menu, Ctrl+F accepts a
# suggestion (like zsh-autosuggestions), Up/Down search history by prefix.
# Skipped quietly when there is no real console (CI, redirected output).
if (Get-Module -ListAvailable -Name PSReadLine) {
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle InlineView
        Set-PSReadLineOption -HistoryNoDuplicates -HistorySearchCursorMovesToEnd
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardChar
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    } catch {
        $null = $_
    }
}

# Aliases. PowerShell aliases cannot carry arguments, so each one is a function
# that forwards them. Built-in aliases of the same name (cat, ...) are removed
# first because aliases win over functions.
{{ range (includeTemplate "aliases.json" . | fromJson) -}}
{{   $requires := get . "requires" -}}
{{   if $requires }}if (Get-Command {{ $requires }} -CommandType Application -ErrorAction SilentlyContinue) { {{ end -}}
{{ if regexMatch "^[A-Za-z]" .name }}Remove-Item -Path 'Alias:{{ .name }}' -Force -ErrorAction SilentlyContinue; {{ end }}function {{ .name }} { {{ .command }} @args }
{{-  if $requires }} }{{ end }}
{{ end }}
# fzf: Ctrl+R searches history, Ctrl+T inserts a file path.
if (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue) {
    try {
        Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
            $historyFile = (Get-PSReadLineOption).HistorySavePath
            if (-not (Test-Path $historyFile)) { return }
            $lines = @(Get-Content $historyFile | Where-Object { $_ })
            [array]::Reverse($lines)
            $pick = $lines | Select-Object -Unique | fzf --height=40% --reverse --no-sort
            if ($pick) {
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($pick)
            }
        }
        Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock {
            $pick = fzf --height=40% --reverse
            if ($pick) { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($pick) }
        }
    } catch {
        $null = $_
    }
}

# zoxide (`z`), then the prompt last.
if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}
if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
