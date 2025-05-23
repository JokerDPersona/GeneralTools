Shader "Hidden/SamplerNode"
{
	Properties
	{
		_B ("_UVs", 2D) = "white" {}
		_C ("_Level", 2D) = "white" {}
		_F ("_NormalScale", 2D) = "white" {}
		_G ("Index", 2D) = "white" {}
		_CustomUVs ("_CustomUVs", Int) = 0
		_Unpack ("_Unpack", Int) = 0
		_LodType ("_LodType", Int) = 0

		_Sampler ("_Sampler", 2D) = "white" {}
		_Sampler3D ("_Sampler3D", 3D) = "white" {}
		_Array ("_Array", 2DArray) = "white" {}
		_Cube( "_Cube", CUBE) = "white" {}
		_Default ("_Default", Int) = 0
		_Type ("_Type", Int) = 0
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma target 3.5
			#include "UnityCG.cginc"
			#include "Preview.cginc"
			#include "UnityStandardUtils.cginc"

			sampler2D _F;
			int _CustomUVs;
			int _Unpack;
			int _Default;

			float4 frag( v2f_img i ) : SV_Target
			{
				const float3 white = float3( 1, 1, 1 );
				const float3 black = float3( 0, 0, 0 );
				const float3 grey = GammaToLinearSpace( 127.0 / 255.0 ).xxx;
				const float3 bump = float3( 0.5, 0.5, 1 );
				const float3 linearGrey = ( 127.0 / 255.0 ).xxx;
				const float3 red = float3( 1, 0, 0 );

				float4 result = float4( 0, 0, 0, 1 );
				switch ( _Default )
				{
					case 1: result.rgb = white; break;
					case 2: result.rgb = black; break;
					case 3: result.rgb = grey; break;
					case 4: result.rgb = ( _Unpack == 1 ) ? UnpackScaleNormal( bump.xxyy, tex2D( _F, i.uv ).r ) : bump; break;
					case 5: result.rgb = linearGrey; break;
					case 6: result.rgb = red; break;
				}
				return result;
			}
			ENDCG
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma target 3.5
			#include "UnityCG.cginc"
			#include "Preview.cginc"
			#include "UnityStandardUtils.cginc"

			sampler2D _B;
			sampler2D _C;
			sampler2D _F;
			sampler2D _G;
			int _CustomUVs;
			int _Unpack;
			int _LodType;

			UNITY_DECLARE_TEX2DARRAY (_Array);
			samplerCUBE _Cube;
			sampler2D _Sampler;
			sampler3D _Sampler3D;
			int _Type;

			float4 frag (v2f_img i) : SV_Target
			{
				if (_Type == 4)
				{
					return UNITY_SAMPLE_TEX2DARRAY ( _Array, float3(i.uv, tex2D( _G, i.uv ).r ) );
				}
				else if (_Type == 3)
				{
					float3 uvs = float3(i.uv,0);

					if (_CustomUVs == 1)
						uvs = tex2D (_B, i.uv).xyz;

					return texCUBE (_Cube, uvs);
				}
				else if (_Type == 2)
				{
					return tex3D (_Sampler3D, float3(i.uv,0));
				}
				else
				{
					float2 uvs = i.uv;
					float4 c = 0;

					if (_CustomUVs == 1)
						uvs = tex2D (_B, i.uv).xy;

					if (_LodType == 1)
					{
						float lod = tex2D (_C, i.uv).r;
						c = tex2Dlod (_Sampler, float4(uvs,0,lod));
					}
					else if (_LodType == 2)
					{
						float bias = tex2D (_C, i.uv).r;
						c = tex2Dbias (_Sampler, float4(uvs,0,bias));
					}
					else
					{
						c = tex2D (_Sampler, uvs);
					}

					if (_Unpack == 1) 
					{
						float nscale = tex2D (_F, i.uv).r;
						c.rgb = UnpackScaleNormal (c, nscale);
					}

					return c;
				}
			}
			ENDCG
		}
	}
}
