Shader "Fur/Fur Base" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" { }
        _LightDirection ("LightDirection", vector) = (0.3, 0.1, -0.1, 0)
        _Alpah ("Alpha", Range(0, 1)) = 1

        [Header(Diffuse)]
        _FrontLightColor ("Front Light Color", Color) = (1, 1, 1, 1)
        _BackLightColor ("Back Light Color", Color) = (1, 1, 1, 1)
        _DiffuseFrontIntensity ("Diffuse Front Intensity", float) = 0.7
        _DiffuseBackIntensity ("Diffuse Back Intensity", float) = 0.3

        [Header(Specular)]
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularIntensity ("SpecularIntensity", Range(1, 10)) = 5
        _Gloss ("Gloss", Range(0, 2)) = 0.5

        [Header(Other Setting)]
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlend ("SrcBlend   [One  SrcAlpha]", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstBlend ("DstBlend   [Zero  OneMinusSrcAlpha]", float) = 0
        [Enum(On, 1, Off, 0)]_ZWrite ("ZWrite        [On  Off]", float) = 1
    }

    SubShader {
        Tags { "RenderPipeline" = "UniversalPipeline" }

        Pass {
            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };
            
            sampler2D _MainTex;
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float3 _LightDirection;
            half _Alpah;

            half4 _FrontLightColor;
            half4 _BackLightColor;
            half _DiffuseFrontIntensity;
            half _DiffuseBackIntensity;

            half4 _SpecularColor;
            half _SpecularIntensity;
            half _Gloss;
            CBUFFER_END

            Varyings vert(Attributes IN) {

                Varyings OUT;
                
                OUT.vertex = TransformObjectToHClip(IN.vertex.xyz);
                OUT.worldPos = TransformObjectToWorld(IN.vertex.xyz);
                OUT.worldNormal = TransformObjectToWorldNormal(IN.normal);

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {

                half3 albedo = tex2D(_MainTex, IN.uv).rgb;

                float3 worldNormal = normalize(IN.worldNormal);
                float3 worldLightDir = normalize(_LightDirection);
                
                half halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
                half3 diffuse = _FrontLightColor.rgb * albedo * halfLambert * _DiffuseFrontIntensity;
                
                half oneMinusHalfLambert = 1 - halfLambert;
                diffuse += _BackLightColor.rgb * albedo * oneMinusHalfLambert * _DiffuseBackIntensity;

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.worldPos.xyz);
                float3 halfDir = normalize(worldLightDir + viewDir);
                half3 specular = _SpecularColor.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss * 256) * _SpecularIntensity;

                return half4(diffuse + specular, _Alpah);
            }
            ENDHLSL
        }
    }
}