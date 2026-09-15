$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$root = Join-Path $repo 'Diagnostics/NormalSampling'
[xml]$manifest = Get-Content (Join-Path $root 'manifest.xml') -Raw
[xml]$original = Get-Content (Join-Path $repo 'manifest.xml') -Raw
$baseline = $original.SelectSingleNode('/manifest/MaterialEditor/Shader[@Name="lilToon"]')
$blocks = $manifest.SelectNodes('/manifest/MaterialEditor/Shader')
if ($blocks.Count -ne 5) { throw 'Expected exactly five diagnostic shaders.' }
if ($manifest.manifest.game -ne 'Koikatsu Sunshine') { throw 'Wrong game.' }
foreach ($hash in (Get-Content (Join-Path $root 'source-hashes.json') -Raw | ConvertFrom-Json)) {
    if ((Get-FileHash (Join-Path $repo $hash.Path) -Algorithm SHA256).Hash -ne $hash.SHA256) { throw ('Production source changed: ' + $hash.Path) }
}
$originalShader = Get-Content (Join-Path $repo 'Shader/lilToon.shader') -Raw
foreach ($block in $blocks) {
    $shader = Get-Content (Join-Path $root ('Shader/' + $block.Name + '.shader')) -Raw
    if ($shader -notmatch ('Shader "' + $block.Name + '"')) { throw 'Shader name mismatch.' }
    if (([regex]::Matches($shader,'#define LTSKKS_NORMAL_DEBUG_VARIANT')).Count -ne 6) { throw 'Expected six passes.' }
    foreach ($property in $baseline.Property) {
        $p = $block.SelectSingleNode('Property[@Name="' + $property.Name + '"]')
        if ($null -eq $p -or $p.OuterXml -ne $property.OuterXml) { throw ('Manifest property mismatch: ' + $property.Name) }
    }
    $normalized = $shader.Replace($block.Name, 'lilToon')
    $normalized = [regex]::Replace($normalized,'(?m)^\s*#define LTSKKS_NORMAL_DEBUG_VARIANT \d+\r?\n','')
    $normalized = [regex]::Replace($normalized,'(?m)^\s*_Debug\w+ .*\r?\n','')
    if ($normalized.Replace("`r`n","`n") -ne $originalShader.Replace("`r`n","`n")) { throw ('Non-diagnostic shader changes: ' + $block.Name) }
    Write-Output ($block.Name + ': full property/pass parity OK')
}
$inc = Join-Path $root 'Shader/Includes'
foreach ($file in Get-ChildItem $inc -Filter '*.cginc') {
    foreach ($match in [regex]::Matches((Get-Content $file.FullName -Raw),'#include "(LTS[^\"]+)"')) {
        if (-not (Test-Path (Join-Path $inc $match.Groups[1].Value))) { throw ('Missing local include: ' + $match.Value) }
    }
}
Write-Output 'Original shader source hashes unchanged; private include graph complete; manifest valid.'
