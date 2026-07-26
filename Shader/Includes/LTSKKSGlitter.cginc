#ifndef LTSKKS_GLITTER_INCLUDED
#define LTSKKS_GLITTER_INCLUDED

float LTSKKS_NsqDistance(float2 a, float2 b)
{
    return dot(a - b, a - b);
}

void LTSKKS_HashRGB4(float2 pos, out float3 noise0, out float3 noise1, out float3 noise2, out float3 noise3)
{
    #define LTSKKS_HASH_M1 1597334677U
    #define LTSKKS_HASH_M2 3812015801U
    #define LTSKKS_HASH_M3 2912667907U
    uint2 q = (uint2)pos;
    uint4 q2 = uint4(q.x, q.y, q.x + 1, q.y + 1) * uint4(LTSKKS_HASH_M1, LTSKKS_HASH_M2, LTSKKS_HASH_M1, LTSKKS_HASH_M2);
    uint3 n0 = (q2.x ^ q2.y) * uint3(LTSKKS_HASH_M1, LTSKKS_HASH_M2, LTSKKS_HASH_M3);
    uint3 n1 = (q2.z ^ q2.y) * uint3(LTSKKS_HASH_M1, LTSKKS_HASH_M2, LTSKKS_HASH_M3);
    uint3 n2 = (q2.x ^ q2.w) * uint3(LTSKKS_HASH_M1, LTSKKS_HASH_M2, LTSKKS_HASH_M3);
    uint3 n3 = (q2.z ^ q2.w) * uint3(LTSKKS_HASH_M1, LTSKKS_HASH_M2, LTSKKS_HASH_M3);
    noise0 = float3(n0) * (1.0 / float(0xffffffffU));
    noise1 = float3(n1) * (1.0 / float(0xffffffffU));
    noise2 = float3(n2) * (1.0 / float(0xffffffffU));
    noise3 = float3(n3) * (1.0 / float(0xffffffffU));
    #undef LTSKKS_HASH_M1
    #undef LTSKKS_HASH_M2
    #undef LTSKKS_HASH_M3
}

float4 LTSKKS_Voronoi(float2 pos, out float2 nearOffset, float scaleRandomize)
{
    #if defined(SHADER_API_D3D9) || defined(SHADER_API_D3D11_9X)
        #define LTSKKS_VORONOI_M1 46203.4357
        #define LTSKKS_VORONOI_M2 21091.5327
        #define LTSKKS_VORONOI_M3 35771.1966
        float2 q = trunc(pos);
        float4 q2 = float4(q.x, q.y, q.x + 1, q.y + 1);
        float3 noise0 = frac(sin(dot(q2.xy, float2(12.9898, 78.233))) * float3(LTSKKS_VORONOI_M1, LTSKKS_VORONOI_M2, LTSKKS_VORONOI_M3));
        float3 noise1 = frac(sin(dot(q2.zy, float2(12.9898, 78.233))) * float3(LTSKKS_VORONOI_M1, LTSKKS_VORONOI_M2, LTSKKS_VORONOI_M3));
        float3 noise2 = frac(sin(dot(q2.xw, float2(12.9898, 78.233))) * float3(LTSKKS_VORONOI_M1, LTSKKS_VORONOI_M2, LTSKKS_VORONOI_M3));
        float3 noise3 = frac(sin(dot(q2.zw, float2(12.9898, 78.233))) * float3(LTSKKS_VORONOI_M1, LTSKKS_VORONOI_M2, LTSKKS_VORONOI_M3));
        #undef LTSKKS_VORONOI_M1
        #undef LTSKKS_VORONOI_M2
        #undef LTSKKS_VORONOI_M3
    #else
        float3 noise0, noise1, noise2, noise3;
        LTSKKS_HashRGB4(pos, noise0, noise1, noise2, noise3);
    #endif

    float4 fracPos = frac(pos).xyxy + float4(0.5, 0.5, -0.5, -0.5);
    float4 dist4 = float4(
        LTSKKS_NsqDistance(fracPos.xy, noise0.xy),
        LTSKKS_NsqDistance(fracPos.zy, noise1.xy),
        LTSKKS_NsqDistance(fracPos.xw, noise2.xy),
        LTSKKS_NsqDistance(fracPos.zw, noise3.xy)
    );
    dist4 = lerp(dist4, dist4 / max(float4(noise0.z, noise1.z, noise2.z, noise3.z), 0.001), scaleRandomize);

    float3 near0A = dist4.x < dist4.y ? float3(0, 0, dist4.x) : float3(1, 0, dist4.y);
    float3 near0B = dist4.z < dist4.w ? float3(0, 1, dist4.z) : float3(1, 1, dist4.w);
    nearOffset = near0A.z < near0B.z ? near0A.xy : near0B.xy;

    float4 nearA = dist4.x < dist4.y ? float4(noise0, dist4.x) : float4(noise1, dist4.y);
    float4 nearB = dist4.z < dist4.w ? float4(noise2, dist4.z) : float4(noise3, dist4.w);
    return nearA.w < nearB.w ? nearA : nearB;
}

