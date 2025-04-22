Shader "Hidden/BlitTexToTexArray"
{

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        CGINCLUDE
        #include "UnityCG.cginc"
        
         struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

        
       SamplerState LODData_point_clamp_sampler;
       SamplerState LODData_linear_clamp_sampler;
     
        Texture2D _MainTex;

        v2f vert (appdata v)
        {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
          
                o.uv = float2(v.uv.x,1.0f - v.uv.y);
                return o;
        }

        float4 pointSampleFrag (v2f In) : SV_Target
         {
                // sample the texture
                float4 col =_MainTex.SampleLevel(LODData_point_clamp_sampler,In.uv,0); 
                return col;
         }

       float4 linearSampleFrag (v2f In) : SV_Target
         {
                // sample the texture
                float4 col =_MainTex.SampleLevel(LODData_point_clamp_sampler,In.uv,0); 
                return col;
         }

        

        ENDCG

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment pointSampleFrag
            //#pragma enable_d3d11_debug_symbols
            ENDCG
        }
       
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment linearSampleFrag
            //#pragma enable_d3d11_debug_symbols
            ENDCG
        }
    }
}
