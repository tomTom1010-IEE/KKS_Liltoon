param([switch]$InitializeSnapshot)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$project = [IO.Path]::GetFullPath((Join-Path $repo '../../..'))
$root = Join-Path $repo 'Diagnostics/NormalSampling'
$shaderDir = Join-Path $root 'Shader'
$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force -Path $shaderDir | Out-Null
if ($InitializeSnapshot) {
    $includes = Join-Path $shaderDir 'Includes'
    if (Test-Path $includes) { throw 'Snapshot already exists; refusing to overwrite diagnostic edits.' }
    New-Item -ItemType Directory -Path $includes | Out-Null
    Get-ChildItem (Join-Path $repo 'Shader/Includes') -Filter '*.cginc' | Copy-Item -Destination $includes
    $hashes = Get-ChildItem (Join-Path $repo 'Shader') -Recurse -File | Where-Object Extension -In '.cginc','.shader' | ForEach-Object {
        @{ Path = $_.FullName.Substring($repo.Length + 1); SHA256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash }
    }
    [IO.File]::WriteAllText((Join-Path $root 'source-hashes.json'), ($hashes | ConvertTo-Json), $utf8)
}
$names = @('lilToonDebug01Baseline','lilToonDebug02TextureSampler','lilToonDebug03FixedLOD','lilToonDebug04XukmiTBN','lilToonDebug05XukmiDecode')
$source = [IO.File]::ReadAllText((Join-Path $repo 'Shader/lilToon.shader')).Replace("`r`n", "`n")
$properties = @'
        _DebugView ("Debug View: 0 Shaded, 1 Packed RGB, 2 Packed A, 3 TS Normal, 4 WS Normal, 5 Mesh Normal, 6 LOD, 7 Marker", Range(0,7)) = 0
        _DebugUV0 ("Debug Raw UV0 (Normal Map Only)", Range(0,1)) = 0
'@
[xml]$original = Get-Content (Join-Path $repo 'manifest.xml') -Raw
[xml]$manifest = '<manifest schema-ver="1"><guid>tom.lilToon.KKS.NormalSamplingDebug</guid><name>lilToon KKS Normal Sampling Debug</name><version>0.1.0</version><author>tomTom</author><description>Five isolated opaque normal-sampling diagnostics. Not a replacement for lilToon KKS.</description><game>Koikatsu Sunshine</game><MaterialEditor /></manifest>'
$bundle = 'chara/tom/liltoon/debug/normal_sampling_20260916.unity3d'
for ($i = 0; $i -lt $names.Count; $i++) {
    $name = $names[$i]
    $shader = $source.Replace('Shader "lilToon"', ('Shader "' + $name + '"'))
    $shader = $shader.Replace('    Properties' + "`n" + '    {', '    Properties' + "`n" + '    {' + "`n" + $properties)
    if (-not $shader.Contains('_DebugView')) { throw 'Properties insertion failed' }
    if ($i -eq 2) { $shader = $shader.Replace($properties, $properties + "`n" + '        _DebugLOD ("Debug Fixed Normal LOD", Range(0,10)) = 0') }
    $shader = $shader.Replace('            CGPROGRAM', '            CGPROGRAM' + "`r`n" + '            #define LTSKKS_NORMAL_DEBUG_VARIANT ' + ($i + 1))
    [IO.File]::WriteAllText((Join-Path $shaderDir ($name + '.shader')), $shader, $utf8)
    $block = $manifest.ImportNode($original.SelectSingleNode('/manifest/MaterialEditor/Shader[@Name="lilToon"]'), $true)
    $block.SetAttribute('Name', $name)
    $block.SetAttribute('AssetBundle', $bundle)
    $block.SetAttribute('Asset', 'a_' + $name)
    foreach ($p in @(@('DebugView','0,7'), @('DebugUV0','0,1'))) {
        $node = $manifest.CreateElement('Property')
        $node.SetAttribute('Name',$p[0]); $node.SetAttribute('Type','Float')
        $node.SetAttribute('Category','Debug'); $node.SetAttribute('Range',$p[1])
        [void]$block.AppendChild($node)
    }
    if ($i -eq 2) {
        $node = $manifest.CreateElement('Property')
        $node.SetAttribute('Name','DebugLOD'); $node.SetAttribute('Type','Float')
        $node.SetAttribute('Category','Debug'); $node.SetAttribute('Range','0,10')
        [void]$block.AppendChild($node)
    }
    [void]$manifest.SelectSingleNode('/manifest/MaterialEditor').AppendChild($block)
}
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.Encoding = $utf8
$writer = [Xml.XmlWriter]::Create((Join-Path $root 'manifest.xml'), $settings)
try { $manifest.Save($writer) } finally { $writer.Dispose() }
Write-Output ('Generated five full shader copies and diagnostic manifest in ' + $root)
