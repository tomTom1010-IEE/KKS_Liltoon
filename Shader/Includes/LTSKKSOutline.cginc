#ifndef LTSKKS_OUTLINE_INCLUDED
#define LTSKKS_OUTLINE_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSParallax.cginc"
#include "LTSKKSAlpha.cginc"

struct LTSKKSOutlineAppData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float3 LTSKKS_OutlineGetLightDirection(float3 posWS)
{
    float3 lightVector = _WorldSpaceLightPos0.xyz - posWS * _WorldSpaceLightPos0.w;
    return normalize(lightVector);
}

float3 LTSKKS_OutlineApplyLightColorOptions(float3 lightColor)
{
    lightColor = min(max(lightColor, float3(_LightMinLimit, _LightMinLimit, _LightMinLimit)), float3(_LightMaxLimit, _LightMaxLimit, _LightMaxLimit));
    float gray = dot(lightColor, float3(0.299, 0.587, 0.114));
    lightColor = lerp(lightColor, float3(gray, gray, gray), saturate(_MonochromeLighting));
    return lerp(lightColor, 1.0, saturate(_AsUnlit));
}

float3 LTSKKS_OutlineGetLightColor(float attenuation)
{
    return LTSKKS_OutlineApplyLightColorOptions(_LightColor0.rgb * attenuation * _lilDirectionalLightStrength);
}

float3 LTSKKS_OutlineGetVertexLightColor(float3 posWS)
{
    float3 vertexLight = 0.0;
    #if defined(LIGHTPROBE_SH) && defined(VERTEXLIGHT_ON)
        float4 toLightX = unity_4LightPosX0 - posWS.x;
        float4 toLightY = unity_4LightPosY0 - posWS.y;
        float4 toLightZ = unity_4LightPosZ0 - posWS.z;
        float4 lengthSq = toLightX * toLightX + toLightY * toLightY + toLightZ * toLightZ + 0.000001;
        float4 atten = saturate(saturate((25.0 - lengthSq * unity_4LightAtten0) * 0.111375) / (0.987725 + lengthSq * unity_4LightAtten0)) * saturate(_VertexLightStrength);

        vertexLight += unity_LightColor[0].rgb * atten.x;
        vertexLight += unity_LightColor[1].rgb * atten.y;
        vertexLight += unity_LightColor[2].rgb * atten.z;
        vertexLight += unity_LightColor[3].rgb * atten.w;
    #endif
    return vertexLight;
}

float LTSKKS_GetOutlineWidth(float2 uv, float4 color)
{
    float width = _OutlineWidth * 0.01;
    width *= tex2Dlod(_OutlineWidthMask, float4(uv, 0.0, 0.0)).r;
    width *= (_OutlineVertexR2Width > 0.5 && _OutlineVertexR2Width < 1.5) ? color.r : 1.0;
    width *= (_OutlineVertexR2Width >= 1.5 && _OutlineVertexR2Width < 2.5) ? color.a : 1.0;
    return width;
}

float3 LTSKKS_GetOutlineVectorOS(LTSKKSOutlineAppData v, float2 uv)
{
    float3 normalOS = normalize(v.normal);
    float3 tangentOS = normalize(v.tangent.xyz);
    float3 bitangentOS = normalize(cross(normalOS, tangentOS) * v.tangent.w);
    float3x3 tbnOS = float3x3(tangentOS, bitangentOS, normalOS);

    float2 vectorUV = uv;
    vectorUV = (_OutlineVectorUVMode > 0.5 && _OutlineVectorUVMode < 1.5) ? v.texcoord1.xy : vectorUV;
    vectorUV = (_OutlineVectorUVMode >= 1.5 && _OutlineVectorUVMode < 2.5) ? v.texcoord2.xy : vectorUV;
    vectorUV = (_OutlineVectorUVMode >= 2.5 && _OutlineVectorUVMode < 3.5) ? v.texcoord3.xy : vectorUV;

    float3 normalTS = LTSKKS_UnpackNormalScale(tex2Dlod(_OutlineVectorTex, float4(vectorUV, 0.0, 0.0)), _OutlineVectorScale);
    float3 outlineOS = normalize(mul(normalTS, tbnOS));
    outlineOS = (_OutlineVertexR2Width >= 1.5 && _OutlineVertexR2Width < 2.5) ? normalize(mul(v.color.rgb * 2.0 - 1.0, tbnOS)) : outlineOS;
    return outlineOS;
}

float3 LTSKKS_GetOutlinedPositionOS(LTSKKSOutlineAppData v, float outlineZBias, out float3 outlineOS)
{
    float3 positionOS = v.vertex.xyz;
    float3 positionWS = mul(unity_ObjectToWorld, float4(positionOS, 1.0)).xyz;
    float width = LTSKKS_GetOutlineWidth(v.texcoord.xy, v.color);
    float distScale = saturate(distance(_WorldSpaceCameraPos.xyz, positionWS));
    width *= lerp(1.0, max(distScale, 0.01), saturate(_OutlineFixWidth));

    outlineOS = LTSKKS_GetOutlineVectorOS(v, v.texcoord.xy);
    if(_OutlineDeleteMesh > 0.5 && abs(width) < 0.000001) positionOS = float3(1e20, 1e20, 1e20);
    positionOS += outlineOS * width;
    positionOS -= normalize(ObjSpaceViewDir(float4(positionOS, 1.0))) * outlineZBias;
    return positionOS;
}

#if defined(LTSKKS_PASS_OUTLINE_SHADOWCASTER)

