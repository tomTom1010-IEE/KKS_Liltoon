#ifndef LTSKKS_KKS_FACE_GRADE_INCLUDED
#define LTSKKS_KKS_FACE_GRADE_INCLUDED

void LTSKKS_ApplyKKSFaceGrade(
    LTSKKSFragData fd,
    inout float4 lns,
    inout float shadowAAStrength)
{
    // Keep lilToon's Flat and RGBA SDF modes authoritative.
    if(_KKSFaceGradeMode < 0.5 || _ShadowMaskType > 0.5) return;

    float angle = _KKSFaceGradeDirectionOffset * 0.01745329252;
    float angleSin;
    float angleCos;
    sincos(angle, angleSin, angleCos);

    float3 localFaceForward = float3(angleSin, 0.0, angleCos);
    float3 localFaceRight = float3(-angleCos, 0.0, angleSin);
    float3 faceForward = mul((float3x3)unity_ObjectToWorld, localFaceForward);
    float3 faceRight = mul((float3x3)unity_ObjectToWorld, localFaceRight);

    float side = dot(fd.L.xz, faceRight.xz);
    float2 gradeUV = fd.uvMain;
    if(_KKSFaceGradeMode > 1.5 && side < 0.0)
    {
        gradeUV.x = 1.0 - gradeUV.x;
    }
    gradeUV = LTSKKS_CalcUV(gradeUV, _KKSFaceGradeMap_ST);

    float grade = UNITY_SAMPLE_TEX2D(_KKSFaceGradeMap, gradeUV).r;
    grade = lerp(grade, 1.0 - grade, saturate(_KKSFaceGradeInvert));

    faceForward.y *= _ShadowFlatBlur;
    faceForward = (dot(faceForward, faceForward) < LTSKKS_EPS) ? 0.0 : normalize(faceForward);
    float3 faceLight = fd.L;
    faceLight.y *= _ShadowFlatBlur;
    faceLight = (dot(faceLight, faceLight) < LTSKKS_EPS) ? 0.0 : normalize(faceLight);

    float faceRelation = dot(faceLight, faceForward);
    float gradeShadow = saturate(faceRelation * 0.5 + grade * 0.5 + 0.25 + _KKSFaceGradeOffset);
    float strength = saturate(_KKSFaceGradeStrength);
    lns = lerp(lns, float4(gradeShadow, gradeShadow, gradeShadow, gradeShadow), strength);
    shadowAAStrength = lerp(shadowAAStrength, 0.0, strength);
}

#endif
