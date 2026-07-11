#ifndef LTSKKS_FORWARD_INCLUDED
#define LTSKKS_FORWARD_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSData.cginc"
#include "LTSKKSPipeline.cginc"
#include "LTSKKSParallax.cginc"
#include "LTSKKSMain.cginc"
#define LTSKKS_ALPHA_WITH_FRAGDATA 1
#include "LTSKKSAlpha.cginc"
#include "LTSKKSNormal.cginc"
#include "LTSKKSAnisotropy.cginc"
#include "LTSKKSShadow.cginc"
#include "LTSKKSReflection.cginc"
#include "LTSKKSMatCap.cginc"
#include "LTSKKSRim.cginc"
#include "LTSKKSGlitter.cginc"
#include "LTSKKSEmission.cginc"

LTSKKSV2F vert(LTSKKSAppData v)
{
    LTSKKSV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    o.bitangentWS = cross(normalize(o.normalWS), normalize(o.tangentWS.xyz)) * o.tangentWS.w;
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.color = v.color;
    o.furLayer = -2.0;
    o.vertexLightColor = LTSKKS_GetVertexLightColor(o.posWS);
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
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

    LTSKKS_ApplyNormal(fd, i);
    LTSKKS_PrepareLighting(fd, i);
    LTSKKS_ApplyMain(fd);
    LTSKKS_ApplyAnisotropy(fd);
    LTSKKS_ApplyMainLayers(fd);
    LTSKKS_ApplyRenderAlpha(fd, i.pos);

    #if defined(LTSKKS_TRANSPARENT_PRE)
        if(_PreOutType > 0.5)
        {
            return LTSKKS_PremultiplyTransparentColor((_PreOutType > 1.5) ? _PreColor : fd.col);
        }
    #endif

    fd.albedo = fd.col.rgb;
    LTSKKS_ApplyShadow(fd);
    LTSKKS_ApplyMainLayersAfterLighting(fd);
    LTSKKS_ApplyRimShade(fd);
    #if !defined(LTSKKS_PASS_FORWARDADD)
        LTSKKS_ApplyBacklight(fd);
    #endif
    LTSKKS_ApplyReflection(fd);
    LTSKKS_ApplyMatCap(fd);
    LTSKKS_ApplyRim(fd);
    LTSKKS_ApplyGlitter(fd);
    #if !defined(LTSKKS_PASS_FORWARDADD)
        LTSKKS_ApplyEmission(fd);
    #endif

    fd.col.rgb = (fd.facing < 0.0) ? lerp(fd.col.rgb, _BackfaceColor.rgb * fd.lightColor, _BackfaceColor.a) : fd.col.rgb;
    fd.col.rgb = min(fd.col.rgb, float3(_BeforeExposureLimit, _BeforeExposureLimit, _BeforeExposureLimit));
    fd.col = LTSKKS_PremultiplyTransparentColor(fd.col);
    UNITY_APPLY_FOG(i.fogCoord, fd.col);
    return fd.col;
}

#endif
