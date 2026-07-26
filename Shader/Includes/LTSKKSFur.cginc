#ifndef LTSKKS_FUR_INCLUDED
#define LTSKKS_FUR_INCLUDED

#define LTSKKS_PASS_FUR 1

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSData.cginc"
#define LTSKKS_DISSOLVE_WITH_FRAGDATA 1
#include "LTSKKSDissolve.cginc"
#include "LTSKKSPipeline.cginc"
#define LTSKKS_PARALLAX_WITH_FRAGDATA 1
#include "LTSKKSParallax.cginc"
#include "LTSKKSMain.cginc"
#define LTSKKS_ALPHA_WITH_FRAGDATA 1
#include "LTSKKSAlpha.cginc"
#include "LTSKKSNormal.cginc"
#include "LTSKKSShadow.cginc"
#include "LTSKKSRim.cginc"

struct LTSKKSFurAppData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 color : COLOR;
    uint vertexID : SV_VertexID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct LTSKKSFurV2G
{
    float4 pos : SV_POSITION;
    float4 uv01 : TEXCOORD0;
    float4 uv23 : TEXCOORD1;
    float3 posWS : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float4 tangentWS : TEXCOORD4;
    float3 bitangentWS : TEXCOORD5;
    float3 furVectorWS : TEXCOORD9;
    float4 color : COLOR;
    float3 vertexLightColor : TEXCOORD8;
    uint vertexID : TEXCOORD10;
    SHADOW_COORDS(6)
    UNITY_FOG_COORDS(7)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

float3 LTSKKS_FurTouchOffset(float3 posWS, float3 furVectorWS)
{
    // KKS does not currently use lilToon's vertex-light fur touch/collision path.
    return 0.0;
}

float3 LTSKKS_FurBlendNormal(float3 dstNormal, float3 srcNormal)
{
    return float3(dstNormal.xy + srcNormal.xy, dstNormal.z * srcNormal.z);
}

void LTSKKS_TransferFurShadowCoord(inout LTSKKSV2F o, float3 posWS)
{
    #if defined(SHADOWS_SCREEN)
        o._ShadowCoord = ComputeScreenPos(o.pos);
    #elif defined(SHADOWS_DEPTH)
        o._ShadowCoord = mul(unity_WorldToShadow[0], float4(posWS, 1.0));
    #elif defined(SHADOWS_CUBE)
        o._ShadowCoord = posWS - _LightPositionRange.xyz;
    #endif
}

LTSKKSFurV2G vert(LTSKKSFurAppData v)
{
    LTSKKSFurV2G o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSFurV2G, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float3 posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    float3 normalWS = UnityObjectToWorldNormal(v.normal);
    float3 tangentWS = UnityObjectToWorldDir(v.tangent.xyz);
    float tangentSign = v.tangent.w * unity_WorldTransformParams.w;
    float3 bitangentWS = cross(normalize(normalWS), normalize(tangentWS)) * tangentSign;

    float2 uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST);
    float3 furVectorTS = _FurVector.xyz + float3(0.0, 0.0, 0.0001);
    if(_VertexColor2FurVector > 0.5)
    {
        furVectorTS = LTSKKS_FurBlendNormal(furVectorTS, v.color.rgb);
    }
    float3 texVector = LTSKKS_UnpackNormalScale(tex2Dlod(_FurVectorTex, float4(uvMain, 0.0, 0.0)), _FurVectorScale);
    furVectorTS = LTSKKS_FurBlendNormal(furVectorTS, texVector);

    float3x3 tbn = float3x3(normalize(tangentWS), normalize(bitangentWS), normalize(normalWS));
    float3 furVectorWS = mul(normalize(furVectorTS), tbn) * _FurVector.w;
    #if defined(LTSKKS_FUR_PRE)
        furVectorWS *= _FurCutoutLength;
    #endif
    furVectorWS.y -= _FurGravity * length(furVectorWS);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.posWS = posWS;
    o.normalWS = normalWS;
    o.tangentWS = float4(tangentWS, tangentSign);
    o.bitangentWS = bitangentWS;
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.color = v.color;
    o.vertexLightColor = LTSKKS_GetVertexLightColor(o.posWS);
    o.furVectorWS = furVectorWS;
    o.vertexID = v.vertexID;
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

float LTSKKS_FurLerp3(float a, float b, float c, float3 factor)
{
    return a * factor.x + b * factor.y + c * factor.z;
}

float2 LTSKKS_FurLerp3(float2 a, float2 b, float2 c, float3 factor)
{
    return a * factor.x + b * factor.y + c * factor.z;
}

float3 LTSKKS_FurLerp3(float3 a, float3 b, float3 c, float3 factor)
{
    return a * factor.x + b * factor.y + c * factor.z;
}

float4 LTSKKS_FurLerp3(float4 a, float4 b, float4 c, float3 factor)
{
    return a * factor.x + b * factor.y + c * factor.z;
}

void LTSKKS_AppendFurVertex(
    in LTSKKSFurV2G v0,
    in LTSKKSFurV2G v1,
    in LTSKKSFurV2G v2,
    float3 factor,
    float3 posWS,
    float furLayer,
    inout TriangleStream<LTSKKSV2F> outStream)
{
    LTSKKSV2F o;
    UNITY_INITIALIZE_OUTPUT(LTSKKSV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v0, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.pos = mul(UNITY_MATRIX_VP, float4(posWS, 1.0));
    o.posWS = posWS;
    o.normalWS = LTSKKS_FurLerp3(v0.normalWS, v1.normalWS, v2.normalWS, factor);
    o.tangentWS = LTSKKS_FurLerp3(v0.tangentWS, v1.tangentWS, v2.tangentWS, factor);
    o.bitangentWS = LTSKKS_FurLerp3(v0.bitangentWS, v1.bitangentWS, v2.bitangentWS, factor);
    o.uv01 = LTSKKS_FurLerp3(v0.uv01, v1.uv01, v2.uv01, factor);
    o.uv23 = LTSKKS_FurLerp3(v0.uv23, v1.uv23, v2.uv23, factor);
    o.color = LTSKKS_FurLerp3(v0.color, v1.color, v2.color, factor);
    o.furLayer = furLayer;
    o.vertexLightColor = LTSKKS_FurLerp3(v0.vertexLightColor, v1.vertexLightColor, v2.vertexLightColor, factor);
    LTSKKS_TransferFurShadowCoord(o, posWS);
    UNITY_TRANSFER_FOG(o, o.pos);
    outStream.Append(o);
}

void LTSKKS_AppendFurStripPoint(
    in LTSKKSFurV2G v0,
    in LTSKKSFurV2G v1,
    in LTSKKSFurV2G v2,
    float3 fur0,
    float3 fur1,
    float3 fur2,
    float3 factor,
    inout TriangleStream<LTSKKSV2F> outStream)
{
    float3 baseWS = LTSKKS_FurLerp3(v0.posWS, v1.posWS, v2.posWS, factor);
    float3 furWS = LTSKKS_FurLerp3(fur0, fur1, fur2, factor);
    LTSKKS_AppendFurVertex(v0, v1, v2, factor, baseWS, 0.0, outStream);
    LTSKKS_AppendFurVertex(v0, v1, v2, factor, baseWS + furWS, 1.0, outStream);
}

void LTSKKS_AppendFurStrips(in LTSKKSFurV2G v0, in LTSKKSFurV2G v1, in LTSKKSFurV2G v2, inout TriangleStream<LTSKKSV2F> outStream)
{
    float2 uv0 = LTSKKS_CalcUV(v0.uv01.xy, _MainTex_ST);
    float2 uv1 = LTSKKS_CalcUV(v1.uv01.xy, _MainTex_ST);
    float2 uv2 = LTSKKS_CalcUV(v2.uv01.xy, _MainTex_ST);
    float len0 = tex2Dlod(_FurLengthMask, float4(uv0, 0.0, 0.0)).r;
    float len1 = tex2Dlod(_FurLengthMask, float4(uv1, 0.0, 0.0)).r;
    float len2 = tex2Dlod(_FurLengthMask, float4(uv2, 0.0, 0.0)).r;
    uint3 n0 = (v0.vertexID * 3 + v1.vertexID + v2.vertexID) * uint3(1597334677U, 3812015801U, 2912667907U);
    uint3 n1 = (v0.vertexID + v1.vertexID * 3 + v2.vertexID) * uint3(1597334677U, 3812015801U, 2912667907U);
    uint3 n2 = (v0.vertexID + v1.vertexID + v2.vertexID * 3) * uint3(1597334677U, 3812015801U, 2912667907U);
    float3 noise0 = normalize(float3(n0) * (2.0 / float(0xffffffffU)) - 1.0);
    float3 noise1 = normalize(float3(n1) * (2.0 / float(0xffffffffU)) - 1.0);
    float3 noise2 = normalize(float3(n2) * (2.0 / float(0xffffffffU)) - 1.0);

    float3 fur0 = (v0.furVectorWS + noise0 * _FurVector.w * _FurRandomize) * len0;
    float3 fur1 = (v1.furVectorWS + noise1 * _FurVector.w * _FurRandomize) * len1;
    float3 fur2 = (v2.furVectorWS + noise2 * _FurVector.w * _FurRandomize) * len2;

    if(_FurLayerNum < 1.5)
    {
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(1.0, 0.0, 0.0), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.0, 1.0, 0.0), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.0, 0.0, 1.0), outStream);
    }
    else
    {
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(1.0, 0.0, 0.0), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.0, 0.5, 0.5), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.0, 1.0, 0.0), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.5, 0.0, 0.5), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.0, 0.0, 1.0), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.5, 0.5, 0.0), outStream);
    }

    if(_FurLayerNum >= 2.5)
    {
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.166667, 0.666667, 0.166667), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.0, 0.5, 0.5), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.166667, 0.166667, 0.666667), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.5, 0.0, 0.5), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.666667, 0.166667, 0.166667), outStream);
        LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(0.5, 0.5, 0.0), outStream);
    }

    LTSKKS_AppendFurStripPoint(v0, v1, v2, fur0, fur1, fur2, float3(1.0, 0.0, 0.0), outStream);
    outStream.RestartStrip();
}

