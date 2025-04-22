Shader "GpuDriven/SphericlImposterURP"
{
    Properties
    {
        _ClipMask("Clip", Range( 0 , 1)) = 0.5

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"
        }

        Cull Back
        AlphaToMask[_AI_AlphaToCoverage]

        HLSLINCLUDE
        #pragma target 3.0
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        ENDHLSL

        Pass
        {
            Name "Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend One Zero
            ZWrite On
            ZTest LEqual
            Offset 0,0
            ColorMask RGBA

            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            #pragma multi_compile _ SHADOWS_SHADOWMASK

            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma enable_d3d11_debug_symbols

            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #define AI_RENDERPIPELINE

            #pragma instancing_options procedural:DrawImposterSetUp

            #include "../ExampleIndirectInclude/DrawImposterIndirect.hlsl"
            #include "../DrawImposter/DynamicImposterInput.hlsl"


            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                float3 vertexSH : TEXCOORD0;
                half4 fogFactorAndVertexLight : TEXCOORD1;
                float2 frameUVs : TEXCOORD2;
                float4 viewPos : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                SphereImpostorVertex(_AxisFrames, _ImposterMeshFitSize, _ImposterMeshScaleAndOffset, _MeshType,
                                               _MeshCenter, _DynamicImposterId
                                               , v.vertex, v.normal, o.frameUVs, o.viewPos);

                float3 normalWS = TransformObjectToWorldNormal(v.normal);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

                OUTPUT_SH(normalWS, o.vertexSH);

                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                o.clipPos = vertexInput.positionCS;
                return o;
            }

            half4 frag(VertexOutput IN, out float outDepth : SV_Depth) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                SurfaceOutputStandardMetallic o = (SurfaceOutputStandardMetallic)0;
                float4 clipPos = 0;
                float3 worldPos = 0;

                SphereImpostorFragment(IN.frameUVs, _ImposterMeshFitSize, IN.viewPos, o, clipPos, worldPos);
                IN.clipPos.zw = clipPos.zw;


                InputData inputData;
                inputData.positionWS = worldPos;
                inputData.normalWS = o.Normal;
                inputData.viewDirectionWS = SafeNormalize(_WorldSpaceCameraPos.xyz - worldPos);
                inputData.fogCoord = IN.fogFactorAndVertexLight.x;
                inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SampleSHPixel(IN.vertexSH, inputData.normalWS);
                inputData.shadowMask = 1; // not supported
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
                #if defined(_MAIN_LIGHT_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif

                half4 color = UniversalFragmentPBR(
                    inputData,
                    o.Albedo,
                    o.Metallic,
                    0.5,
                    o.Smoothness,
                    o.Occlusion,
                    o.Emission,
                    o.Alpha);

                color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
                outDepth = clipPos.z;
                return color;
            }
            ENDHLSL
        }

        Pass
        {

            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature_local_fragment _ALPHATEST_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN


            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #pragma instancing_options procedural:DrawImposterSetUp

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"

            #include "../ExampleIndirectInclude/DrawImposterIndirect.hlsl"
            #include "../DrawImposter/DynamicImposterInput.hlsl"

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 clipPos : SV_POSITION;
                float3 vertexSH : TEXCOORD0;
                half4 fogFactorAndVertexLight : TEXCOORD1;
                float2 frameUVs : TEXCOORD2;
                float4 viewPos : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                SphereImpostorVertex(_AxisFrames, _ImposterMeshFitSize, _ImposterMeshScaleAndOffset, _MeshCenter,
                                                                        _MeshType, _DynamicImposterId
                                                                        , v.vertex, v.normal, o.frameUVs, o.viewPos);

                float3 normalWS = TransformObjectToWorldNormal(v.normal);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

                OUTPUT_SH(normalWS, o.vertexSH);

                half3 vertexLight = VertexLighting(vertexInput.positionWS, normalWS);
                half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                o.clipPos = vertexInput.positionCS;
                return o;
            }

            FragmentOutput frag(VertexOutput IN
                                              , out float outDepth : SV_Depth
            )
            {
                SurfaceOutputStandardMetallic o = (SurfaceOutputStandardMetallic)0;
                float4 clipPos = 0;
                float3 worldPos = 0;

                SphereImpostorFragment(IN.frameUVs, _ImposterMeshFitSize, IN.viewPos, o, clipPos, worldPos);
                IN.clipPos.zw = clipPos.zw;

                InputData inputData;
                inputData.positionWS = worldPos;
                inputData.normalWS = o.Normal;
                inputData.viewDirectionWS = SafeNormalize(_WorldSpaceCameraPos.xyz - worldPos);
                inputData.fogCoord = IN.fogFactorAndVertexLight.x;
                inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
                inputData.bakedGI = SampleSHPixel(IN.vertexSH, inputData.normalWS);
                inputData.shadowMask = 1; // not supported
                inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
                #if defined(_MAIN_LIGHT_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                #else
                inputData.shadowCoord = float4(0, 0, 0, 0);
                #endif


                BRDFData brdfData;
                InitializeBRDFData(o.Albedo, o.Metallic, 0.5f, o.Smoothness, o.Alpha, brdfData);
                half4 color;
                color.rgb = GlobalIllumination(brdfData, SampleSHPixel(IN.vertexSH, o.Normal), o.Occlusion, o.Normal,
                                               IN.viewPos);
                color.a = o.Alpha;


                outDepth = clipPos.z;


                return BRDFDataToGbuffer(brdfData, inputData, o.Smoothness, o.Emission + color.rgb);
            }
            ENDHLSL
        }

    }
}