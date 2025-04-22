#ifndef GPUDRIVEN_COMMON
#define GPUDRIVEN_COMMON

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Assets/Resources/Shader/Include/GpuCullHelper.hlsl"

#define FLOAT_MAX 100000000.0f
#define FLOAT_MIN -100000000.0f

#define MESH_TYPE_RENDER_COUNT 16192 //单个Mesh种类能绘制的最大数量
#define MESH_MAX_LOD_COUNT 4
#define WORLD_BUTTOM_HEIGHT -128  //世界的最低高度
#define CONVERT_RADIAN 0.0246399f  //(360.0f/255.0f)/180.0f * 3.1415926f
#define QUTER_SCALE 0.000015259f//0.0039215f //1.0f/255
#define LOD_FADE_DIS 1.0f //lod过渡检查距离
#define ADDITIONAL_SHADOW_DATA_INDEX 5  //多光源数据起始索引，0为主绘制 1~4为级联阴影，5以上为多光源阴影

uniform float4 _GpuDrivenQualityConfigs[8];
uniform int _GpuDrivenQualityLevel;

#define LOD_DISTANCE_SCALE _GpuDrivenQualityConfigs[_GpuDrivenQualityLevel].x
#define MAXIMUM_LOD_LEVEL _GpuDrivenQualityConfigs[_GpuDrivenQualityLevel].y

struct MeshData
{
    float4 lodDistacne; //范围为 lod0:x~y lod1:y~z lod2:z~w lod3:>w
    int4 lodMeshIds; //从lod0开始，-1的话表示没有配置
    float3 meshExtend;
    float3 meshCenter;
    int disableHiz; //1:关闭 0:开启
    int enableShadowCaster; //1:开启 0：关闭
    int enableDynamicImposter; //1:开启 0：关闭
    int runnerImposterMaterialType;
    float4 imposterMeshScaleAndOffset;
    float4 imposterFitSize;
};


struct ClusterData
{
    GpuBounds bounds;
};

struct InstanceData
{
    int lod0MeshId;
    float3 pos; //
    //uint scaleAndRotate;//8位对应一个维度缩放 0~255对应一个维度 缩放0.1f为最小单位 旋转360/255为最小单位
    //uint roatateXZAndCustomInstanceId;//前16位代表旋转XZ轴，后16位代表自定义InstanceData的id
    uint scaleXZ;
    uint scaleYAndCustomInstanceId;
    uint quterXY;
    uint quterZW;
    float4 customData0;
};

struct CustomInstanceData1
{
    float4 instanceParam1;
};

struct CustomInstanceData2
{
    float4 instanceParam1;
    float4 instanceParam2;
};


int GetLodLevel(float4 lodConfig, float dis)
{
    dis *= LOD_DISTANCE_SCALE;
    if (dis < lodConfig.x)
        return max(0,MAXIMUM_LOD_LEVEL);

    if (dis < lodConfig.y)
        return max(1,MAXIMUM_LOD_LEVEL);

    if (dis < lodConfig.z)
        return max(2,MAXIMUM_LOD_LEVEL);

    if (dis < lodConfig.w)
        return max(3,MAXIMUM_LOD_LEVEL);

    return -1;
}

int GetLodFadeId(int4 lodIds, int lodLevel, float4 lodConfig, float dis)
{
    dis *= LOD_DISTANCE_SCALE;
    switch (lodLevel)
    {
    case 0:
        if (abs(dis - lodConfig.x) < LOD_FADE_DIS)
            return lodIds.y;
        break;
    case 1:
        if (abs(dis - lodConfig.x) < LOD_FADE_DIS)
            return lodIds.x;
        if (abs(dis - lodConfig.y) < LOD_FADE_DIS)
            return lodIds.z;
        break;
    case 2:
        if (abs(dis - lodConfig.y) < LOD_FADE_DIS)
            return lodIds.y;
        if (abs(dis - lodConfig.z) < LOD_FADE_DIS)
            return lodIds.w;
        break;
    case 3:
        if (abs(dis - lodConfig.z) < LOD_FADE_DIS)
            return lodIds.z;
        break;
    }

    return -1;
}

