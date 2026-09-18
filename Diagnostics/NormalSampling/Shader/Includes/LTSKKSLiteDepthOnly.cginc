#ifndef LTSKKS_LITE_DEPTH_ONLY_INCLUDED
#define LTSKKS_LITE_DEPTH_ONLY_INCLUDED

#include "UnityCG.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSLiteInput.cginc"
#include "LTSKKSLiteAlpha.cginc"

struct LTSKKSLiteDepthV2F
{
    float4 pos : SV_POSITION;
    float2 uvMain : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSLiteDepthV2F vert(appdata_base v)
{
    LTSKKSLiteDepthV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSLiteDepthV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    return o;
}

float4 frag(LTSKKSLiteDepthV2F i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5) discard;
    float alpha = LTSKKS_LiteSampleAlpha(i.uvMain);
    LTSKKS_LiteClipDepthAlpha(alpha, i.pos);
    return 0;
}

#endif
