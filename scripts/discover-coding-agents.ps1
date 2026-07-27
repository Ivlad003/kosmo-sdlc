#Requires -Version 5.1
<#
.SYNOPSIS
  Dynamically discover coding-agent CLIs on PATH and write inventory for AI judge.
#>
param(
  [string]$OutDir = "_",
  [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Continue"
Set-Location $ProjectRoot

$catalog = @(
  @{ id = "grok";     family = "grok";     binaries = @("grok");                   headless = 'grok -p "{prompt}"';                   code = 'grok -p "{prompt}"' }
  @{ id = "claude";   family = "claude";   binaries = @("claude");                 headless = 'claude -p --bare "{prompt}"';          code = 'claude -p --bare "{prompt}"' }
  @{ id = "codex";    family = "codex";    binaries = @("codex");                  headless = 'codex exec "{prompt}"';                code = 'codex review' }
  @{ id = "copilot";  family = "copilot";  binaries = @("copilot");                headless = 'copilot -p "{prompt}"';                code = 'copilot -p "{prompt}"' }
  @{ id = "gemini";   family = "gemini";   binaries = @("gemini");                 headless = 'gemini -p "{prompt}"';                code = 'gemini -p "{prompt}"' }
  @{ id = "aider";    family = "aider";    binaries = @("aider");                  headless = 'aider --yes --message "{prompt}"';    code = 'aider --yes --message "{prompt}"' }
  @{ id = "cursor";   family = "cursor";   binaries = @("cursor-agent", "cursor"); headless = 'cursor-agent -p "{prompt}"';           code = 'cursor-agent -p "{prompt}"' }
  @{ id = "opencode"; family = "opencode"; binaries = @("opencode");               headless = 'opencode run "{prompt}"';              code = 'opencode run "{prompt}"' }
  @{ id = "amp";      family = "amp";      binaries = @("amp");                    headless = 'amp -p "{prompt}"';                   code = 'amp -p "{prompt}"' }
  @{ id = "qwen";     family = "qwen";     binaries = @("qwen");                   headless = 'qwen -p "{prompt}"';                  code = 'qwen -p "{prompt}"' }
)

function Test-Binary([string]$name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $c) { return $null }
  $ver = $null
  try {
    $out = & $name --version 2>&1 | Select-Object -First 1
    if ($out) { $ver = ("$out").Trim() }
  } catch {}
  return [pscustomobject]@{ path = $c.Source; version = $ver }
}

function Get-HostFamily {
  if ($env:GROK_SESSION_ID) { return "grok" }
  if ($env:CLAUDECODE -or $env:CLAUDE_CODE_ENTRYPOINT) { return "claude" }
  if ($env:CODEX_HOME -and $env:CODEX_CI) { return "codex" }
  if ($env:CURSOR_TRACE_ID) { return "cursor" }
  try {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue
    $depth = 0
    while ($p -and $depth -lt 8) {
      $name = ("$($p.Name) $($p.CommandLine)").ToLowerInvariant()
      if ($name -match "grok") { return "grok" }
      if ($name -match "claude") { return "claude" }
      if ($name -match "codex") { return "codex" }
      if ($name -match "cursor") { return "cursor" }
      if (-not $p.ParentProcessId -or $p.ParentProcessId -eq 0) { break }
      $p = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.ParentProcessId)" -ErrorAction SilentlyContinue
      $depth++
    }
  } catch {}
  return "unknown"
}

$found = New-Object System.Collections.Generic.List[object]
foreach ($entry in $catalog) {
  $hit = $null
  $binUsed = $null
  foreach ($b in $entry.binaries) {
    $hit = Test-Binary $b
    if ($hit) { $binUsed = $b; break }
  }
  if (-not $hit) { continue }
  $found.Add([pscustomobject]@{
    id          = $entry.id
    family      = $entry.family
    binary      = $binUsed
    path        = $hit.path
    version     = $hit.version
    headless    = $entry.headless
    code_review = $entry.code
    available   = $true
  }) | Out-Null
}

if (-not ($found | Where-Object { $_.id -eq "copilot" })) {
  $gh = Test-Binary "gh"
  if ($gh) {
    $ext = ""
    try { $ext = (& gh extension list 2>&1 | Out-String) } catch {}
    if ($ext -match "copilot") {
      $found.Add([pscustomobject]@{
        id = "copilot"; family = "copilot"; binary = "gh"
        path = $gh.path; version = $gh.version
        headless = 'gh copilot suggest -t shell "{prompt}"'
        code_review = "gh copilot explain"
        available = $true
      }) | Out-Null
    }
  }
}

$hostFamily = Get-HostFamily
$peers = @($found | Where-Object { $_.family -ne $hostFamily } | ForEach-Object { $_.id })
$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

if (-not (Test-Path $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$agentsArr = @()
foreach ($a in $found) {
  $agentsArr += @{
    id = $a.id; family = $a.family; binary = $a.binary
    path = $a.path; version = $a.version
    headless = $a.headless; code_review = $a.code_review
    available = $true
  }
}
$jsonObj = @{
  discovered_at = $ts
  host_family   = $hostFamily
  project_root  = $ProjectRoot
  judge_peers   = @($peers)
  agents        = $agentsArr
}
$jsonPath = Join-Path $OutDir "coding-agents.json"
$jsonObj | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8

$peerLine = if ($peers.Count -gt 0) {
  ($peers | ForEach-Object { '`' + $_ + '`' }) -join ", "
} else {
  "_none - install another CLI_"
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Coding agents inventory")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Auto-generated by ``scripts/discover-coding-agents.ps1`` (or ``/kosmo-sdlc:discover-agents``).")
[void]$sb.AppendLine("Used by **ai-judge** for multi-CLI peer selection.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **discovered_at:** $ts")
[void]$sb.AppendLine("- **host_family:** ``$hostFamily``")
[void]$sb.AppendLine("- **judge_peers (exclude host):** $peerLine")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Available agents")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| id | family | binary | version | headless |")
[void]$sb.AppendLine("| --- | --- | --- | --- | --- |")
foreach ($a in $found) {
  $ver = if ($a.version) { ($a.version -replace '\|', '/') } else { "-" }
  $hl = if ($a.headless) { '`' + $a.headless + '`' } else { "interactive only" }
  [void]$sb.AppendLine("| ``$($a.id)`` | ``$($a.family)`` | ``$($a.binary)`` | $ver | $hl |")
}
if ($found.Count -eq 0) {
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("_No coding-agent CLIs found on PATH._")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Judge policy")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("1. Prefer peers whose ``family`` is not equal to ``host_family``.")
[void]$sb.AppendLine("2. Need at least 2 peers for multi-judge; else warn.")
[void]$sb.AppendLine("3. Re-run after installing a CLI: ``/kosmo-sdlc:discover-agents``.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Machine paths")
[void]$sb.AppendLine("")
foreach ($a in $found) {
  [void]$sb.AppendLine("- **$($a.id):** ``$($a.path)``")
}
[void]$sb.AppendLine("")

$mdPath = Join-Path $OutDir "coding-agents.md"
$sb.ToString() | Set-Content -Path $mdPath -Encoding UTF8

Write-Host "Wrote $mdPath"
Write-Host "Wrote $jsonPath"
Write-Host ("host_family={0} peers={1}" -f $hostFamily, ($peers -join ","))
exit 0
