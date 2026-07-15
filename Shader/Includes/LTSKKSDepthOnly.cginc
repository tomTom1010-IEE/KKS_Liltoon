#ifndef LTSKKS_DEPTH_ONLY_INCLUDED
#define LTSKKS_DEPTH_ONLY_INCLUDED

#include "UnityCG.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSParallax.cginc"
#include "LTSKKSAlpha.cginc"

struct LTSKKSDepthV2F
{
    float4 pos : SV_POSITION;
    float4 uv01 : TEXCOORD0;
    float4 uv23 : TEXCOORD1;
    float2 uvMain : TEXCOORD2;
    float2 uvMat : TEXCOORD3;
    float3 posWS : TEXCOORD4;
    float3 normalWS : TEXCOORD5;
    float4 tangentWS : TEXCOORD6;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSDepthV2F vert(appdata_full v)
{
    LTSKKSDepthV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSDepthV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    o.uvMat = LTSKKS_MatCapUV(UnityObjectToWorldNormal(v.normal)).xy;
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    return o;
}

float4 frag(LTSKKSDepthV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5) discard;
    float depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
    float2 uv0 = i.uv01.xy;
    float2 uvMain = i.uvMain;
    float2 ddxMain = abs(ddx(uvMain));
    float2 ddyMain = abs(ddy(uvMain));
    LTSKKS_ApplyAuxiliaryMainParallax(uvMain, uv0, i.posWS, i.normalWS, i.tangentWS);
    float alpha = LTSKKS_GetLayeredProcessedAlphaGrad(uv0, i.uv01.zw, i.uv23.xy, i.uv23.zw, i.uvMat, uvMain, ddxMain, ddyMain, facing, depth);
    #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        LTSKKS_ClipTransparentPrepassAlpha(alpha, i.pos);
    #else
        LTSKKS_ClipAlpha(alpha, _Cutoff);
    #endif
    return 0;
}

#endif
