$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
[xml]$manifest = Get-Content (Join-Path $root 'manifest.xml') -Raw
$skin = $manifest.SelectSingleNode('//Shader[@Name="lilToonKKSSkin"]')
$switches = $manifest.SelectNodes('//Shader/Property[@Name="UseDetailMaskForShadowPost"]')
if ($switches.Count -ne 1 -or $switches[0].ParentNode.Name -ne 'lilToonKKSSkin') { throw 'Switch must be Skin-only' }
$category = $skin.SelectSingleNode('Property[@Name="ShadowPostAO"]').Category
foreach ($name in @('DetailMask', 'UseDetailMaskForShadowPost')) {
    $props = $skin.SelectNodes('Property[@Name="' + $name + '"]')
    if ($props.Count -ne 1 -or $props[0].Category -ne $category) { throw "Wrong category or duplicate: $name" }
}
$shader = Get-Content (Join-Path $root 'Shader/lilToonKKSSkin.shader') -Raw
if ($shader -notmatch '_UseDetailMaskForShadowPost\s*\([^\r\n]+\)\s*=\s*0') { throw 'Default must be off' }
$shadow = Get-Content (Join-Path $root 'Shader/Includes/LTSKKSShadow.cginc') -Raw
if ($shadow -notmatch '(?s)#if defined\(LTSKKS_KKS_SKIN\)\s*// Replace only.*?if\(_ShadowPostAO > 0.5 && _UseDetailMaskForShadowPost > 0.5\).*?LTSKKS_CalcUV\(fd.uv0, _DetailMask_ST\).*?1.0 - LTSKKS_SAMPLE_KKS_SKIN\(_DetailMask, detailUV\).g;.*?borderMask.rgb = float3\(detailAO, detailAO, detailAO\);.*?#endif') { throw 'Missing Skin-only post-AO replacement path' }
if ($shadow.IndexOf('float detailAO') -gt $shadow.IndexOf('borderMask.r = saturate')) { throw 'Detail input must precede AO remapping' }
$input = Get-Content (Join-Path $root 'Shader/Includes/LTSKKSInput.cginc') -Raw
if ($input -notmatch '(?s)#if defined\(LTSKKS_KKS_SKIN\)(?:(?!#endif).)*float _UseDetailMaskForShadowPost;') { throw 'Input must be Skin-only' }
$reflection = Get-Content (Join-Path $root 'Shader/Includes/LTSKKSReflection.cginc') -Raw
if ($reflection -notmatch 'fd.smoothness \*= LTSKKS_SAMPLE_KKS_SKIN\(_DetailMask, detailMaskUV\).a;') { throw 'Existing alpha smoothness mapping changed' }
Write-Output 'PASS: Skin-only default-off switch, matching categories, UV0/ST inverse-G replacement before AO remapping, existing alpha mapping retained.'
