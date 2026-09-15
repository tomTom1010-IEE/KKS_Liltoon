$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$includes = Join-Path $root 'Shader/Includes'
$policy = Get-Content (Join-Path $includes 'LTSKKSSampling.cginc') -Raw
$wrap = @{}
foreach ($m in [regex]::Matches($policy, '(?m)^#define LTSKKS_WRAP(_\w+) sampler_ltskks_linear_(repeat|clamp)$')) {
    if ($wrap.ContainsKey($m.Groups[1].Value)) { throw "Duplicate policy: $($m.Groups[1].Value)" }
    $wrap[$m.Groups[1].Value] = $m.Groups[2].Value
}
$declarations = @{}
foreach ($file in Get-ChildItem $includes -Filter '*.cginc') {
    $source = Get-Content $file.FullName -Raw
    foreach ($m in [regex]::Matches($source, 'UNITY_DECLARE_TEX2D_NOSAMPLER\((_\w+)\)')) {
        $tex = $m.Groups[1].Value
        $declarations[$tex] = $true
        if (-not $wrap.ContainsKey($tex)) { throw "Missing wrap policy: $tex in $($file.Name)" }
    }
    foreach ($m in [regex]::Matches($source, 'LTSKKS_SAMPLE_(?:TEX(?:_LOD4|_LOD|_GRAD)?|KKS_SKIN|LUT_LOD)\((_\w+),')) {
        if (-not $wrap.ContainsKey($m.Groups[1].Value)) { throw "Unmapped sample in $($file.Name): $($m.Value)" }
    }
    if ($source -match 'UNITY_SAMPLE_TEX2D|sampler_MainTex|UNITY_DECLARE_TEX2D\(') {
        throw "Legacy texture-owned sampler in $($file.Name)"
    }
    foreach ($m in [regex]::Matches($source, '\btex2D(?:lod|grad)?\((_\w+),')) {
        if ($m.Groups[1].Value -ne '_lilBackgroundTexture') { throw "Unconverted sample: $($m.Value)" }
    }
}
foreach ($tex in $wrap.Keys) {
    if (-not $declarations.ContainsKey($tex)) { throw "Policy has no texture declaration: $tex" }
}
foreach ($tex in @('_MainTex', '_BumpMap', '_Bump2ndMap', '_ParallaxMap', '_AnisotropyShiftNoiseMask', '_DissolveNoiseMask', '_Main2ndDissolveNoiseMask', '_Main3rdDissolveNoiseMask', '_FurNoiseMask', '_Texture2', '_Texture3', '_LiquidNormalMap')) {
    if ($wrap[$tex] -ne 'repeat') { throw "$tex must repeat" }
}
foreach ($tex in @('_AlphaMask', '_Bump2ndScaleMask', '_AnisotropyScaleMask', '_ShadowStrengthMask', '_liquidmask', '_overtex3', '_MatCapTex', '_MainGradationTex', '_TriMask')) {
    if ($wrap[$tex] -ne 'clamp') { throw "$tex must clamp" }
}
$shadow = Get-Content (Join-Path $includes 'LTSKKSShadow.cginc') -Raw
if ([regex]::Matches($shadow, 'LTSKKS_SAMPLE_LUT_LOD\(').Count -ne 6) { throw 'All shadow LUT samples must clamp' }
foreach ($name in @('LTSKKSInput.cginc', 'LTSKKSLiteInput.cginc')) {
    if ((Get-Content (Join-Path $includes $name) -Raw) -notmatch '#include "LTSKKSSampling.cginc"') { throw "Missing policy include: $name" }
}
[xml]$manifest = Get-Content (Join-Path $root 'manifest.xml') -Raw
if ($manifest.SelectSingleNode('//game').InnerText -ne 'Koikatsu Sunshine') { throw 'Unexpected game target' }
Write-Output "PASS: $($wrap.Count) texture policies; ordinary/LOD/gradient sampling coverage; noise exceptions; shadow LUT clamp; valid KKS manifest."
