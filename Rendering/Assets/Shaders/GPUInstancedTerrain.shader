Shader "Custom/GPUInstancedTerrain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "FrustumCulling.compute"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint instanceID:SV_InstanceID;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            StructuredBuffer<float4x4> _InstanceData;
            sampler2D _MainTex;

            float4 CalculateWorldPosition(appdata v)
            {
                float4x4 martix = _InstanceData[v.instanceID];
                return mul(martix, v.vertex);
            }

            StructuredBuffer<NodeData> _NodeBuffer;
            StructuredBuffer<uint> _VisibleBuffer;

            void ApplyLODTransition(int lodLevel, float4 worldPos)
            {
                
            }

            v2f vert(appdata v, uint instanceID:SV_InstanceID)
            {
                // 通过可见缓冲区获得实际索引
                uint realIndex = _VisibleBuffer[instanceID];
                NodeData node = _NodeBuffer[realIndex];
                // 构建实例矩阵
                float4x4 martix = {
                    node.size.x, 0, 0, node.center.x,
                    0, node.size.y, 0, node.center.y,
                    0, 0, node.size.z, node.center.z,
                    0, 0, 0, 1
                };
                // 变换顶点
                float4 worldPos = mul(martix, v.vertex);
                v2f o;
                o.pos = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = v.uv;
                // LOD混合计算
                ApplyLODTransition(node.lodLevel, worldPos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}