
Shader "Custom/Leaf Shader"
{
	Properties
	{
		_Color("Color", Color) = (1, 1, 1, 1)

		_CutoutTexture("Cutout Texture", 2D) = "white" {}
		_AlphaCutout("Alpha Cutout", Range(0, 1)) = 0

		_ShadingLUT("Shading LUT", 2D) = "white" {}

		_AmbientOcclusionPow("Ambient Occlusion Power", Range(0, 5)) = 1
		_AmbientOcclusionScale("Ambient Occlusion Scale", Range(0, 2)) = .5

		_SubSurfColor("SubSurface Color", Color) = (1, 1, 1, 1)
		_SubSurfDistortionMult("SubSurface Distortion Multiplier", Range(0, 2)) = 1
		_SubSurfPow("SubSurface Pow", Range(0, 5)) = 1
		_SubSurfScale("SubSurface Scale", Range(0, 2)) = 1
	}
	
	SubShader
	{
		
		LOD 100
		Cull Off
		
		Pass
		{
			Name "BASE_LIGHTING"
			Tags 
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 color : COLOR;
			};
			
			fixed4 _Color;

			sampler2D _CutoutTexture;
			fixed _AlphaCutout;
			fixed _ndotvCutout;

			sampler2D _ShadingLUT;

			float _AmbientOcclusionPow;
			fixed _AmbientOcclusionScale;

			fixed4 _SubSurfColor;
			float _SubSurfDistortionMult;
			float _SubSurfPow;
			float _SubSurfScale;

			fixed4 softLight(fixed4 a, fixed4 b)
			{
				return (1 - 2 * b) * a * a + 2 * b * a;
			}

			v2f vert (appdata v)
			{
				v2f o;
				
				o.color = v.color;
				o.pos = UnityObjectToClipPos(v.vertex);
				v.normal = UnityObjectToWorldNormal(v.normal);
				o.uv = v.uv;

				fixed3 viewDir = normalize(WorldSpaceViewDir(v.vertex));
				//ndotv
				fixed ndotv = saturate(dot(viewDir, -(_WorldSpaceLightPos0.xyz + v.normal * _SubSurfDistortionMult)));
				ndotv = dot(pow(ndotv, _SubSurfPow), _SubSurfScale);
				
				//ndotl
				fixed ndotl = dot(v.normal, _WorldSpaceLightPos0.xyz);

				fixed4 baseColor = _Color * tex2Dlod(_ShadingLUT, ndotl);
				fixed4 AOColor = tex2Dlod(_ShadingLUT, pow(v.color.r, _AmbientOcclusionPow) * _AmbientOcclusionScale);
				fixed4 subSurfColor = ndotv * _SubSurfColor;

				o.color = (softLight(baseColor, AOColor) + subSurfColor);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{	
				fixed4 col = tex2D(_CutoutTexture, i.uv);
				clip(col.a - _AlphaCutout);

				return i.color * col;
			}
			ENDCG
		}

	}
	Fallback "Unlit/Color"
}
