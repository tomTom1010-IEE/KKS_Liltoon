#ifndef LTSKKS_LITE_INPUT_INCLUDED
#define LTSKKS_LITE_INPUT_INCLUDED

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _MainTex_ScrollRotate;
float4 _Color;
sampler2D _TriMask;

float _Invisible;
float _AsUnlit;
float _Cutoff;
float _SubpassCutoff;
float _FlipNormal;
float _BackfaceForceShadow;
float _VertexLightStrength;
float _LightMinLimit;
float _LightMaxLimit;
float _BeforeExposureLimit;
float _MonochromeLighting;
float _AlphaBoostFA;
float _lilDirectionalLightStrength;
float _AAStrength;
sampler3D _DitherMaskLOD;

float _UseShadow;
float _ShadowBorder;
float _ShadowBlur;
sampler2D _ShadowColorTex;
float _Shadow2ndBorder;
float _Shadow2ndBlur;
sampler2D _Shadow2ndColorTex;
float _ShadowEnvStrength;
float4 _ShadowBorderColor;
float _ShadowBorderRange;

float _UseMatCap;
sampler2D _MatCapTex;
float4 _MatCapTex_ST;
float4 _MatCapBlendUV1;
float _MatCapZRotCancel;
float _MatCapPerspective;
float _MatCapVRParallaxStrength;
float _MatCapMul;

float _UseRim;
float4 _RimColor;
float _RimBorder;
float _RimBlur;
float _RimFresnelPower;
float _RimShadowMask;

float _UseEmission;
float4 _EmissionColor;
sampler2D _EmissionMap;
float4 _EmissionMap_ST;
float4 _EmissionMap_ScrollRotate;
float _EmissionMap_UVMode;
float4 _EmissionBlink;

float _UseOutline;
float4 _OutlineColor;
sampler2D _OutlineTex;
float4 _OutlineTex_ST;
float4 _OutlineTex_ScrollRotate;
float _OutlineWidth;
sampler2D _OutlineWidthMask;
float _OutlineFixWidth;
float _OutlineVertexR2Width;
float _OutlineDeleteMesh;
float _OutlineEnableLighting;
float _OutlineZBias;

#endif
