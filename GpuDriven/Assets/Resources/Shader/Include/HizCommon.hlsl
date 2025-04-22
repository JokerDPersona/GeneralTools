#ifndef HIZ_COMMON
#define HIZ_COMMON

Texture2D<float4> _HizMap;
uniform float4 _HizMapSize;
uniform float4x4 _HizCameraMatrixVP;

//将世界坐标转为uv+depth
float3 TransformWorldToUVD(float3 positionWS)
{
    float4 positionHS = mul(_HizCameraMatrixVP, float4(positionWS, 1.0));
    float3 uvd = positionHS.xyz / positionHS.w;
    uvd.xy = (uvd.xy + 1) * 0.5;
    //点可能跑到摄像机背后去，深度会变成负数，需要特殊处理一下
    
    if(uvd.z < 0){
        #if _REVERSE_Z
        uvd.z = 1;
        #else
        uvd.z = 0;
        #endif
    }
    
    return uvd;
}


void GetBoundsUVD(float3 boundMin,float3 boundMax,out float3 boundUVMin,out float3 boundUVMax){
  
    float3 p0 = TransformWorldToUVD(boundMin);
    float3 p1 = TransformWorldToUVD(boundMax);
    float3 p2 = TransformWorldToUVD(float3(boundMin.x,boundMin.y,boundMax.z));
    float3 p3 = TransformWorldToUVD(float3(boundMin.x,boundMax.y,boundMin.z));
    float3 p4 = TransformWorldToUVD(float3(boundMin.x,boundMax.y,boundMax.z));
    float3 p5 = TransformWorldToUVD(float3(boundMax.x,boundMin.y,boundMax.z));
    float3 p6 = TransformWorldToUVD(float3(boundMax.x,boundMax.y,boundMin.z));
    float3 p7 = TransformWorldToUVD(float3(boundMax.x,boundMin.y,boundMin.z));

    float3 min1 = min(min(p0,p1),min(p2,p3));
    float3 min2 = min(min(p4,p5),min(p6,p7));
    boundUVMin = min(min1,min2);

    float3 max1 = max(max(p0,p1),max(p2,p3));
    float3 max2 = max(max(p4,p5),max(p6,p7));
    boundUVMax = max(max1,max2);
}

uint GetHizMip(float3 boundMin,float3 boundMa){
    float2 size = (boundMa.xy - boundMin.xy) * _HizMapSize.xy;
    uint2 mip2 = ceil(log2(size));
    uint mip = clamp(max(mip2.x,mip2.y),1,_HizMapSize.z - 1);
    return mip;
}


float SampleHiz(float2 uv,float mip,float2 mipTexSize){
    uint2 coord = floor(uv * mipTexSize);
    coord = min(coord,round(mipTexSize)-1);
    return _HizMap.mips[mip][coord].r; 
}

//Hiz Cull
bool HizOcclusionCull(float3 boundMin,float3 boundMax){

    float3 boundUVMin,boundUVMax;
    GetBoundsUVD(boundMin,boundMax,boundUVMin,boundUVMax);
    const uint mip = GetHizMip(boundUVMin,boundUVMax);
    const float2 mipTexSize = round(_HizMapSize.xy / pow(2,mip));
    float d1 = SampleHiz(boundUVMin.xy,mip,mipTexSize); 
    float d2 = SampleHiz(boundUVMax.xy,mip,mipTexSize); 
    float d3 = SampleHiz(float2(boundUVMin.x,boundUVMax.y),mip,mipTexSize);
    float d4 = SampleHiz(float2(boundUVMax.x,boundUVMin.y),mip,mipTexSize);
    

    #if _REVERSE_Z
    float depth = boundUVMax.z;
    return d1 > depth && d2 > depth && d3 > depth && d4 > depth;
    #else
    float depth = boundUVMin.z;
    return d1 < depth && d2 < depth && d3 < depth && d4 < depth;
    #endif
}



#endif