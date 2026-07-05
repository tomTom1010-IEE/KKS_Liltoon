#ifndef LTSKKS_SHADOW_CASTER_INCLUDED
#define LTSKKS_SHADOW_CASTER_INCLUDED

#include "UnityCG.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSAlpha.cginc"

struct LTSKKSShadowV2F
{
    V2F_SHADOW_CASTER;
    float4 uv01 : TEXCOORD1;
    float4 uv23 : TEXCOORD2;
    float2 uvMain : TEXCOORD3;
    float2 uvMat : TEXCOORD4;
    float3 posWS : TEXCOORD5;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSShadowV2F vert(appdata_full v)
{
    LTSKKSShadowV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSShadowV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    o.uvMat = LTSKKS_MatCapUV(UnityObjectToWorldNormal(v.normal)).xy;
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
    return o;
}

float4 frag(LTSKKSShadowV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5) discard;
    float depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
    float alpha = LTSKKS_GetLayeredProcessedAlpha(i.uv01.xy, i.uv01.zw, i.uv23.xy, i.uv23.zw, i.uvMat, i.uvMain, facing, depth);
    LTSKKS_ClipShadowAlpha(alpha, i.pos);
    SHADOW_CASTER_FRAGMENT(i)
}

#endif
