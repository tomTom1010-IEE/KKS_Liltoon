param([ValidateSet('Assets','Build','Package')][string]$Stage = 'Assets')
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$project = [IO.Path]::GetFullPath((Join-Path $repo '../../..'))
$root = Join-Path $repo 'Diagnostics/NormalSampling'
$assetRoot = 'Assets/Mods/liltoon/Diagnostics/NormalSampling'
$bundle = 'chara/tom/liltoon/debug/normal_sampling_20260916.unity3d'
$names = @('lilToonDebug01Baseline','lilToonDebug02TextureSampler','lilToonDebug03FixedLOD','lilToonDebug04XukmiTBN','lilToonDebug05XukmiDecode')
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Invoke-Bridge($id, $command, $timeout = 180) {
    $id = 'normal-debug-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + $id
    $inbox = Join-Path $project ('CodexBridge/Inbox/' + $id + '.json')
    $outbox = Join-Path $project ('CodexBridge/Outbox/' + $id + '.result.json')
    [IO.File]::WriteAllText($inbox, ($command | ConvertTo-Json -Depth 8), $utf8)
    $deadline = (Get-Date).AddSeconds($timeout)
    while (-not (Test-Path $outbox)) {
        if ((Get-Date) -gt $deadline) { throw ('Bridge timeout; inspect pending command: ' + $inbox) }
        Start-Sleep -Seconds 2
    }
    $result = Get-Content $outbox -Raw | ConvertFrom-Json
    if (-not $result.success) { throw ($outbox + ': ' + $result.message) }
    Write-Output ($command.operation + ': ' + $result.message)
    if ($command.operation -eq 'buildAssetBundles') {
        [IO.File]::WriteAllText((Join-Path $root 'build-result.json'), ($result | ConvertTo-Json -Depth 12), $utf8)
    }
}
if ($Stage -eq 'Assets') {
    Invoke-Bridge 'refresh' @{operation='refresh'}
    foreach ($name in $names) {
        Invoke-Bridge ('material-' + $name) @{operation='createMaterial'; assetPath="$assetRoot/Material/m_$name.mat"; shader=$name}
        Invoke-Bridge ('prefab-' + $name) @{operation='createPrefab'; assetPath="$assetRoot/Prefab/a_$name.prefab"; name="a_$name"; materialPath="$assetRoot/Material/m_$name.mat"; primitive='Sphere'}
    }
    Invoke-Bridge 'bundle' @{operation='setAssetBundles'; assetBundleName=$bundle; assetPaths=@($names | ForEach-Object { "$assetRoot/Prefab/a_$_.prefab" })}
} elseif ($Stage -eq 'Build') {
    # Existing duplicate AssetBundleBrowser GUIDs break Unity StrictMode even when shaders compile.
    # Keep normal build behavior and inspect shader errors independently before packaging.
    Invoke-Bridge 'build' @{operation='buildAssetBundles'; outputDirectory='Build/abdata'; buildTarget='StandaloneWindows'; forceRebuild=$false; strictMode=$false; koikatsuPath='D:/Program Files/KoikatuSunshine'} 3600
} else {
    $built = Join-Path $project ('Build/abdata/' + $bundle)
    if (-not (Test-Path $built)) { throw 'Diagnostic bundle has not been built.' }
    $result = Get-Content (Join-Path $root 'build-result.json') -Raw | ConvertFrom-Json
    if (-not $result.success) { throw 'Build was not successful.' }
    if ($built -notin $result.files) { throw 'Successful build did not report the diagnostic bundle.' }
    $bundleManifest = Get-Content ($built + '.manifest') -Raw
    foreach ($name in $names) {
        if (-not $bundleManifest.Contains("$assetRoot/Prefab/a_$name.prefab")) { throw ('Missing built prefab: ' + $name) }
    }
    if (-not $bundleManifest.Contains('Dependencies: []')) { throw 'Unexpected external bundle dependencies.' }
    $editorLog = Get-Content (Join-Path $env:LOCALAPPDATA 'Unity/Editor/Editor.log') -Raw
    $start = $editorLog.LastIndexOf('[CodexBridge] Building AssetBundles to:')
    if ($start -lt 0) { throw 'Build log marker missing.' }
    if ($editorLog.Substring($start) -match '(?i)Shader error|failed to compile') { throw 'Shader compilation error in build log.' }
    if (Get-Process -Name SB3UtilityScript -ErrorAction SilentlyContinue) { throw 'AssetBundle postprocessor is still running.' }
    $dist = Join-Path $project 'Build/NormalSamplingDebug'
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    $zip = Join-Path $dist 'lilToon_KKS_NormalSamplingDebug_0.1.0.zipmod'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $stream = [IO.File]::Open($zip, [IO.FileMode]::Create)
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($entry in @(@((Join-Path $root 'manifest.xml'),'manifest.xml'), @($built,('abdata/' + $bundle)), @((Join-Path $root 'README.md'),'README.md'), @((Join-Path $root 'README_CN.md'),'README_CN.md'))) {
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $entry[0], $entry[1], [IO.Compression.CompressionLevel]::Optimal)
        }
    } finally { $archive.Dispose(); $stream.Dispose() }
    $check = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $check.Entries | Select-Object FullName,Length
        if ($check.Entries.Count -ne 4) { throw 'Unexpected archive entry count' }
    } finally { $check.Dispose() }
    Get-FileHash $zip -Algorithm SHA256
}
