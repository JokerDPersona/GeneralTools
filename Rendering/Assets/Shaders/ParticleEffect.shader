Shader "Unlit/ParticleEffect"
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
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct particleData
            {
                float3 pos;
                float4 color;
            };

            StructuredBuffer<particleData> particleBuffer;

            struct v2f
            {
                float4 col : COLOR;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(uint id:SV_VertexID)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(float4(particleBuffer[id].pos, 0));
                o.col = particleBuffer[id].color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return i.col;
            }
            ENDCG
        }
    }
}