[maxvertexcount(26)]
void geom(triangle LTSKKSFurV2G input[3], inout TriangleStream<LTSKKSV2F> outStream)
{
    if(_Invisible > 0.5) return;

    LTSKKS_AppendFurStrips(input[0], input[1], input[2], outStream);
}

void LTSKKS_ApplyFurAlpha(inout LTSKKSFragData fd, LTSKKSV2F i)
{
    float furLayer = saturate(i.furLayer);
    float furLayerShift = furLayer - furLayer * _FurRootOffset + _FurRootOffset;
    float furLayerAbs = abs(furLayerShift);
    float2 noiseUV = LTSKKS_CalcUV(fd.uv0, _FurNoiseMask_ST);
    float furNoise = tex2D(_FurNoiseMask, noiseUV).r;
    float furMask = tex2D(_FurMask, fd.uvMain).r;

    #if defined(LTSKKS_RENDER_CUTOUT) || defined(LTSKKS_FUR_PRE)
        float furAlpha = saturate(furNoise - furLayerShift * furLayerAbs * furLayerAbs * furLayerAbs + 0.25);
    #else
        float furAlpha = saturate(furNoise - furLayerShift * furLayerAbs * furLayerAbs);
    #endif
    fd.col.a *= furAlpha * furMask;

    #if defined(LTSKKS_RENDER_CUTOUT)
        fd.col.a = LTSKKS_ApplyDitherToAlpha(fd.col.a, i.pos);
        LTSKKS_ClipAlpha(fd.col.a, _Cutoff);
    #elif defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        LTSKKS_ClipAlpha(fd.col.a, _Cutoff);
        #if defined(LTSKKS_TRANSPARENT_PRE)
            LTSKKS_ClipSubpassAlpha(fd.col.a, i.pos);
            fd.col *= _PreColor;
            LTSKKS_ClipAlpha(fd.col.a, _PreCutoff);
        #elif defined(LTSKKS_PASS_FORWARDADD)
            fd.col.a = saturate(fd.col.a * _AlphaBoostFA);
        #endif
    #endif
}

