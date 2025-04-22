#ifndef BAKE_IMPOSTER_VT_INDIRECT
#define BAKE_IMPOSTER_VT_INDIRECT

#define MAX_IMPOSTER_DIR_BATCH_COUNT 512
//#include "GPUDrivenCommon.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"


float4x4 _ImposterCamViewMatrixs[512];
float4x4 _ImposterCamProjectionMatrixs[512];

void BakeImposterSetUp()
{
    unity_ObjectToWorld = float4x4(1, 0, 0, 0,
                                   0, 1, 0, 0,
                                   0, 0, 1, 0,
                                   0, 0, 0, 1);

    unity_WorldToObject = Inverse(unity_ObjectToWorld);

    float4x4 viewMat = _ImposterCamViewMatrixs[unity_InstanceID];;
    unity_MatrixV = viewMat;
    unity_MatrixInvV = Inverse(unity_MatrixV);
    float4x4 pMat = _ImposterCamProjectionMatrixs[unity_InstanceID];
    glstate_matrix_projection = pMat;
    unity_MatrixInvP = Inverse(glstate_matrix_projection);
    unity_MatrixVP = mul(pMat, viewMat);
    unity_MatrixInvVP = Inverse(unity_MatrixVP);
}


#endif
