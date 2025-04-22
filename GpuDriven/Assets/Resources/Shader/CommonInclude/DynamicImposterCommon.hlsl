#ifndef DYNAMIC_IMPOSTER_COMMON
#define DYNAMIC_IMPOSTER_COMMON

#include "GPUDrivenCommon.hlsl"

#define MAX_IMPOSTER_FRAME_COUNT 32 //需要保证imposter的方位数量小于这个，也就是最大为31


int2 GetDynamicImposterDirId(int axisFrames,float3 worldCameraPos,float3 position, float4 rotation, float3 scale)
{
	int sizeX = axisFrames;
	int sizeY = axisFrames - 1;
	float axisSizeFraction = 1.0f/sizeY;
	float4x4 worldToObjMat = GetWorldToLocalMatrix(position,rotation,scale);
	float3 objectCameraPosition = mul( worldToObjMat, float4( worldCameraPos, 1 ) ).xyz;
	float3 objectCameraDirection = normalize( objectCameraPosition );
	float3 upVector = float3( 0,1,0 );
	// Create vertical radial angle
	float verticalAngle = frac( atan2( -objectCameraDirection.z, -objectCameraDirection.x ) /(PI * 2) ) * sizeX + 0.5;
	// Create horizontal radial angle
	float verticalDot = dot( objectCameraDirection, upVector );
	float upAngle = ( acos( -verticalDot ) /PI ) + axisSizeFraction * 0.5f;
	int2 imposterId = int2( floor( verticalAngle ), min( floor( upAngle * sizeY ), sizeY ) );
	
	return imposterId;
}


int2 GetDynamicImposterDirIdByIntId(int dynamicImposterIntId)
{
	return int2(dynamicImposterIntId/MAX_IMPOSTER_FRAME_COUNT,dynamicImposterIntId%MAX_IMPOSTER_FRAME_COUNT);
}

uint GetDynamicImposterDirIntId(int axisFrames,float3 worldCameraPos,float3 position, float4 rotation, float3 scale)
{
	int2 imposterDirId = GetDynamicImposterDirId(axisFrames,worldCameraPos,position,rotation,scale);
	uint imposterDirIntId = imposterDirId.x * MAX_IMPOSTER_FRAME_COUNT + imposterDirId.y;
	return imposterDirIntId;
}

int GetDynamicImposterId(int axisFrames,int meshLodType,float3 worldCameraPos,float3 position, float4 rotation, float3 scale)
{
	const int allImposterDirType = MAX_IMPOSTER_FRAME_COUNT * MAX_IMPOSTER_FRAME_COUNT;
    int2 imposterDirId = GetDynamicImposterDirId(axisFrames,worldCameraPos,position,rotation,scale);
	const int imposterDirIntId = imposterDirId.x * MAX_IMPOSTER_FRAME_COUNT + imposterDirId.y;
	return meshLodType * allImposterDirType + imposterDirIntId;
}

int GetDynamicImposterId(int meshLodType,int imposterDirIntId)
{
	const int allImposterDirType = MAX_IMPOSTER_FRAME_COUNT * MAX_IMPOSTER_FRAME_COUNT;
	return meshLodType * allImposterDirType + imposterDirIntId;
}


int GetImposterPackId(int imposterId)
{
	const int allImposterDirType = MAX_IMPOSTER_FRAME_COUNT * MAX_IMPOSTER_FRAME_COUNT;
	const int meshLodType = imposterId/allImposterDirType;
	const int imposterDirIntId = imposterId%allImposterDirType;
	int2 imposterDirId = int2(imposterDirIntId/MAX_IMPOSTER_FRAME_COUNT, imposterDirIntId%MAX_IMPOSTER_FRAME_COUNT);

	int packData = 0;
	packData|=meshLodType;
	packData<<=5;
	packData|=imposterDirId.x;
	packData<<=5;
	packData|=imposterDirId.y;

	return packData;
}

uint PackImposterInstanceTempData(uint id,uint dynamicImposterDirIntId)
{
	uint packData = id;
	packData<<=10;
	packData|=dynamicImposterDirIntId;
	return packData;
}

void UnpackImposterInstanceTempData(uint packData,out uint id,out uint dynamicImposterDirIntId)
{
	dynamicImposterDirIntId = packData&0x3ff;
	packData>>=10;
	id = packData;
}






#endif