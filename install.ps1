#Requires -Version 7
<#
.SYNOPSIS
    Install a DSH agent preset from a bundled persona template.

.DESCRIPTION
    Creates a NEW user preset by cloning a shipped base preset (default:
    standard) and swapping its persona text for a persona template in this
    repo's personas/ directory. The result lands in
    "$HOME\.dsh\.agent-presets\<id>\".

    This is a thin clone-and-go installer: it only needs this script plus the
    persona .md files. It does not depend on the full preset manager.

    A persona file may use the placeholders {{model}} and {{cwd}} — the DSH
    loader substitutes them from the agent's own route and workspace at mount
    time, so leave them verbatim in the template.

.EXAMPLE
    .\install.ps1 -Id thai-coder -PersonaFile personas\thai-coder.md -Name "Thai Coder" -Description "Coding agent ตอบไทย"

.EXAMPLE
    .\install.ps1 -Id thai-coder -From minimal -Name "Thai Coder" -Default
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Id,
    [string]$From = 'standard',
    [string]$PersonaFile = 'personas\thai-coder.md',
    [string]$Name,
    [string]$Description,
    [switch]$Default,
    [string]$HomeOverride
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── paths ────────────────────────────────────────────────────────────────────

function Resolve-DshHome {
    if ($HomeOverride) { return [IO.Path]::GetFullPath($HomeOverride) }
    if ($env:DSH_HOME -and $env:DSH_HOME.Trim()) { return [IO.Path]::GetFullPath($env:DSH_HOME) }
    return Join-Path ([Environment]::GetFolderPath('UserProfile')) '.dsh'
}
$script:DshHome = Resolve-DshHome
$script:UserRoot = Join-Path $script:DshHome '.agent-presets'
$script:SettingsFile = Join-Path $script:DshHome 'settings.yaml'

# Find the shipped base presets beside the installed dsh.
function Find-ShippedRoot {
    $cmd = Get-Command dsh -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) {
        $dir = Split-Path $cmd.Source
        while ($dir -and $dir -ne (Split-Path $dir)) {
            $candidate = Join-Path $dir 'config\agent-presets'
            if (Test-Path $candidate) { return $candidate }
            $dir = Split-Path $dir
        }
    }
    $nvmRoots = @(
        (Join-Path $env:APPDATA 'nvm'),
        (Join-Path ([Environment]::GetFolderPath('UserProfile')) 'AppData\Roaming\nvm')
    ) | Select-Object -Unique | Where-Object { Test-Path $_ }
    foreach ($nvm in $nvmRoots) {
        $hit = Get-ChildItem $nvm -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'node_modules\@deepseek-ai\dsh\config\agent-presets' } |
            Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $null
}
$script:ShippedRoot = Find-ShippedRoot
if (-not $script:ShippedRoot) { throw "Could not locate the DSH install (config\agent-presets). Is 'dsh' on PATH?" }

# ── validation ───────────────────────────────────────────────────────────────

if ($Id -notmatch '^[a-z0-9][a-z0-9-]*$') { throw "invalid preset id '$Id' (must match [a-z0-9][a-z0-9-]*)" }

$sourceDir = Join-Path $script:ShippedRoot $From
if (-not (Test-Path (Join-Path $sourceDir 'agent.cordis.yml'))) {
    throw "base preset '$From' not found under shipped root (looked at $sourceDir)"
}

$dest = Join-Path $script:UserRoot $Id
if (Test-Path $dest) {
    throw "a preset/directory already exists at $dest — delete it first (discovery would list it broken)"
}

$personaPath = if ([IO.Path]::IsPathRooted($PersonaFile)) { $PersonaFile } else { Join-Path $PSScriptRoot $PersonaFile }
if (-not (Test-Path $personaPath)) { throw "persona file not found: $personaPath" }
$persona = (Get-Content $personaPath -Raw -Encoding UTF8).TrimEnd()
if ($persona -eq '') { throw "persona file is empty: $personaPath" }

# ── clone base → new preset ─────────────────────────────────────────────────

