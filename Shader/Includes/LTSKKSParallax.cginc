#ifndef LTSKKS_PARALLAX_INCLUDED
#define LTSKKS_PARALLAX_INCLUDED

#ifndef UNITY_SAMPLE_TEX2D_SAMPLER_LOD
#define UNITY_SAMPLE_TEX2D_SAMPLER_LOD(texName, samplerName, coord, lod) texName.SampleLevel(sampler##samplerName, coord, lod)
#endif

#ifndef UNITY_SAMPLE_TEX2D_SAMPLER_GRAD
#define UNITY_SAMPLE_TEX2D_SAMPLER_GRAD(texName, samplerName, coord, dx, dy) texName.SampleGrad(sampler##samplerName, coord, dx, dy)
#endif

#define LTSKKS_POM_DETAIL 200

void LTSKKS_Parallax(inout float2 uvMain, inout float2 uv, float useParallax, float2 parallaxOffset, float parallaxScale, float parallaxOffsetParam)
{
    if(useParallax > 0.5)
    {
        float height = (UNITY_SAMPLE_TEX2D_SAMPLER_LOD(_ParallaxMap, _MainTex, uvMain, 0).r - parallaxOffsetParam) * parallaxScale;
        uvMain += height * parallaxOffset;
        uv += height * parallaxOffset;
    }
}

void LTSKKS_POM(inout float2 uvMain, inout float2 uv, float useParallax, float4 uvST, float3 parallaxViewDirection, float parallaxScale, float parallaxOffsetParam)
{
    if(useParallax <= 0.5 || abs(parallaxScale) < LTSKKS_EPS) return;

    float height = 0.0;
    float height2 = 0.0;
    float3 rayStep = -parallaxViewDirection;
    float3 rayPos = float3(uvMain, 1.0) + (1.0 - parallaxOffsetParam) * parallaxScale * parallaxViewDirection;
    rayStep.xy *= uvST.xy;
    rayStep = rayStep / LTSKKS_POM_DETAIL;
    rayStep.z /= parallaxScale;

    float stepCount = max(1.0, LTSKKS_POM_DETAIL * 2.0 * abs(parallaxScale));
    for(int i = 0; i < stepCount; ++i)
    {
        height2 = height;
        rayPos += rayStep;
        height = UNITY_SAMPLE_TEX2D_SAMPLER_LOD(_ParallaxMap, _MainTex, rayPos.xy, 0).r;
        if(height >= rayPos.z) break;
    }

    float2 prevObjPoint = rayPos.xy - rayStep.xy;
    float nextHeight = height - rayPos.z;
    float prevHeight = height2 - rayPos.z + rayStep.z;
    float denom = nextHeight - prevHeight;
    float weight = (abs(denom) < LTSKKS_EPS) ? 0.0 : nextHeight / denom;
    rayPos.xy = lerp(rayPos.xy, prevObjPoint, weight);

    uv += rayPos.xy - uvMain;
    uvMain = rayPos.xy;
}

void LTSKKS_ApplyMainParallax(inout LTSKKSFragData fd)
{
    if(_UseParallax <= 0.5) return;

    if(_UsePOM > 0.5)
    {
        LTSKKS_POM(fd.uvMain, fd.uv0, _UseParallax, _MainTex_ST, fd.parallaxViewDirection, _Parallax, _ParallaxOffset);
    }
    else
    {
        LTSKKS_Parallax(fd.uvMain, fd.uv0, _UseParallax, fd.parallaxOffset, _Parallax, _ParallaxOffset);
    }
}

float4 LTSKKS_SampleMainTexAfterParallax(float2 uv, float2 ddxMain, float2 ddyMain)
{
    float4 mainTex = LTSKKS_SAMPLE_MAIN_TEX(uv);
    if(_UseParallax > 0.5 && _UsePOM > 0.5)
    {
        mainTex = UNITY_SAMPLE_TEX2D_SAMPLER_GRAD(_MainTex, _MainTex, uv, ddxMain, ddyMain);
    }
    return mainTex;
}

#endif
