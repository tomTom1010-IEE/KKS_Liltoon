#ifndef LTSKKS_LITE_OUTLINE_INCLUDED
#define LTSKKS_LITE_OUTLINE_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSLiteInput.cginc"
#include "LTSKKSLiteAlpha.cginc"

struct LTSKKSLiteOutlineAppData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct LTSKKSLiteOutlineV2F
{
    float4 pos : SV_POSITION;
    float2 uvOutline : TEXCOORD0;
    float2 uvMain : TEXCOORD1;
    float3 posWS : TEXCOORD2;
    SHADOW_COORDS(3)
    UNITY_FOG_COORDS(4)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSLiteOutlineV2F vert(LTSKKSLiteOutlineAppData v)
{
    LTSKKSLiteOutlineV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSLiteOutlineV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float width = _OutlineWidth * 0.01 * tex2Dlod(_OutlineWidthMask, float4(v.texcoord.xy, 0, 0)).r;
    if(_OutlineVertexR2Width > 0.5) width *= v.color.r;
    float3 posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    width *= lerp(1.0, max(distance(_WorldSpaceCameraPos.xyz, posWS), 0.01), saturate(_OutlineFixWidth));
    if(_OutlineDeleteMesh > 0.5 && abs(width) < 0.000001) v.vertex.xyz = 1e20;
    v.vertex.xyz += normalize(v.normal) * width;
    v.vertex.xyz -= normalize(ObjSpaceViewDir(v.vertex)) * _OutlineZBias;

    o.pos = UnityObjectToClipPos(v.vertex);
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.uvOutline = LTSKKS_CalcUV(v.texcoord.xy, _OutlineTex_ST, _OutlineTex_ScrollRotate);
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

float4 frag(LTSKKSLiteOutlineV2F i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5 || _UseOutline < 0.5) discard;
    float alpha = LTSKKS_LiteSampleAlpha(i.uvMain);
    LTSKKS_LiteClipForwardAlpha(alpha);

    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWS);
    float3 lightColor = _LightColor0.rgb * attenuation * _lilDirectionalLightStrength;
    lightColor = min(max(lightColor, _LightMinLimit.xxx), _LightMaxLimit.xxx);
    lightColor = lerp(lightColor, 1.0, saturate(_AsUnlit));
    float4 color = tex2D(_OutlineTex, i.uvOutline) * _OutlineColor;
    color.rgb = lerp(color.rgb, color.rgb * lightColor, saturate(_OutlineEnableLighting));
    color.a *= alpha;
    color = LTSKKS_LiteFinalizeAlpha(color);
    UNITY_APPLY_FOG(i.fogCoord, color);
    return color;
}

#endif
