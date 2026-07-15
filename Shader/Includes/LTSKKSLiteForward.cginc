#ifndef LTSKKS_LITE_FORWARD_INCLUDED
#define LTSKKS_LITE_FORWARD_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSLiteInput.cginc"
#include "LTSKKSLiteAlpha.cginc"

struct LTSKKSLiteAppData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    float4 texcoord3 : TEXCOORD3;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct LTSKKSLiteV2F
{
    float4 pos : SV_POSITION;
    float4 uv01 : TEXCOORD0;
    float4 uv23 : TEXCOORD1;
    float3 posWS : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float3 vertexLight : TEXCOORD4;
    SHADOW_COORDS(5)
    UNITY_FOG_COORDS(6)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

float3 LTSKKS_LiteLightOptions(float3 color)
{
    color = min(max(color, _LightMinLimit.xxx), _LightMaxLimit.xxx);
    float gray = dot(color, float3(0.299, 0.587, 0.114));
    color = lerp(color, gray.xxx, saturate(_MonochromeLighting));
    return lerp(color, 1.0, saturate(_AsUnlit));
}

float3 LTSKKS_LiteVertexLights(float3 posWS)
{
    float3 color = 0.0;
    #if defined(VERTEXLIGHT_ON)
        float4 x = unity_4LightPosX0 - posWS.x;
        float4 y = unity_4LightPosY0 - posWS.y;
        float4 z = unity_4LightPosZ0 - posWS.z;
        float4 lengthSq = x*x + y*y + z*z + 0.000001;
        float4 atten = saturate(saturate((25.0 - lengthSq * unity_4LightAtten0) * 0.111375) / (0.987725 + lengthSq * unity_4LightAtten0));
        atten *= saturate(_VertexLightStrength);
        color += unity_LightColor[0].rgb * atten.x;
        color += unity_LightColor[1].rgb * atten.y;
        color += unity_LightColor[2].rgb * atten.z;
        color += unity_LightColor[3].rgb * atten.w;
    #endif
    return color;
}

float LTSKKS_LiteToon(float value, float border, float blur)
{
    float aa = fwidth(value) * saturate(_AAStrength);
    float width = max(blur + aa, 0.0001);
    return saturate((value - (border - width * 0.5)) / width);
}

float LTSKKS_LiteBlink(float4 blink)
{
    float wave = sin((_Time.y + blink.z) * max(blink.y, 0.0)) * 0.5 + 0.5;
    return lerp(1.0, lerp(1.0 - blink.x, 1.0 + blink.x, wave), saturate(blink.w));
}

LTSKKSLiteV2F vert(LTSKKSLiteAppData v)
{
    LTSKKSLiteV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSLiteV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.vertexLight = LTSKKS_LiteVertexLights(o.posWS);
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

float4 frag(LTSKKSLiteV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
    if(_Invisible > 0.5) discard;

    float2 uvMain = LTSKKS_CalcUV(i.uv01.xy, _MainTex_ST, _MainTex_ScrollRotate);
    float4 mainColor = tex2D(_MainTex, uvMain) * _Color;
    LTSKKS_LiteClipForwardAlpha(mainColor.a);
    float4 triMask = tex2D(_TriMask, uvMain);

    float3 N = normalize(i.normalWS);
    if(facing < 0.0 && _FlipNormal > 0.5) N = -N;
    float3 V = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
    float3 L = normalize(_WorldSpaceLightPos0.xyz - i.posWS * _WorldSpaceLightPos0.w);
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWS);

    float3 rawLight = _LightColor0.rgb * attenuation * _lilDirectionalLightStrength;
    #if !defined(LTSKKS_LITE_FORWARDADD)
        rawLight += i.vertexLight;
    #endif
    float3 lightColor = LTSKKS_LiteLightOptions(rawLight);
    float ln = dot(N, L);
    float ln01 = saturate(ln * 0.5 + 0.5);

    #if !defined(LTSKKS_LITE_FORWARDADD)
        if(_UseMatCap > 0.5)
        {
            float2 matUV = LTSKKS_CalcMatCapUV(i.uv01.zw, N, V, _MatCapTex_ST, _MatCapBlendUV1.xy, _MatCapZRotCancel, _MatCapPerspective, _MatCapVRParallaxStrength);
            float3 matcap = tex2D(_MatCapTex, matUV).rgb;
            float3 combined = (_MatCapMul > 0.5) ? mainColor.rgb * matcap : mainColor.rgb + matcap;
            mainColor.rgb = lerp(mainColor.rgb, combined, triMask.r);
        }
    #endif

    float3 albedo = mainColor.rgb;
    float shadowMix = 1.0;
    float3 color;
    if(_UseShadow > 0.5)
    {
        float shade1 = LTSKKS_LiteToon(ln01, _ShadowBorder, _ShadowBlur);
        float shade2 = LTSKKS_LiteToon(ln01, _Shadow2ndBorder, _Shadow2ndBlur);
        float borderShade = LTSKKS_LiteToon(ln01, _ShadowBorder, _ShadowBlur + _ShadowBorderRange);
        float backfaceShadow = (facing < 0.0) ? 1.0 - _BackfaceForceShadow : 1.0;
        shade1 *= backfaceShadow;
        shade2 *= backfaceShadow;
        borderShade *= backfaceShadow;
        shadowMix = shade1;

        #if defined(LTSKKS_LITE_FORWARDADD)
            color = albedo * lightColor * shade1;
        #else
            float4 shadow1 = tex2D(_ShadowColorTex, uvMain);
            float4 shadow2 = tex2D(_Shadow2ndColorTex, uvMain);
            float3 indirect = lerp(albedo, shadow1.rgb, shadow1.a);
            indirect = lerp(indirect, shadow2.rgb, shadow2.a * (1.0 - shade2));
            float3 direct = albedo * lightColor;
            indirect *= lightColor;
            float env = saturate(dot(max(ShadeSH9(float4(N, 1.0)), 0.0), float3(0.299, 0.587, 0.114)) * _ShadowEnvStrength);
            indirect = lerp(indirect, albedo, env);
            indirect = min(indirect, direct);
            indirect = lerp(indirect, direct, borderShade * _ShadowBorderColor.rgb);
            color = lerp(indirect, direct, shade1);
        #endif
    }
    else
    {
        color = albedo * lightColor;
    }

    float nv = abs(dot(N, V));
    if(_UseRim > 0.5)
    {
        float rim = pow(saturate(1.0 - nv), _RimFresnelPower);
        rim = LTSKKS_LiteToon(rim, _RimBorder, _RimBlur);
        rim = lerp(rim, rim * shadowMix, saturate(_RimShadowMask));
        color += rim * triMask.g * _RimColor.rgb * lightColor * _RimColor.a;
    }

    #if !defined(LTSKKS_LITE_FORWARDADD)
        if(_UseEmission > 0.5)
        {
            float2 emissionUV = i.uv01.xy;
            if(_EmissionMap_UVMode > 0.5 && _EmissionMap_UVMode < 1.5) emissionUV = i.uv01.zw;
            if(_EmissionMap_UVMode >= 1.5 && _EmissionMap_UVMode < 2.5) emissionUV = i.uv23.xy;
            if(_EmissionMap_UVMode >= 2.5 && _EmissionMap_UVMode < 3.5) emissionUV = i.uv23.zw;
            if(_EmissionMap_UVMode >= 3.5 && _EmissionMap_UVMode < 4.5) emissionUV = nv.xx;
            emissionUV = LTSKKS_CalcUV(emissionUV, _EmissionMap_ST, _EmissionMap_ScrollRotate);
            float4 emission = tex2D(_EmissionMap, emissionUV) * _EmissionColor;
            color += emission.rgb * emission.a * triMask.b * LTSKKS_LiteBlink(_EmissionBlink);
        }
    #endif

    color = min(color, _BeforeExposureLimit.xxx);
    float4 outputColor = float4(color, mainColor.a);
    #if defined(LTSKKS_LITE_FORWARDADD)
        #if defined(LTSKKS_LITE_TRANSPARENT)
            outputColor.rgb *= saturate(mainColor.a * _AlphaBoostFA);
        #endif
        outputColor.a = 0.0;
        UNITY_APPLY_FOG_COLOR(i.fogCoord, outputColor, fixed4(0,0,0,0));
    #else
        outputColor = LTSKKS_LiteFinalizeAlpha(outputColor);
        UNITY_APPLY_FOG(i.fogCoord, outputColor);
    #endif
    return outputColor;
}

#endif
