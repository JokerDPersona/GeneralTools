#ifndef GPUDRIVEN_INDIRECT
#define GPUDRIVEN_INDIRECT

#include "../CommonInclude/GPUDrivenCommon.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/Custom/Include/IndirectCommonInput.hlsl"

int _MeshSubType;//Meshid
int _DataIndex;//主绘制的话为0 阴影绘制的话为级联阴影下标+1
uniform float3 _WorldCenterOffset;//大世界中心位置偏移
uniform int _MeshTypeCount;//当前Mesh总数

uniform StructuredBuffer<InstanceData> _StaticGpuDrivenIndirectAllInstanceDatas;//所有Instance的M矩阵以及自定义的数据
uniform StructuredBuffer<uint> _StaticGpuDrivenIndirectInstanceTypeIndexStart;
uniform StructuredBuffer<uint> _StaticGpuDrivenIndirectCullInstanceIds;

uint _CustomInstanceId;
float4 _CustomData0;

//为了统一方法，所以阴影和本体的方法写在一起
void StaticGpuDrivenSetup()
{
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED	 

    const uint startIndex = _StaticGpuDrivenIndirectInstanceTypeIndexStart[_MeshSubType + _DataIndex * _MeshTypeCount];
    const uint finalInstanceId = _StaticGpuDrivenIndirectCullInstanceIds[startIndex + unity_InstanceID];

    InstanceData data = _StaticGpuDrivenIndirectAllInstanceDatas[finalInstanceId];
    float3 value0 = data.pos; float3 _position = value0 + _WorldCenterOffset;
    
    float3 scale;
    uint customInstanceId;
    GetScaleAndCustomInstanceId(data.scaleXZ,data.scaleYAndCustomInstanceId,scale,customInstanceId);
    
    float4 quter = GetQuterByPacked(data.quterXY,data.quterZW);
    unity_ObjectToWorld = GetLocalToWorldMatrix(_position,quter,scale);
    unity_WorldToObject = Inverse(unity_ObjectToWorld);
    _CustomInstanceId = customInstanceId;
    _CustomData0 = data.customData0;
    
    #endif
}

uniform StructuredBuffer<InstanceData> _DynamicGpuDrivenIndirectAllInstanceDatas;//所有Instance的M矩阵以及自定义的数据
uniform StructuredBuffer<uint> _DynamicGpuDrivenIndirectInstanceTypeIndexStart;
uniform StructuredBuffer<uint> _DynamicGpuDrivenIndirectCullInstanceIds;


void DynamicGpuDrivenSetup()
{
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED	 

    const uint startIndex = _DynamicGpuDrivenIndirectInstanceTypeIndexStart[_MeshSubType + _DataIndex * _MeshTypeCount];
    const uint finalInstanceId = _DynamicGpuDrivenIndirectCullInstanceIds[startIndex + unity_InstanceID];

    InstanceData data = _DynamicGpuDrivenIndirectAllInstanceDatas[finalInstanceId];
    float3 value0 = data.pos; float3 _position = value0 + _WorldCenterOffset;
    
    float3 scale;
    uint customInstanceId;
    GetScaleAndCustomInstanceId(data.scaleXZ,data.scaleYAndCustomInstanceId,scale,customInstanceId);
    
    float4 quter = GetQuterByPacked(data.quterXY,data.quterZW);
    unity_ObjectToWorld = GetLocalToWorldMatrix(_position,quter,scale);
    unity_WorldToObject = Inverse(unity_ObjectToWorld);
    _CustomInstanceId = customInstanceId;
    _CustomData0 = data.customData0;
    
    #endif
    
}


#endif