float3 LTSKKS_CalcGlitter(float2 uv, float3 normalDirection, float3 viewDirection, float3 cameraDirection, float3 lightDirection)
{
    float2 pos = uv * _GlitterParams1.xy;
    float2 dd = fwidth(pos);
    float factor = frac(sin(dot(floor(pos / floor(dd + 3.0)), float2(12.9898, 78.233))) * 46203.4357) + 0.5;
    float2 factor2 = floor(dd + factor * 0.5);
    pos = pos / max(1.0, factor2) + _GlitterParams1.xy * factor2;

    float2 nearOffset;
    float4 near = LTSKKS_Voronoi(pos, nearOffset, _GlitterScaleRandomize);

    float3 glitterNormal = abs(frac(near.xyz * 14.274 + _Time.x * _GlitterParams2.x) * 2.0 - 1.0);
    glitterNormal = normalize(glitterNormal * 2.0 - 1.0);
    float glitter = dot(glitterNormal, cameraDirection);
    glitter = abs(frac(glitter * _GlitterSensitivity + _GlitterSensitivity) - 0.5) * 4.0 - 1.0;
    glitter = saturate(1.0 - (glitter * _GlitterParams1.w + _GlitterParams1.w));
    glitter = pow(glitter, _GlitterPostContrast);
    glitter *= saturate((_GlitterParams1.z - near.w) / max(fwidth(near.w), LTSKKS_EPS));

    float3 halfDirection = normalize(viewDirection + lightDirection * _GlitterParams2.z);
    float nh = saturate(dot(normalDirection, halfDirection));
    glitter = saturate(glitter * saturate(nh * _GlitterParams2.y + 1.0 - _GlitterParams2.y));

    float3 glitterColor = glitter - glitter * frac(near.xyz * 278.436) * _GlitterParams2.w;

    if(_GlitterApplyShape > 0.5)
    {
        float2 maskUV = pos - floor(pos) - nearOffset + 0.5 - near.xy;
        maskUV = maskUV / max(_GlitterParams1.z, LTSKKS_EPS) * _GlitterShapeTex_ST.xy + _GlitterShapeTex_ST.zw;
        if(_GlitterAngleRandomize > 0.5)
        {
            float si, co;
            sincos(near.z * 785.238, si, co);
            maskUV = float2(maskUV.x * co - maskUV.y * si, maskUV.x * si + maskUV.y * co);
        }

        float randomScale = lerp(1.0, 1.0 / sqrt(max(near.z, 0.001)), _GlitterScaleRandomize);
        maskUV = maskUV * randomScale + 0.5;
        float inRange = step(0.0, maskUV.x) * step(0.0, maskUV.y) * step(maskUV.x, 1.0) * step(maskUV.y, 1.0);
        maskUV = (maskUV + floor(near.xy * _GlitterAtras.xy)) / max(_GlitterAtras.xy, float2(1.0, 1.0));
        float2 mipFactor = 0.125 / max(_GlitterParams1.z, LTSKKS_EPS) * _GlitterAtras.xy * _GlitterShapeTex_ST.xy * randomScale;
        float4 shapeTex = tex2Dgrad(_GlitterShapeTex, maskUV, abs(ddx(pos)) * mipFactor.x, abs(ddy(pos)) * mipFactor.y);
        shapeTex.a *= inRange;
        glitterColor *= shapeTex.rgb * shapeTex.a;
    }

    return glitterColor;
}

void LTSKKS_ApplyGlitter(inout LTSKKSFragData fd)
{
    if(_UseGlitter <= 0.5) return;

    float3 n = normalize(lerp(fd.origN, fd.N, saturate(_GlitterNormalStrength)));
    float3 viewDirection = fd.V;
    float3 cameraDirection = normalize(lerp(normalize(UNITY_MATRIX_V._m20_m21_m22), fd.V, saturate(_GlitterVRParallaxStrength)));

    float4 glitterColor = _GlitterColor;
    float2 colorUV = fd.uvMain;
    if(_GlitterColorTex_UVMode > 0.5 && _GlitterColorTex_UVMode < 1.5) colorUV = fd.uv1;
    if(_GlitterColorTex_UVMode >= 1.5 && _GlitterColorTex_UVMode < 2.5) colorUV = fd.uv2;
    if(_GlitterColorTex_UVMode >= 2.5) colorUV = fd.uv3;
    glitterColor *= LTSKKS_SAMPLE_TEX(_GlitterColorTex, LTSKKS_CalcUV(colorUV, _GlitterColorTex_ST));

    float2 glitterUV = (_GlitterUVMode > 0.5) ? fd.uv1 : fd.uv0;
    glitterColor.rgb *= LTSKKS_CalcGlitter(glitterUV, n, viewDirection, cameraDirection, fd.L);
    glitterColor.rgb = lerp(glitterColor.rgb, glitterColor.rgb * fd.albedo, saturate(_GlitterMainStrength));
    glitterColor.a = (fd.facing < (_GlitterBackfaceMask - 1.0)) ? 0.0 : glitterColor.a;
    glitterColor.a = lerp(glitterColor.a, glitterColor.a * fd.shadowmix, saturate(_GlitterShadowMask));

    #if !defined(LTSKKS_REFRACTION)
        glitterColor.a *= lerp(1.0, fd.col.a, saturate(_GlitterApplyTransparency));
    #endif

    #if defined(LTSKKS_PASS_FORWARDADD)
        fd.col.rgb += glitterColor.a * saturate(_GlitterEnableLighting) * glitterColor.rgb * fd.lightColor;
    #else
        glitterColor.rgb = lerp(glitterColor.rgb, glitterColor.rgb * fd.lightColor, saturate(_GlitterEnableLighting));
        fd.col.rgb += glitterColor.rgb * glitterColor.a;
    #endif
}

#endif
