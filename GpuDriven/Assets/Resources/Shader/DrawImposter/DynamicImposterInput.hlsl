#ifndef DYNAMIC_IMPOSTER_INPUT
#define DYNAMIC_IMPOSTER_INPUT
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

//默认走金属度工作流
struct SurfaceOutputStandardMetallic
{
    half3 Albedo;
    half Metallic;
    half2 CustomData;
    float3 Normal;
    half3 Emission;
    half Smoothness;
    half Occlusion;
    half Alpha;
};


Texture2D _Imposter_LookUpTex;

sampler2D _AlbedoAlphaVT;
sampler2D _MetallicSmoothnessVT;//r:金属度 g:光滑度 ba:自定义
sampler2D _NormalDepthVT;
sampler2D _EmissionOcclusionVT;

float4 _Imposter_PageParam;
float4 _AlbedoAlpha_TileParam;


float _ClipMask;



inline void SphereImpostorVertex( int axisFrames,float4 imposterFitSize,float4 imposterScaleAndOffset,
    float3 meshCenter,int meshType,int dynamicImposterId,
    inout float4 vertex, inout float3 normal, inout float2 frameUVs, inout float4 viewPos  )
{
    float sizeX = axisFrames;
    float sizeY = axisFrames - 1;
    float UVscale = imposterFitSize.x;
    float4 fractions = 1 / float4( sizeX, axisFrames, sizeY, UVscale );
    float2 sizeFraction = fractions.xy;
    //float axisSizeFraction = fractions.z;
    float fractionsUVscale = fractions.w;

    // Basic data
    float3 worldOrigin = 0;
    float4 perspective = float4( 0, 0, 0, 1 );
    // if there is no perspective we offset world origin with a 5000 view dir vector, otherwise we use the original world position
    if( UNITY_MATRIX_P[ 3 ][ 3 ] == 1 )
    {
        perspective = float4( 0, 0, 5000, 0 );
        worldOrigin = unity_ObjectToWorld._m03_m13_m23;
    }

    float3 worldCameraPos = worldOrigin + mul( UNITY_MATRIX_I_V, perspective ).xyz;

    float3 objectCameraPosition = mul( unity_WorldToObject, float4( worldCameraPos, 1 ) ).xyz - meshCenter; //ray origin
    float3 objectCameraDirection = normalize( objectCameraPosition );

    // Create orthogonal vectors to define the billboard
    float3 upVector = float3( 0,1,0 );
    float3 objectHorizontalVector = normalize( cross( objectCameraDirection, upVector ) );
    float3 objectVerticalVector = cross( objectHorizontalVector, objectCameraDirection );
    
    // Create vertical radial angle
    float verticalAngle = frac( atan2( -objectCameraDirection.z, -objectCameraDirection.x ) / (PI * 2) ) * sizeX + 0.5;

    // Create horizontal radial angle
    float verticalDot = dot( objectCameraDirection, upVector );
    //float upAngle = ( acos( -verticalDot ) /PI ) + axisSizeFraction * 0.5f;//纬度角的UV分段
    
    float yRot = sizeFraction.x * PI * verticalDot * ( 2 * frac( verticalAngle ) - 1 );
    
    //面片Mesh初始缩放偏移
    vertex.xy = vertex.xy * imposterScaleAndOffset.xy + imposterScaleAndOffset.zw;
    
    // Billboard rotation
    float2 uvExpansion = vertex.xy;
    float cosY = cos( yRot );
    float sinY = sin( yRot );
    float2 uvRotator = mul( uvExpansion, float2x2( cosY, -sinY, sinY, cosY ) );

    // Billboard
    float3 billboard = objectHorizontalVector * uvRotator.x + objectVerticalVector * uvRotator.y + meshCenter;
    
    //float2 relativeCoords = float2( floor( verticalAngle ), min( floor( upAngle * sizeY ), sizeY ) );
    int2 lookUpUV = int2(dynamicImposterId,meshType);
    int4 lookUpResult = round(_Imposter_LookUpTex[lookUpUV] * 255.0f);
    float2 tileIndex = lookUpResult.xy;
    frameUVs.xy = ((tileIndex + ( uvExpansion * fractionsUVscale + 0.5 ) ) * (_AlbedoAlpha_TileParam.y + _AlbedoAlpha_TileParam.x * 2))/_AlbedoAlpha_TileParam.zw;
    
    viewPos.w = 0;
    viewPos.xyz = TransformWorldToView( TransformObjectToWorld( billboard ) );
    
    vertex.xyz = billboard;
    normal.xyz = objectCameraDirection;
}


