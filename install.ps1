#!/usr/bin/env pwsh
# dev-rigor-stack installer (Windows PowerShell / PowerShell 7+).
# Copies the vendored skills into your agent's skills directory.
#
# Usage:
#   ./install.ps1                                  # -> $env:CLAUDE_CONFIG_DIR\skills or ~\.claude\skills
#   ./install.ps1 -Target ~/.codex/skills          # install somewhere else (e.g. Codex)
#   ./install.ps1 -WithPonytail                    # also fetch the optional ponytail lane from its repo
#
# Re-running updates in place (each skill is replaced). No path assumptions.
# NOTE: kept ASCII-only on purpose -- Windows PowerShell 5.1 reads a BOM-less script as
# ANSI, so non-ASCII characters (em dashes, smart quotes) would break the parser.
[CmdletBinding()]
param(
  [switch]$WithPonytail,
  [string]$Target
)
$ErrorActionPreference = 'Stop'

$SkillsSrc = Join-Path $PSScriptRoot 'skills'
if (-not (Test-Path $SkillsSrc)) {
  throw "no skills/ directory found next to this script ($SkillsSrc)"
}

if ($Target) {
  $Dest = $Target
} else {
  $DestRoot = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
  $Dest = Join-Path $DestRoot 'skills'
}

New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Write-Host "Installing dev-rigor-stack skills -> $Dest`n"

$installed = 0
foreach ($src in Get-ChildItem -Directory $SkillsSrc) {
  $target = Join-Path $Dest $src.Name
  if (Test-Path $target) { Remove-Item -Recurse -Force $target }
  Copy-Item -Recurse $src.FullName $target
  if (Test-Path (Join-Path $target 'SKILL.md')) {
    Write-Host "  ok    $($src.Name)"
    $installed++
  } else {
    throw "FAIL $($src.Name): no SKILL.md landed"
  }
}

Write-Host "`nInstalled $installed stack skill(s) to $Dest"

if ($WithPonytail) {
  Write-Host "`nFetching ponytail (third-party - DietrichGebert, MIT) from github.com/DietrichGebert/ponytail ..."
  $git = Get-Command git -ErrorAction SilentlyContinue
  if (-not $git) {
    Write-Host "  WARN  git not found - skipped ponytail. Your $installed stack skill(s) installed fine."
    Write-Host "        Add it later from https://github.com/DietrichGebert/ponytail"
  } else {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ponytail-" + [System.IO.Path]::GetRandomFileName())
    try {
      git clone --depth 1 --quiet "https://github.com/DietrichGebert/ponytail" $tmp
      if ($LASTEXITCODE -ne 0) { throw "clone failed (git exit $LASTEXITCODE)" }
      $psrc = Join-Path $tmp 'skills'
      if (-not (Test-Path $psrc)) { throw "no skills/ directory in the ponytail repo" }
      $pcount = 0
      foreach ($pd in Get-ChildItem -Directory $psrc) {
        $pt = Join-Path $Dest $pd.Name
        if (Test-Path $pt) { Remove-Item -Recurse -Force $pt }
        Copy-Item -Recurse $pd.FullName $pt
        if (Test-Path (Join-Path $pt 'SKILL.md')) { Write-Host "  ok    $($pd.Name)"; $pcount++ }
      }
      Write-Host "  added $pcount ponytail skill(s) - skills only; always-on hooks NOT wired (see its repo for those)."
    } catch {
      Write-Host "  WARN  couldn't fetch ponytail ($($_.Exception.Message)) - skipped."
      Write-Host "        Your $installed stack skill(s) installed fine. Add it later from"
      Write-Host "        https://github.com/DietrichGebert/ponytail"
    } finally {
      if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
    }
  }
}

Write-Host "`nNext steps:"
if (-not $WithPonytail) {
  Write-Host "  * ponytail (the code-minimalism / anti-bloat lane) is a separate third-party plugin"
  Write-Host "    by DietrichGebert - not bundled. Re-run with  -WithPonytail  to fetch it, or install"
  Write-Host "    it yourself. The stack works without it; you lose only the 'what can I delete' discipline."
}
Write-Host "  * Optional: fold config/CLAUDE.md into your own ~/.claude/CLAUDE.md so the stack applies"
Write-Host "    automatically. Review it first -- do not blindly overwrite your existing CLAUDE.md."
Write-Host "  * Restart your agent (or reload skills) so it picks up the new skills."