int GetLodFadeId(int4 lodIds, int lodLevel, float4 lodConfig, float dis, float bias)
{
    dis *= LOD_DISTANCE_SCALE;
    const float lodFadeDis = LOD_FADE_DIS + bias;
    switch (lodLevel)
    {
    case 0:
        if (abs(dis - lodConfig.x) < lodFadeDis)
            return lodIds.y;
        break;
    case 1:
        if (abs(dis - lodConfig.x) < lodFadeDis)
            return lodIds.x;
        if (abs(dis - lodConfig.y) < lodFadeDis)
            return lodIds.z;
        break;
    case 2:
        if (abs(dis - lodConfig.y) < lodFadeDis)
            return lodIds.y;
        if (abs(dis - lodConfig.z) < lodFadeDis)
            return lodIds.w;
        break;
    case 3:
        if (abs(dis - lodConfig.z) < lodFadeDis)
            return lodIds.z;
        break;
    }

    return -1;
}


int GetInstanceIndexStart(int numObject, int dataIndex, int limitAddtionalShadowObjectCount)
{
    if (dataIndex >= ADDITIONAL_SHADOW_DATA_INDEX)
    {
        return ADDITIONAL_SHADOW_DATA_INDEX * numObject + (dataIndex - ADDITIONAL_SHADOW_DATA_INDEX) *
            limitAddtionalShadowObjectCount;
    }
    else
    {
        return dataIndex * numObject;
    }
}

//0:out 1:In 2:Partial
int Inside(float4 planes[6], GpuBounds bounds)
{
    float3 center = (bounds.max + bounds.min) / 2.0f;
    const float radius = length((bounds.max - bounds.min) / 2.0f);
    bool all_in = true;
    for (int i = 0; i < 6; ++i)
    {
        const float distance = dot(float4(center, 1.0f), planes[i]);
        if (distance + radius < 0)
        {
            return 0;
        }
        all_in = all_in && (distance > radius);
    }
    if (all_in)
        return 1;
    return 2;
}


int Inside(float4 planes[6], float3 center, float radius)
{
    bool all_in = true;
    for (int i = 0; i < 6; ++i)
    {
        const float distance = dot(float4(center, 1.0f), planes[i]);
        if (distance + radius < 0)
        {
            return 0;
        }
        all_in = all_in && (distance > radius);
    }
    if (all_in)
        return 1;
    return 2;
}


//0:out 1:In 2:Partial
int CascadeShadowInside(float4 planes[40], GpuBounds bounds, int cascadeIndex, int planeCount)
{
    float3 center = (bounds.max + bounds.min) / 2.0f;
    const float radius = length((bounds.max - bounds.min) / 2.0f);
    const int startPlaneIndex = cascadeIndex * 10;
    const int endPlaneIndex = startPlaneIndex + planeCount;
    bool all_in = true;
    for (int i = startPlaneIndex; i < endPlaneIndex; ++i)
    {
        const float distance = dot(float4(center, 1.0f), planes[i]);
        if (distance + radius < 0)
        {
            return 0;
        }
        all_in = all_in && (distance > radius);
    }
    if (all_in)
        return 1;
    return 2;
}


int AdditionalShadowInside(float4 planes[1000], GpuBounds bounds, int sliceIndex, int planeCount)
{
    float3 center = (bounds.max + bounds.min) / 2.0f;
    const float radius = length((bounds.max - bounds.min) / 2.0f);
    const int startPlaneIndex = sliceIndex * 10;
    const int endPlaneIndex = startPlaneIndex + planeCount;
    bool all_in = true;
    for (int i = startPlaneIndex; i < endPlaneIndex; ++i)
    {
        const float distance = dot(float4(center, 1.0f), planes[i]);
        if (distance + radius < 0)
        {
            return 0;
        }
        all_in = all_in && (distance > radius);
    }
    if (all_in)
        return 1;
    return 2;
}


int GetLodMeshId(int4 lodMeshId, int lodLevel)
{
    switch (lodLevel)
    {
    case 0:
        return lodMeshId.x;
    case 1:
        return lodMeshId.y;
    case 2:
        return lodMeshId.z;
    case 3:
        return lodMeshId.w;
    }
    return -1;
}

uint PackInstanceTempData(uint id, uint lod, uint dataIndex)
{
    uint packData = id;
    packData <<= 3;
    packData |= lod;
    packData <<= 7;
    packData |= dataIndex;
    return packData;
}

void UnpackInstanceTempData(uint packData, out uint id, out uint lod, out uint dataIndex)
{
    dataIndex = packData & 0x7f;
    packData >>= 7;
    lod = packData & 0x7;
    packData >>= 3;
    id = packData;
}