void LTSKKS_ApplyFurAOAndRim(inout LTSKKSFragData fd, LTSKKSV2F i)
{
    float furLayer = saturate(i.furLayer);
    float2 noiseUV = LTSKKS_CalcUV(fd.uv0, _FurNoiseMask_ST);
    float furNoise = tex2D(_FurNoiseMask, noiseUV).r;

    #if defined(LTSKKS_RENDER_CUTOUT) || defined(LTSKKS_FUR_PRE)
        float furAO = _FurAO * saturate(1.0 - fwidth(i.furLayer));
        fd.col.rgb *= furLayer * furAO * 2.0 + 1.0 - furAO;
    #else
        float furAO = saturate(1.0 - furNoise + furNoise * furLayer) * _FurAO * 1.25 + 1.0 - _FurAO;
        fd.col.rgb *= furAO;
    #endif

    float fresnel = pow(saturate(1.0 - abs(dot(normalize(fd.N), fd.V))), max(_FurRimFresnelPower, 0.01));
    float antiLight = lerp(1.0, LTSKKS_OpenLitGray(fd.invLighting), saturate(_FurRimAntiLight));
    fd.col.rgb += furLayer * fresnel * antiLight * _FurRimColor.rgb * fd.lightColor;
}

float4 frag(LTSKKSV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    LTSKKSFragData fd = LTSKKS_InitFragData();
    fd.uv0 = i.uv01.xy;
    fd.uv1 = i.uv01.zw;
    fd.uv2 = i.uv23.xy;
    fd.uv3 = i.uv23.zw;
    fd.posWS = i.posWS;
    fd.depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
    fd.facing = facing;

    if(_Invisible > 0.5) discard;

    LTSKKS_PrepareSurfaceBasis(fd, i);
    LTSKKS_ApplyMain(fd);
    LTSKKS_ApplyNormal(fd, i);
    LTSKKS_PrepareLighting(fd, i);
    LTSKKS_ApplyMainLayers(fd);
    LTSKKS_ApplyAlphaMask(fd);
    LTSKKS_ApplyGlobalDissolve(fd);
    LTSKKS_ApplyFurAlpha(fd, i);

    fd.albedo = fd.col.rgb;
    LTSKKS_ApplyShadow(fd);
    LTSKKS_ApplyMainLayersAfterLighting(fd);
    LTSKKS_ApplyRimShade(fd);
    LTSKKS_ApplyFurAOAndRim(fd, i);
    LTSKKS_ApplyDissolveEmission(fd);

    fd.col.rgb = (fd.facing < 0.0) ? lerp(fd.col.rgb, _BackfaceColor.rgb * fd.lightColor, _BackfaceColor.a) : fd.col.rgb;
    fd.col.rgb = min(fd.col.rgb, float3(_BeforeExposureLimit, _BeforeExposureLimit, _BeforeExposureLimit));
    fd.col = LTSKKS_PremultiplyTransparentColor(fd.col);
    UNITY_APPLY_FOG(i.fogCoord, fd.col);
    return fd.col;
}

#endif
