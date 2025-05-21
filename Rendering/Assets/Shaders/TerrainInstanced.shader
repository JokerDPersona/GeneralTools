Shader "Custom/TerrainInstanced"
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
            "Queue" = "Geometry"
        }

        Pass
        {
            ZWrite On
            ZTest LEqual
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"
            #include "FrustumCulling.compute"

            StructuredBuffer<NodeData> _NodesBuffer;
            StructuredBuffer<int> _VisibleIndicesBuffer;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint instanceID : SV_InstanceID;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;

                // 获取实际节点索引
                int realIndex = _VisibleIndicesBuffer[v.instanceID];
                float3 center = _NodesBuffer[realIndex].center;
                float3 size = _NodesBuffer[realIndex].size;

                // 构建实例矩阵
                float4x4 instanceMatrix = {
                    size.x, 0, 0, center.x,
                    0, size.y, 0, center.y,
                    0, 0, size.z, center.z,
                    0, 0, 0, 1
                };

                // 变换顶点
                float4 worldPos = mul(instanceMatrix, v.vertex);
                o.pos = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            fixed4 frag(v2f i) : SV_Target
            {
                //return float4(1,0,0,1); // 显示红色
                //return float4(i.uv.x, i.uv.y, 0, 1); // 测试uv
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}