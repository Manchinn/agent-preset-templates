#Requires -Version 7
<#
.SYNOPSIS
    Self-test for install.ps1. Runs the real installer against a synthetic base
    preset in a temp home and asserts the shape of the output preset.

.DESCRIPTION
    Used locally and by CI (.github/workflows/test.yml). It does NOT need a DSH
    install: it builds a fake base preset (mirroring standard's agent.cordis.yml
    shape), runs install.ps1 against it with -BaseDir and a -HomeOverride, then
    asserts:
      - the persona row is replaced with the persona text (REPLACE_ME gone)
      - {{model}} and {{cwd}} are preserved
      - sibling rows (tool-fs, tool-web) are preserved
      - preset.yml metadata is written
      - -Default updates settings.yaml

.EXAMPLE
    pwsh ./test-install.ps1   # exit 0 = pass, 1 = fail
#>
[CmdletBinding()]
param()
$script:PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERT FAILED: $Message" }
}

$fail = 0
try {
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ('dsh-preset-test-' + [guid]::NewGuid().ToString('N'))
    try {
        # ── synthetic base preset (same row shape as `standard`) ────────────
        $base = Join-Path $tmp 'base' 'standard'
        New-Item $base -ItemType Directory -Force | Out-Null
        $baseComp = @'
# synthetic base for install.ps1 self-test
- id: persona
  name: '@deepseek-ai/dsh-persona'
  config:
    text: >-
      REPLACE_ME

- id: tool-fs
  name: '@deepseek-ai/dsh-tool-fs'

- id: tool-web
  name: '@deepseek-ai/dsh-tool-web'
  config:
    fetch: false
'@
        [IO.File]::WriteAllText((Join-Path $base 'agent.cordis.yml'), $baseComp.TrimStart() + "`n", [Text.UTF8Encoding]::new($false))

        $tmpHome = Join-Path $tmp 'home'
        $personaFile = Join-Path $script:PSScriptRoot 'personas' 'thai-coder.md'
        Assert (Test-Path $personaFile) "persona fixture missing: $personaFile"
        $personaText = (Get-Content $personaFile -Raw -Encoding UTF8).TrimEnd()

        $install = Join-Path $script:PSScriptRoot 'install.ps1'

        # ── run install (persona op) ────────────────────────────────────────
        & $install -Id thai-coder -BaseDir $base -PersonaFile $personaFile `
            -Name "Thai Coder" -Description "CI test" -HomeOverride $tmpHome | Out-Null

        $dest = Join-Path $tmpHome '.agent-presets' 'thai-coder'
        $comp = Join-Path $dest 'agent.cordis.yml'
        Assert (Test-Path $comp) "agent.cordis.yml not written at $dest"
        $raw = Get-Content $comp -Raw -Encoding UTF8

        Assert ($raw -notmatch 'REPLACE_ME') "persona text was not replaced (REPLACE_ME still present)"
        Assert ($raw -match 'ตอบเป็นภาษาไทยเป็นหลัก') "persona Thai text missing from output"
        Assert ($raw -match '\{\{model\}\}') "{{model}} placeholder lost"
        Assert ($raw -match '\{\{cwd\}\}') "{{cwd}} placeholder lost"
        Assert ($raw -match 'dsh-tool-fs') "sibling row tool-fs was dropped"
        Assert ($raw -match 'dsh-tool-web') "sibling row tool-web was dropped"

        $meta = Join-Path $dest 'preset.yml'
        Assert (Test-Path $meta) "preset.yml not written"
        $metaRaw = Get-Content $meta -Raw -Encoding UTF8
        Assert ($metaRaw -match 'name: Thai Coder') "preset.yml name missing"
        Assert ($metaRaw -match 'description: CI test') "preset.yml description missing"

        # ── run install with -Default (settings.yaml side-effect) ──────────
        $settings = Join-Path $tmpHome 'settings.yaml'
        [IO.File]::WriteAllText($settings, "profiles:`n  active: default`nagent-presets:`n  default: standard`n", [Text.UTF8Encoding]::new($false))
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        & $install -Id thai-coder -BaseDir $base -PersonaFile $personaFile `
            -Name "Thai Coder" -HomeOverride $tmpHome -Default | Out-Null
        $settingsRaw = Get-Content $settings -Raw -Encoding UTF8
        Assert ($settingsRaw -match '(?m)^\s*default:\s*thai-coder') "-Default did not set default: thai-coder in settings.yaml"

        Write-Host "PASS: install.ps1 self-test" -ForegroundColor Green
    } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
    }
} catch {
    Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $fail = 1
}
exit $fail
