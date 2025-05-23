Shader "Hidden/IsInfinite"
{
	Properties
	{
		_A ("_A", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Preview.cginc"
			#pragma vertex vert_img
			#pragma fragment frag

			sampler2D_float _A;

			float4 frag(v2f_img i) : SV_Target
			{
				return isinf( tex2D(_A, i.uv) ) ? 1 : 0;
			}
			ENDCG
		}
	}
}
