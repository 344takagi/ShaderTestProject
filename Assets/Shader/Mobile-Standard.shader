Shader "Custom/Mobile-Standard"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)					// これいるの？.
		_MainTex ("Texture", 2D) = "white" {}
		
		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5	// これいるの？.
		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		
		// Blending state
		[HideInInspector] _Mode ("__mode", Float) = 0.0		// これいるの？.
		[HideInInspector] _SrcBlend ("__src", Float) = 1.0
		[HideInInspector] _DstBlend ("__dst", Float) = 0.0
		[HideInInspector] _ZWrite ("__zw", Float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }

		Pass
		{
			Blend [_SrcBlend] [_DstBlend]
			ZWrite [_ZWrite]
			
			CGPROGRAM
			
			#pragma shader_feature _ _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D	_MainTex;
			float4		_MainTex_ST;
			half4		_Color;
			half		_Metallic;
			half		_Glossiness;
			
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			half4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 texColor = _Color * tex2D(_MainTex, i.uv);
				
				//half3 specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, texColor.rgb, _Metallic);
				half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
				half oneMinusReflectivity = oneMinusDielectricSpec - _Metallic * oneMinusDielectricSpec;
				half3 diffColor = texColor.rgb * oneMinusReflectivity;
				
				half modifiedAlpha = 0.0;
#if defined(_ALPHAPREMULTIPLY_ON)
				// NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
				
				// Transparency 'removes' from Diffuse component
				diffColor = diffColor * texColor.a;
				// Reflectivity 'removes' from the rest of components, including Transparency
				modifiedAlpha = 1 - oneMinusReflectivity + texColor.a * oneMinusReflectivity;
				
#elif defined(_ALPHABLEND_ON)
				modifiedAlpha = texColor.a;
				
#else
				UNITY_OPAQUE_ALPHA(modifiedAlpha);
#endif
				
				UNITY_APPLY_FOG(i.fogCoord, diffColor);
				return half4(diffColor, modifiedAlpha);
			}
			ENDCG
		}
	}
	
	CustomEditor "MobileStandardGUI"
}