New-Item $dest -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $sourceDir '*') $dest -Recurse -Force

# ── rewrite the persona row ──────────────────────────────────────────────────
# Preserves any extra keys on the persona row (e.g. 'complete' / 'includeRuntimeContext'
# on the minimal base) while replacing just the text.

$compPath = Join-Path $dest 'agent.cordis.yml'
$text = Get-Content $compPath -Raw -Encoding UTF8
$pattern = '(?m)^- id:\s*persona\b(?s:.)*?(?=^- |\z)'
$block = [regex]::Match($text, $pattern).Value
if (-not $block) { Remove-Item $dest -Recurse -Force; throw "base preset '$From' has no '- id: persona' row" }

$extraKeys = [regex]::Matches($block, '(?m)^\s{4}(?!text:)([A-Za-z][\w-]*):(?:\s+(\S.*))?$') |
    Where-Object { $_.Groups[1].Value -notin @('name', 'text') }

$nl = [Environment]::NewLine
$sb = [Text.StringBuilder]::new()
[void]$sb.Append("- id: persona$nl")
[void]$sb.Append("  name: '@deepseek-ai/dsh-persona'$nl")
[void]$sb.Append("  config:$nl")
[void]$sb.Append("    text: |$nl")
foreach ($l in ($persona -split "\r?\n")) {
    [void]$sb.Append($(if ($l -eq '') { $nl } else { "      $l$nl" }))
}
foreach ($k in $extraKeys) { [void]$sb.Append("    $($k.Groups[1].Value): $($k.Groups[2].Value)$nl") }

$replacement = $sb.ToString().TrimEnd() + "`n"
$rx = [regex]::new($pattern)
$text = $rx.Replace($text, { param($m) $replacement })
[IO.File]::WriteAllText($compPath, $text, [Text.UTF8Encoding]::new($false))

# ── preset.yml (display metadata) ────────────────────────────────────────────

$metaLines = @()
if ($Name) { $metaLines += "name: $Name" }
if ($Description) { $metaLines += "description: $Description" }
if ($metaLines.Count -gt 0) {
    [IO.File]::WriteAllText(
        (Join-Path $dest 'preset.yml'),
        (($metaLines -join "`n") + "`n"),
        [Text.UTF8Encoding]::new($false)
    )
}

Write-Host "installed preset '$Id' at $dest" -ForegroundColor Green
Write-Host "  base     : $($From) (shipped)" -ForegroundColor DarkGray
Write-Host "  persona  : $($personaPath)" -ForegroundColor DarkGray
if ($Name) { Write-Host "  name     : $Name" -ForegroundColor DarkGray }

# ── optional: set as default for new sessions ────────────────────────────────

function Set-DefaultPreset([string]$PresetId) {
    if (-not (Test-Path $script:SettingsFile)) { throw "settings.yaml not found at $script:SettingsFile" }
    $backup = "$script:SettingsFile.bak-presets"
    Copy-Item $script:SettingsFile $backup -Force
    $lines = [System.Collections.Generic.List[string]](Get-Content $script:SettingsFile -Encoding UTF8)
    $nsIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^agent-presets:\s*$') { $nsIndex = $i; break } }
    if ($nsIndex -ge 0) {
        $done = $false
        for ($i = $nsIndex + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\S') { break }
            if ($lines[$i] -match '^(\s+)default:\s*\S+') { $lines[$i] = "$($Matches[1])default: $PresetId"; $done = $true; break }
        }
        if (-not $done) { $lines.Insert($nsIndex + 1, "  default: $PresetId") }
    } else {
        while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
        $lines.Add('agent-presets:')
        $lines.Add("  default: $PresetId")
    }
    [IO.File]::WriteAllText($script:SettingsFile, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
    Write-Host "default preset -> '$PresetId' (backup: $backup)" -ForegroundColor Green
}

if ($Default) { Set-DefaultPreset $Id }

Write-Host "NOTE: applies to sessions created FROM NOW ON; running/started sessions keep their preset." -ForegroundColor Yellow