struct LTSKKSOutlineShadowV2F
{
    V2F_SHADOW_CASTER;
    float4 uv01 : TEXCOORD1;
    float4 uv23 : TEXCOORD2;
    float2 uvMain : TEXCOORD3;
    float2 uvMat : TEXCOORD4;
    float3 posWS : TEXCOORD5;
    float3 normalWS : TEXCOORD6;
    float4 tangentWS : TEXCOORD7;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSOutlineShadowV2F vert(LTSKKSOutlineAppData v)
{
    LTSKKSOutlineShadowV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSOutlineShadowV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float3 outlineOS;
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    o.uvMat = LTSKKS_MatCapUV(o.normalWS).xy;
    v.vertex.xyz = LTSKKS_GetOutlinedPositionOS(v, 0.0, outlineOS);
    v.normal = normalize(outlineOS);
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
    return o;
}

float4 frag(LTSKKSOutlineShadowV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5 || _UseOutline < 0.5) discard;
    float depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
    float2 uv0 = i.uv01.xy;
    float2 uvMain = i.uvMain;
    float2 ddxMain = abs(ddx(uvMain));
    float2 ddyMain = abs(ddy(uvMain));
    LTSKKS_ApplyAuxiliaryMainParallax(uvMain, uv0, i.posWS, i.normalWS, i.tangentWS);
    float alpha = LTSKKS_GetLayeredProcessedAlphaGrad(uv0, i.uv01.zw, i.uv23.xy, i.uv23.zw, i.uvMat, uvMain, ddxMain, ddyMain, facing, depth);
    LTSKKS_ClipShadowAlpha(alpha, i.pos);
    SHADOW_CASTER_FRAGMENT(i)
}

#else

struct LTSKKSOutlineV2F
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float3 posWS : TEXCOORD2;
    float2 uvMain : TEXCOORD5;
    float4 uv01 : TEXCOORD6;
    float4 uv23 : TEXCOORD7;
    float3 baseNormalWS : TEXCOORD8;
    float4 tangentWS : TEXCOORD9;
    SHADOW_COORDS(3)
    UNITY_FOG_COORDS(4)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSOutlineV2F vert(LTSKKSOutlineAppData v)
{
    LTSKKSOutlineV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSOutlineV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    float2 uv = LTSKKS_CalcUV(v.texcoord.xy, _OutlineTex_ST, _OutlineTex_ScrollRotate);
    float3 outlineOS;
    float3 positionOS = LTSKKS_GetOutlinedPositionOS(v, _OutlineZBias, outlineOS);

    o.pos = UnityObjectToClipPos(float4(positionOS, 1.0));
    o.uv = uv;
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.baseNormalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    o.posWS = mul(unity_ObjectToWorld, float4(positionOS, 1.0)).xyz;
    o.normalWS = UnityObjectToWorldNormal(outlineOS);
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

float4 frag(LTSKKSOutlineV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5 || _UseOutline < 0.5) discard;
    #if defined(LTSKKS_RENDER_CUTOUT) || defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        float depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
        float2 uv0 = i.uv01.xy;
        float2 uvMain = i.uvMain;
        float2 ddxMain = abs(ddx(uvMain));
        float2 ddyMain = abs(ddy(uvMain));
        LTSKKS_ApplyAuxiliaryMainParallax(uvMain, uv0, i.posWS, i.baseNormalWS, i.tangentWS);
        float2 uvMat = LTSKKS_MatCapUV(normalize(i.baseNormalWS)).xy;
        float outlineAlpha = LTSKKS_GetLayeredProcessedAlphaGrad(uv0, i.uv01.zw, i.uv23.xy, i.uv23.zw, uvMat, uvMain, ddxMain, ddyMain, facing, depth);
        #if defined(LTSKKS_RENDER_CUTOUT)
            outlineAlpha = LTSKKS_ApplyDitherToAlpha(outlineAlpha, i.pos);
            LTSKKS_ClipAlpha(outlineAlpha, _Cutoff);
        #else
            LTSKKS_ClipAlpha(outlineAlpha, _Cutoff);
            LTSKKS_ClipSubpassAlpha(outlineAlpha, i.pos);
        #endif
    #endif

    float4 col = tex2D(_OutlineTex, i.uv);
    col.rgb = LTSKKS_ToneCorrection(col.rgb, _OutlineTexHSVG);

    float3 n = normalize(i.normalWS);
    float3 l = LTSKKS_OutlineGetLightDirection(i.posWS);
    float outlineNdotL = dot(normalize(mul((float3x3)UNITY_MATRIX_V, n).xy), normalize(mul((float3x3)UNITY_MATRIX_V, l).xy)) * 0.5 + 0.5;
    float3 outlineLitColor = (_OutlineLitApplyTex > 0.5) ? col.rgb * _OutlineLitColor.rgb : _OutlineLitColor.rgb;
    float outlineLitFactor = saturate(outlineNdotL * _OutlineLitScale + _OutlineLitOffset) * _OutlineLitColor.a;

    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWS);
    if(_OutlineLitShadowReceive > 0.5) outlineLitFactor *= attenuation;

    float3 lightColor = LTSKKS_OutlineGetLightColor(attenuation);
    #if !defined(LTSKKS_PASS_FORWARDADD)
        float3 vertexLightColor = LTSKKS_OutlineGetVertexLightColor(i.posWS);
        lightColor = LTSKKS_OutlineApplyLightColorOptions(_LightColor0.rgb * attenuation * _lilDirectionalLightStrength + vertexLightColor);
    #endif
    col.rgb = lerp(col.rgb * _OutlineColor.rgb, outlineLitColor, outlineLitFactor);
    col.rgb = lerp(col.rgb, col.rgb * lightColor, saturate(_OutlineEnableLighting));
    col.a *= _OutlineColor.a;
    UNITY_APPLY_FOG(i.fogCoord, col);
    return col;
}

#endif

#endif
