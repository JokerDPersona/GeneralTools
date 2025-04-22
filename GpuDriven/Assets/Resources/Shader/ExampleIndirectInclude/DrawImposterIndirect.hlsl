#ifndef DRAW_IMPOSTER_INDIRECT
#define DRAW_IMPOSTER_INDIRECT
#include "../CommonInclude/GPUDrivenCommon.hlsl"
#include "../CommonInclude/DynamicImposterCommon.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
int _ImposterMaterialTypeIndex;//总Mesh类型x渲染视口数量+面片材质id
int _AxisFrames;//轴向方位数量

uniform StructuredBuffer<InstanceData> _StaticGpuDrivenIndirectAllInstanceDatas;//所有Instance的M矩阵以及自定义的数据
uniform StructuredBuffer<uint> _StaticGpuDrivenIndirectInstanceTypeIndexStart;
uniform StructuredBuffer<uint> _StaticGpuDrivenIndirectCullInstanceIds;
uniform StructuredBuffer<MeshData> _StaticGpuDrivenAllGpuMeshBuffer;

float3 _MeshCenter;
float4 _ImposterMeshFitSize;
float4 _ImposterMeshScaleAndOffset;
int _DynamicImposterId;
int _MeshType;
 
void DrawImposterSetUp()
{
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
    const uint startIndex = _StaticGpuDrivenIndirectInstanceTypeIndexStart[_ImposterMaterialTypeIndex];
    const uint imposterTempData = _StaticGpuDrivenIndirectCullInstanceIds[startIndex + unity_InstanceID];

    uint index,dynamicImposterDirIntId;
    UnpackImposterInstanceTempData(imposterTempData,index,dynamicImposterDirIntId);

    const InstanceData data = _StaticGpuDrivenIndirectAllInstanceDatas[index];
    const MeshData lod0MeshData = _StaticGpuDrivenAllGpuMeshBuffer[data.lod0MeshId];
    
    float3 value0 = data.pos; float3 _position = value0;
    
    float3 scale;
    uint customInstanceId;
    GetScaleAndCustomInstanceId(data.scaleXZ,data.scaleYAndCustomInstanceId,scale,customInstanceId);
    
    float4 quter = GetQuterByPacked(data.quterXY,data.quterZW);
    unity_ObjectToWorld = GetLocalToWorldMatrix(_position,quter,scale);
    unity_WorldToObject = Inverse(unity_ObjectToWorld);

    _MeshType = data.lod0MeshId; 
    _MeshCenter = lod0MeshData.meshCenter;
    _ImposterMeshFitSize = lod0MeshData.imposterFitSize;
    _ImposterMeshScaleAndOffset = lod0MeshData.imposterMeshScaleAndOffset;
    _DynamicImposterId = GetDynamicImposterId(data.lod0MeshId,dynamicImposterDirIntId);
    
    #endif
}



#endif