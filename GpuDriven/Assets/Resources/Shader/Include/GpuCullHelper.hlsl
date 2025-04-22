#ifndef GPU_CULL_HELPER
#define GPU_CULL_HELPER

struct GpuBounds
{
    float3 min;
    float3 max;
};

float4 _CameraPlanes[6];

bool IsOutSidePlane(float4 plane, float3 position)
{
    return dot(plane.xyz, position) + plane.w < 0;
}

bool FrustumCullAABB(GpuBounds bounds)
{
    const float3 minPosition = bounds.min;
    const float3 maxPosition = bounds.max;
    [unroll]
    for (int i = 0; i < 6; i++)
    {
        float3 p = minPosition;
        float3 normal = _CameraPlanes[i].xyz;
        //需要获取距离平面最近的坐标
        if (normal.x > 0)
            p.x = maxPosition.x;
        if (normal.y > 0)
            p.y = maxPosition.y;
        if (normal.z > 0)
            p.z = maxPosition.z;
        if (IsOutSidePlane(_CameraPlanes[i], p))
        {
            return true;
        }
    }
    return false;
}



#endif