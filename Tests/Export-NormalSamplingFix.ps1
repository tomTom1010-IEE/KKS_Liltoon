$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$project = [IO.Path]::GetFullPath((Join-Path $repo '../../..'))
$result = Get-Content (Join-Path $project 'CodexBridge/Outbox/20260916-normal-filter-fix-build.result.json') -Raw | ConvertFrom-Json
if (-not $result.success) { throw 'Unity build did not succeed.' }
$bundle = 'chara/tom/liltoon/shaders/liltoon.unity3d'
$built = Join-Path $project ('Build/abdata/' + $bundle)
if ($built -notin $result.files) { throw 'Successful build did not update the production bundle.' }
if (Get-Process -Name SB3UtilityScript -ErrorAction SilentlyContinue) { throw 'Wait for the AssetBundle postprocessor.' }
$editorLog = Get-Content (Join-Path $env:LOCALAPPDATA 'Unity/Editor/Editor.log') -Raw
$start = $editorLog.LastIndexOf('[CodexBridge] Building AssetBundles to:')
if ($start -lt 0 -or $editorLog.Substring($start) -match '(?i)Shader error|failed to compile') { throw 'Missing build log or shader compilation error.' }
$bundleManifest = Get-Content ($built + '.manifest') -Raw
if (-not $bundleManifest.Contains('Dependencies: []')) { throw 'Unexpected external bundle dependency.' }
[xml]$manifest = Get-Content (Join-Path $repo 'manifest.xml') -Raw
foreach ($shader in $manifest.manifest.MaterialEditor.Shader) {
    if ($shader.AssetBundle -ne $bundle) { throw 'Unexpected registered bundle.' }
    if ($bundleManifest -notmatch ('(?i)/' + [regex]::Escape($shader.Asset) + '\.prefab')) { throw ('Missing prefab in bundle: ' + $shader.Asset) }
}
$out = Join-Path $project 'Build/NormalSamplingFix'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$zip = Join-Path $out 'lilToon_KKS_v1.0.3_normalfilter1.zipmod'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [IO.File]::Open($zip, [IO.FileMode]::Create)
$archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($pair in @(@((Join-Path $repo 'manifest.xml'),'manifest.xml'), @($built,('abdata/' + $bundle)), @((Join-Path $repo 'Tests/NormalSamplingFix.md'),'SAMPLING_FIX.md'))) {
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$pair[0],$pair[1],[IO.Compression.CompressionLevel]::Optimal)
    }
} finally { $archive.Dispose(); $stream.Dispose() }
$check = [IO.Compression.ZipFile]::OpenRead($zip)
try {
    if ($check.Entries.Count -ne 3) { throw 'Unexpected zipmod contents.' }
    $check.Entries | ForEach-Object { Write-Output ($_.FullName + ': ' + $_.Length + ' bytes') }
} finally { $check.Dispose() }
Get-FileHash $zip -Algorithm SHA256 | Format-List
