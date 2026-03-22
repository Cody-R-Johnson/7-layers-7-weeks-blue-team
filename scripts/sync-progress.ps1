param(
    [string]$RootPath = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
    [int]$TotalWeeks = 7,
    [int]$DaysPerWeek = 7
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-OrdinalNumber {
    param([string]$Name, [string]$Prefix)

    if ($Name -match "^$Prefix-(\d+)$") {
        return [int]$Matches[1]
    }

    return $null
}

function Get-ModuleTitle {
    param([string]$ReadmePath, [int]$Week, [int]$Day)

    $defaultTitle = "Week $Week Day $Day"
    $line = Get-Content -Path $ReadmePath -TotalCount 1
    if (-not $line) {
        return $defaultTitle
    }

    $trimmed = $line.Trim()
    if ($trimmed.StartsWith("# ")) {
        return $trimmed.Substring(2).Trim()
    }

    return $defaultTitle
}

$root = (Resolve-Path $RootPath).Path
$rootReadmePath = Join-Path $root "README.md"

if (-not (Test-Path -Path $rootReadmePath)) {
    throw "Root README not found at $rootReadmePath"
}

$moduleEntries = @()

$weekDirs = Get-ChildItem -Path $root -Directory | Where-Object { $_.Name -match "^Week-\d+$" }
foreach ($weekDir in ($weekDirs | Sort-Object { Get-OrdinalNumber -Name $_.Name -Prefix "Week" })) {
    $weekNumber = Get-OrdinalNumber -Name $weekDir.Name -Prefix "Week"
    if ($null -eq $weekNumber) {
        continue
    }

    $dayDirs = Get-ChildItem -Path $weekDir.FullName -Directory | Where-Object { $_.Name -match "^Day-\d+$" }
    foreach ($dayDir in ($dayDirs | Sort-Object { Get-OrdinalNumber -Name $_.Name -Prefix "Day" })) {
        $dayNumber = Get-OrdinalNumber -Name $dayDir.Name -Prefix "Day"
        if ($null -eq $dayNumber) {
            continue
        }

        $dayReadmePath = Join-Path $dayDir.FullName "README.md"
        if (-not (Test-Path -Path $dayReadmePath)) {
            continue
        }

        $title = Get-ModuleTitle -ReadmePath $dayReadmePath -Week $weekNumber -Day $dayNumber
        $relativePath = $dayReadmePath.Substring($root.Length + 1) -replace "\\", "/"

        $moduleEntries += [PSCustomObject]@{
            Week         = $weekNumber
            Day          = $dayNumber
            Title        = $title
            RelativePath = $relativePath
        }
    }
}

$moduleEntries = $moduleEntries | Sort-Object Week, Day
$completedModuleLines = @()

if ($moduleEntries.Count -eq 0) {
    $completedModuleLines = @("- None yet")
} else {
    foreach ($entry in $moduleEntries) {
        $completedModuleLines += "- [$($entry.Title)]($($entry.RelativePath))"
    }
}

$completedSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($entry in $moduleEntries) {
    $null = $completedSet.Add("$($entry.Week)-$($entry.Day)")
}

$nextModule = $null
for ($w = 1; $w -le $TotalWeeks; $w++) {
    for ($d = 1; $d -le $DaysPerWeek; $d++) {
        if (-not $completedSet.Contains("$w-$d")) {
            $nextModule = "Week $w Day $d"
            break
        }
    }

    if ($nextModule) {
        break
    }
}

$currentProgressLines = @()
if ($moduleEntries.Count -eq 0) {
    $currentProgressLines += "- Completed: None"
} else {
    $latestEntry = $moduleEntries[-1]
    $currentProgressLines += "- Completed: $($moduleEntries.Count) module(s) (through Week $($latestEntry.Week) Day $($latestEntry.Day))"
}

if ($nextModule) {
    $currentProgressLines += "- Next module: $nextModule"
} else {
    $currentProgressLines += "- Next module: Program complete"
}

$content = Get-Content -Path $rootReadmePath -Raw

if ($content -notmatch "(?m)^## Completed Modules\s*$") {
    throw "Section '## Completed Modules' was not found in README.md"
}

if ($content -notmatch "(?m)^## Current Progress\s*$") {
    throw "Section '## Current Progress' was not found in README.md"
}

$completedBlock = "## Completed Modules`r`n`r`n" + ($completedModuleLines -join "`r`n") + "`r`n`r`n"
$content = [regex]::Replace(
    $content,
    "(?ms)^## Completed Modules\s*\r?\n.*?(?=^## Current Progress\s*$)",
    $completedBlock
)

$currentProgressBlock = "## Current Progress`r`n`r`n" + ($currentProgressLines -join "`r`n") + "`r`n`r`n"
$content = [regex]::Replace(
    $content,
    "(?ms)^## Current Progress\s*\r?\n.*?(?=^(?:##\s|<details>\s*$)|\z)",
    $currentProgressBlock
)

Set-Content -Path $rootReadmePath -Value $content
Write-Host "README synced: $rootReadmePath"
