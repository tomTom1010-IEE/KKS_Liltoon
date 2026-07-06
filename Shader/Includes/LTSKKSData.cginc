#ifndef LTSKKS_DATA_INCLUDED
#define LTSKKS_DATA_INCLUDED

struct LTSKKSAppData
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

struct LTSKKSV2F
{
    float4 pos : SV_POSITION;
    float4 uv01 : TEXCOORD0;
    float4 uv23 : TEXCOORD1;
    float3 posWS : TEXCOORD2;
    float3 normalWS : TEXCOORD3;
    float4 tangentWS : TEXCOORD4;
    float3 bitangentWS : TEXCOORD5;
    float4 color : COLOR;
    float3 vertexLightColor : TEXCOORD8;
    SHADOW_COORDS(6)
    UNITY_FOG_COORDS(7)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

struct LTSKKSFragData
{
    float4 col;
    float4 main2ndLayer;
    float4 main3rdLayer;
    float3 albedo;
    float3 emissionColor;
    float2 uv0;
    float2 uv1;
    float2 uv2;
    float2 uv3;
    float2 uvMain;
    float2 uvMat;
    float2 ddxMain;
    float2 ddyMain;
    float3 posWS;
    float3 N;
    float3 origN;
    float3 T;
    float3 B;
    float3 V;
    float3 L;
    float3 origL;
    float3 H;
    float ln;
    float nv;
    float nvabs;
    float attenuation;
    float smoothness;
    float perceptualRoughness;
    float roughness;
    float depth;
    float3 lightColor;
    float3 indLightColor;
    float3 addLightColor;
    float shadowmix;
    float facing;
};

LTSKKSFragData LTSKKS_InitFragData()
{
    LTSKKSFragData fd;
    fd.col = 1.0;
    fd.main2ndLayer = 0.0;
    fd.main3rdLayer = 0.0;
    fd.albedo = 1.0;
    fd.emissionColor = 0.0;
    fd.uv0 = fd.uv1 = fd.uv2 = fd.uv3 = fd.uvMain = fd.uvMat = 0.0;
    fd.ddxMain = fd.ddyMain = 0.0;
    fd.posWS = 0.0;
    fd.N = fd.origN = float3(0,0,1);
    fd.T = float3(1,0,0);
    fd.B = float3(0,1,0);
    fd.V = fd.L = fd.origL = fd.H = float3(0,0,1);
    fd.ln = fd.nv = fd.nvabs = 1.0;
    fd.attenuation = 1.0;
    fd.smoothness = 0.0;
    fd.perceptualRoughness = 1.0;
    fd.roughness = 1.0;
    fd.depth = 0.0;
    fd.lightColor = 1.0;
    fd.indLightColor = fd.addLightColor = 0.0;
    fd.shadowmix = 1.0;
    fd.facing = 1.0;
    return fd;
}

#endif