inline void SphereImpostorFragment(float2 frameUVs,float4 fitSize,float4 viewPos,inout SurfaceOutputStandardMetallic o,out float4 clipPos, out float3 worldPos)
{

    // albedo alpha
    float4 albedoSample = tex2D(_AlbedoAlphaVT,frameUVs);
    // early clip
    o.Alpha = albedoSample.a;
    #if !defined( AI_SKIP_ALPHA_CLIP )
    clip( o.Alpha - _ClipMask );
    #endif
    o.Albedo = albedoSample.rgb;

    // Specular Smoothness
    float4 specularSample = tex2D(_MetallicSmoothnessVT,frameUVs);
    o.Metallic = specularSample.r;
    o.Smoothness = specularSample.g;
    o.CustomData = specularSample.ba;

    // Emission Occlusion
    float4 emissionSample = tex2D(_EmissionOcclusionVT,frameUVs);
    o.Emission = emissionSample.rgb;
    o.Occlusion = emissionSample.a;

    // Normal
    float4 normalSample = tex2D(_NormalDepthVT,frameUVs);
    float4 remapNormal = normalSample * 2 - 1; // object normal is remapNormal.rgb
    float3 worldNormal = normalize( mul( (float3x3)unity_ObjectToWorld, remapNormal.xyz ) );
    o.Normal = worldNormal;
    
    // Depth
    float depthFitSize = fitSize.y;
    float depth = remapNormal.a * depthFitSize * 0.5 * length( unity_ObjectToWorld[ 2 ].xyz );
   
    #if !defined(AI_RENDERPIPELINE) // no SRP
    #if defined(SHADOWS_DEPTH)
    if( unity_LightShadowBias.y == 1.0 ) // get only the shadowcaster, this is a hack
        {
        viewPos.z += depth * _AI_ShadowView;
        viewPos.z += -_AI_ShadowBias;
        }
    else // else add offset normally
        {
        viewPos.z += depth;
        }
    #else // else add offset normally
    viewPos.z += depth;
    #endif
    #elif defined(AI_RENDERPIPELINE) // SRP
    #if ( defined(SHADERPASS) && ((defined(SHADERPASS_SHADOWS) && SHADERPASS == SHADERPASS_SHADOWS) || (defined(SHADERPASS_SHADOWCASTER) && SHADERPASS == SHADERPASS_SHADOWCASTER)) ) || defined(UNITY_PASS_SHADOWCASTER)
    viewPos.z += depth * _AI_ShadowView;
    viewPos.z += -_AI_ShadowBias;
    #else // else add offset normally
    viewPos.z += depth;
    #endif
    #endif

    worldPos = mul( UNITY_MATRIX_I_V, float4( viewPos.xyz, 1 ) ).xyz;
    clipPos = mul( UNITY_MATRIX_P, float4( viewPos.xyz, 1 ) );


    #if !defined(AI_RENDERPIPELINE) // no SRP
    #if defined(SHADOWS_DEPTH)
    clipPos = UnityApplyLinearShadowBias( clipPos );
    #endif
    #elif defined(AI_RENDERPIPELINE) // SRP
    #if defined(UNITY_PASS_SHADOWCASTER) && !defined(SHADERPASS)
    #if UNITY_REVERSED_Z
    clipPos.z = min( clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE );
    #else
    clipPos.z = max( clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE );
    #endif
    #endif
    #endif

    clipPos.xyz /= clipPos.w;

    if( UNITY_NEAR_CLIP_VALUE < 0 )
        clipPos = clipPos * 0.5 + 0.5;
    

}



#endif