uint PackFlagToTempData(uint tempData, uint flag)
{
    uint packData = tempData;
    packData <<= 2;
    packData |= flag;
    return packData;
}

void UnpackInstanceTempData(uint packData, out uint tempData, out uint flag)
{
    flag = packData & 0x3;
    packData >>= 2;
    tempData = packData;
}


//检测Bounds和球体是否相交，粗略比较
bool CheckBoundsAndSphereIntersect(GpuBounds bounds, float3 sphereCenter, float sphereRadius)
{
    float3 center = (bounds.max + bounds.min) / 2.0f;
    const float radius = length((bounds.max - bounds.min) / 2.0f);
    float dis = distance(sphereCenter, center);
    return dis < radius + sphereRadius;
}


//packedData0:xz packedData1:y、id
void GetScaleAndCustomInstanceId(uint packedData0, uint packedData1, out float3 scale, out uint customInstanceId)
{
    float scaleZ = (packedData0 & 0xffff) / 100.0f;
    float scaleX = ((packedData0 >> 16) & 0xffff) / 100.0f;
    customInstanceId = (packedData1 & 0xffff);
    float scaleY = ((packedData1 >> 16) & 0xffff) / 100.0f;
    scale = float3(scaleX, scaleY, scaleZ);
}


float4 GetQuterByPacked(uint packedData1, uint packedData2)
{
    /*
    int mm = (0xff & packedData1);
    float w = mm * QUTER_SCALE * 2.0f - 1.0f;
    float z = ((packedData1 >> 8)&0xff) * QUTER_SCALE * 2.0f - 1.0f;
    float y = ((packedData1 >> 16)&0xff) * QUTER_SCALE * 2.0f - 1.0f;
    float x = ((packedData1 >> 24)&0xff) * QUTER_SCALE * 2.0f - 1.0f;
*/

    float y = (0xffff & packedData1) * QUTER_SCALE * 2.0f - 1.0f;
    float x = ((packedData1 >> 16) & 0xffff) * QUTER_SCALE * 2.0f - 1.0f;

    float w = (0xffff & packedData2) * QUTER_SCALE * 2.0f - 1.0f;
    float z = ((packedData2 >> 16) & 0xffff) * QUTER_SCALE * 2.0f - 1.0f;

    return float4(x, y, z, w);
}

float4x4 QuaternionToMatrix(float4 quaternion)
{
    float4x4 result = (float4x4)0;
    float x = quaternion.x;
    float y = quaternion.y;
    float z = quaternion.z;
    float w = quaternion.w;

    float x2 = x + x;
    float y2 = y + y;
    float z2 = z + z;
    float xx = x * x2;
    float xy = x * y2;
    float xz = x * z2;
    float yy = y * y2;
    float yz = y * z2;
    float zz = z * z2;
    float wx = w * x2;
    float wy = w * y2;
    float wz = w * z2;

    result[0][0] = 1.0 - (yy + zz);
    result[0][1] = xy - wz;
    result[0][2] = xz + wy;

    result[1][0] = xy + wz;
    result[1][1] = 1.0 - (xx + zz);
    result[1][2] = yz - wx;

    result[2][0] = xz - wy;
    result[2][1] = yz + wx;
    result[2][2] = 1.0 - (xx + yy);

    result[3][3] = 1.0;

    return result;
}

float4x4 GetLocalToWorldMatrix(float3 position, float4 rotation, float3 scale)
{
    float4x4 m = (float4x4)0;

    m = QuaternionToMatrix(rotation);

    m[0][0] *= scale.x;
    m[0][1] *= scale.y;
    m[0][2] *= scale.z;
    m[1][0] *= scale.x;
    m[1][1] *= scale.y;
    m[1][2] *= scale.z;
    m[2][0] *= scale.x;
    m[2][1] *= scale.y;
    m[2][2] *= scale.z;
    m[3][0] *= scale.x;
    m[3][1] *= scale.y;
    m[3][2] *= scale.z;

    m[0][3] = position.x;
    m[1][3] = position.y;
    m[2][3] = position.z;

    return m;
}


float4x4 GetWorldToLocalMatrix(float3 position, float4 rotation, float3 scale)
{
    return Inverse(GetLocalToWorldMatrix(position, rotation, scale));
}


#endif
