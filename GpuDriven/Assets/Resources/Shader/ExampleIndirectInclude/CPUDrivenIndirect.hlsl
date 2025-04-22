#ifndef CPUDRIVEN_INDIRECT
#define CPUDRIVEN_INDIRECT

#include "../CommonInclude/GPUDrivenCommon.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/Custom/Include/IndirectCommonInput.hlsl"

#define CPU_RENDER_BATCH_COUNT 400


CBUFFER_START(UnityInstanced)
float4 _StaticGpuDrivenPosAndLod0MeshTypes[CPU_RENDER_BATCH_COUNT];
float4 _StaticGpuDrivenQuters[CPU_RENDER_BATCH_COUNT];
float4 _StaticGpuDrivenScaleAndCustomDatas[CPU_RENDER_BATCH_COUNT];
float4 _StaticGpuDrivenCustomDatas0[CPU_RENDER_BATCH_COUNT];

float4 _DynamicGpuDrivenPosAndLod0MeshTypes[CPU_RENDER_BATCH_COUNT];
float4 _DynamicGpuDrivenQuters[CPU_RENDER_BATCH_COUNT];
float4 _DynamicGpuDrivenScaleAndCustomDatas[CPU_RENDER_BATCH_COUNT];
float4 _DynamicGpuDrivenCustomDatas0[CPU_RENDER_BATCH_COUNT];

CBUFFER_END

uint _CustomInstanceId;
float4 _CustomData0;


void StaticGpuDrivenSetup()
{
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED
    
    float3 position = _StaticGpuDrivenPosAndLod0MeshTypes[unity_InstanceID];
    float4 quter = _StaticGpuDrivenQuters[unity_InstanceID];
    float4 scaleAndCustomData = _StaticGpuDrivenScaleAndCustomDatas[unity_InstanceID];
    _CustomInstanceId = round(scaleAndCustomData.w);
    _CustomData0 = _StaticGpuDrivenCustomDatas0[unity_InstanceID];
    
    unity_ObjectToWorld = GetLocalToWorldMatrix(position,quter,scaleAndCustomData.xyz);
    unity_WorldToObject = Inverse(unity_ObjectToWorld);
    
    #endif
}


void DynamicGpuDrivenSetup()
{
    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED	 

    float3 position = _DynamicGpuDrivenPosAndLod0MeshTypes[unity_InstanceID];
    float4 quter = _DynamicGpuDrivenQuters[unity_InstanceID];
    float4 scaleAndCustomData = _DynamicGpuDrivenScaleAndCustomDatas[unity_InstanceID];
    _CustomInstanceId = round(scaleAndCustomData.w);
    _CustomData0 = _DynamicGpuDrivenCustomDatas0[unity_InstanceID];
    
    unity_ObjectToWorld = GetLocalToWorldMatrix(position,quter,scaleAndCustomData.xyz);
    unity_WorldToObject = Inverse(unity_ObjectToWorld);
    
    #endif
    
}


#endif