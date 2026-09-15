#ifndef LTSKKS_TESSELLATION_INCLUDED
#define LTSKKS_TESSELLATION_INCLUDED

struct LTSKKSTessellationFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

#ifndef LTSKKS_TESS_APPDATA
    #define LTSKKS_TESS_APPDATA appdata_full
#endif

LTSKKS_TESS_APPDATA vertTess(LTSKKS_TESS_APPDATA v)
{
    return v;
}

float LTSKKS_CalcEdgeTessFactor(float3 wpos0, float3 wpos1, float edgeLen)
{
    float dist = distance((wpos0 + wpos1) * 0.5, _WorldSpaceCameraPos.xyz);
    return max(distance(wpos0, wpos1) * _ScreenParams.y / max(edgeLen * dist, 0.0001), 1.0);
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[patchconstantfunc("hullConst")]
[outputcontrolpoints(3)]
LTSKKS_TESS_APPDATA hull(InputPatch<LTSKKS_TESS_APPDATA, 3> input, uint id : SV_OutputControlPointID)
{
    return input[id];
}

LTSKKSTessellationFactors hullConst(InputPatch<LTSKKS_TESS_APPDATA, 3> input)
{
    LTSKKSTessellationFactors output;
    UNITY_INITIALIZE_OUTPUT(LTSKKSTessellationFactors, output);
    UNITY_SETUP_INSTANCE_ID(input[0]);

    if(_Invisible > 0.5)
    {
        output.edge[0] = 0.0;
        output.edge[1] = 0.0;
        output.edge[2] = 0.0;
        output.inside = 0.0;
        return output;
    }

    float3 posWS0 = mul(unity_ObjectToWorld, input[0].vertex).xyz;
    float3 posWS1 = mul(unity_ObjectToWorld, input[1].vertex).xyz;
    float3 posWS2 = mul(unity_ObjectToWorld, input[2].vertex).xyz;
    float3 normalWS0 = UnityObjectToWorldNormal(input[0].normal);
    float3 normalWS1 = UnityObjectToWorldNormal(input[1].normal);
    float3 normalWS2 = UnityObjectToWorldNormal(input[2].normal);

    float4 tessFactor;
    tessFactor.x = LTSKKS_CalcEdgeTessFactor(posWS1, posWS2, _TessEdge);
    tessFactor.y = LTSKKS_CalcEdgeTessFactor(posWS2, posWS0, _TessEdge);
    tessFactor.z = LTSKKS_CalcEdgeTessFactor(posWS0, posWS1, _TessEdge);
    tessFactor.xyz = min(tessFactor.xyz, _TessFactorMax);

    float3 viewNV = float3(
        abs(dot(normalize(normalWS0), normalize(_WorldSpaceCameraPos.xyz - posWS0))),
        abs(dot(normalize(normalWS1), normalize(_WorldSpaceCameraPos.xyz - posWS1))),
        abs(dot(normalize(normalWS2), normalize(_WorldSpaceCameraPos.xyz - posWS2)))
    );
    viewNV = saturate(1.0 - float3(viewNV.y + viewNV.z, viewNV.z + viewNV.x, viewNV.x + viewNV.y) * 0.5);
    tessFactor.xyz = max(tessFactor.xyz * viewNV * viewNV, 1.0);
    tessFactor.w = (tessFactor.x + tessFactor.y + tessFactor.z) / 3.0;

    float4 clipPos0 = UnityObjectToClipPos(input[0].vertex);
    float4 clipPos1 = UnityObjectToClipPos(input[1].vertex);
    float4 clipPos2 = UnityObjectToClipPos(input[2].vertex);
    clipPos0.xy /= max(abs(clipPos0.w), 0.0001);
    clipPos1.xy /= max(abs(clipPos1.w), 0.0001);
    clipPos2.xy /= max(abs(clipPos2.w), 0.0001);

    bool outside =
        (clipPos0.x >  1.01 && clipPos1.x >  1.01 && clipPos2.x >  1.01) ||
        (clipPos0.x < -1.01 && clipPos1.x < -1.01 && clipPos2.x < -1.01) ||
        (clipPos0.y >  1.01 && clipPos1.y >  1.01 && clipPos2.y >  1.01) ||
        (clipPos0.y < -1.01 && clipPos1.y < -1.01 && clipPos2.y < -1.01);
    tessFactor = outside ? 0.0 : tessFactor;

    output.edge[0] = tessFactor.x;
    output.edge[1] = tessFactor.y;
    output.edge[2] = tessFactor.z;
    output.inside = tessFactor.w;
    return output;
}

[domain("tri")]
LTSKKS_TESS_OUTPUT domain(LTSKKSTessellationFactors tessFactors, const OutputPatch<LTSKKS_TESS_APPDATA, 3> input, float3 bary : SV_DomainLocation)
{
    LTSKKS_TESS_APPDATA output;
    UNITY_INITIALIZE_OUTPUT(LTSKKS_TESS_APPDATA, output);
    UNITY_TRANSFER_INSTANCE_ID(input[0], output);

    output.vertex = input[0].vertex * bary.x + input[1].vertex * bary.y + input[2].vertex * bary.z;
    output.normal = input[0].normal * bary.x + input[1].normal * bary.y + input[2].normal * bary.z;
    output.tangent = input[0].tangent * bary.x + input[1].tangent * bary.y + input[2].tangent * bary.z;
    output.texcoord = input[0].texcoord * bary.x + input[1].texcoord * bary.y + input[2].texcoord * bary.z;
    output.texcoord1 = input[0].texcoord1 * bary.x + input[1].texcoord1 * bary.y + input[2].texcoord1 * bary.z;
    output.texcoord2 = input[0].texcoord2 * bary.x + input[1].texcoord2 * bary.y + input[2].texcoord2 * bary.z;
    output.texcoord3 = input[0].texcoord3 * bary.x + input[1].texcoord3 * bary.y + input[2].texcoord3 * bary.z;
    output.color = input[0].color * bary.x + input[1].color * bary.y + input[2].color * bary.z;

    output.normal = normalize(output.normal);
    output.tangent.xyz = normalize(output.tangent.xyz);
    output.tangent.w = input[0].tangent.w;

    float3 posOS = output.vertex.xyz;
    float3 normalOS0 = normalize(input[0].normal);
    float3 normalOS1 = normalize(input[1].normal);
    float3 normalOS2 = normalize(input[2].normal);
    float3 pt0 = normalOS0 * (dot(input[0].vertex.xyz, normalOS0) - dot(posOS, normalOS0) - _TessShrink * 0.01);
    float3 pt1 = normalOS1 * (dot(input[1].vertex.xyz, normalOS1) - dot(posOS, normalOS1) - _TessShrink * 0.01);
    float3 pt2 = normalOS2 * (dot(input[2].vertex.xyz, normalOS2) - dot(posOS, normalOS2) - _TessShrink * 0.01);
    output.vertex.xyz += (pt0 * bary.x + pt1 * bary.y + pt2 * bary.z) * _TessStrength;

    return vert(output);
}

#endif
