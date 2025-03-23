Shader "Custom/CausticShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CausticSpeed ("Caustic Speed", Range(0, 1)) = 0.131
        _WorldPosXY_Speed1X ("World Pos XY Speed 1X", Range(-1, 1)) = -0.02
        _WorldPosXY_Speed1Y ("World Pos XY Speed 1Y", Range(-1, 1)) = -0.01
        _CausticScale ("Caustic Scale", Range(0, 1)) = 0.25
        _CausticNormalDisturbance ("Caustic Normal Disturbance", Range(0, 1)) = 0.096

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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 world : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float hash33(float3 p3)
            {
                p3 = frac(p3 * 0.8);
                p3 += dot(p3, p3.yzx + 19.19);
                return -1.0 + 2.0 * frac((p3.x + p3.y) * p3.z);
            }

            float3 GetWorldSpaceViewDir(float3 worldPos)
            {
                return worldPos - _WorldSpaceCameraPos;
            }

            float perlin_noise(float3 p)
            {
                float3 pi = floor(p);
                float3 pf = p - pi;

                float3 w = pf * pf * (3.0 - 2.0 * pf);

                return lerp(
                    lerp(
                        lerp(dot(pf - float3(0, 0, 0), hash33(pi + float3(0, 0, 0))),
                             dot(pf - float3(1, 0, 0),
                                 hash33(pi + float3(1, 0, 0))),
                             w.x),
                        lerp(dot(pf - float3(0, 0, 1), hash33(pi + float3(0, 0, 1))),
                             dot(pf - float3(1, 0, 1),
                                 hash33(pi + float3(1, 0, 1))),
                             w.x),
                        w.z),
                    lerp(
                        lerp(dot(pf - float3(0, 1, 0), hash33(pi + float3(0, 1, 0))),
                             dot(pf - float3(1, 1, 0), hash33(pi + float3(1, 1, 0))),
                             w.x),
                        lerp(dot(pf - float3(0, 1, 1), hash33(pi + float3(0, 1, 1))),
                             dot(pf - float3(1, 1, 1),
                                 hash33(pi + float3(1, 1, 1))),
                             w.x),
                        w.z),
                    w.y);
            }

            const float _CausticSpeed = 0.131; // _151._m29
            const float _WorldPosXY_Speed1X = -0.02; // _151._m44
            const float _WorldPosXY_Speed1Y = -0.01; // _151._m45
            const float _CausticScale = 0.25; // _151._m28
            const float _CausticNormalDisturbance = 0.096; // _151._m33

            float GenshipCaustic(float3 _lookThroughAtTerrainWorldPos)
            {
                float3 _causticPos3DInput;
                _causticPos3DInput.xy = (_Time.y * _CausticSpeed * float2(_WorldPosXY_Speed1X, _WorldPosXY_Speed1Y) *
                        25.0)
                    + _lookThroughAtTerrainWorldPos.xz * _CausticScale;
                // _causticPos3DInput.xy += _terrainToSurfLength * _CausticNormalDisturbance * _surfNormal.xz; // shadertoy 这里没有水面法线信息，屏蔽这个
                _causticPos3DInput.z = _Time.y * _CausticSpeed;

                float3 _step1;
                _step1.x = dot(_causticPos3DInput, float3(-2.0, 3.0, 1.0));
                _step1.y = dot(_causticPos3DInput, float3(-1.0, -2.0, 2.0));
                _step1.z = dot(_causticPos3DInput, float3(2.0, 1.0, 2.0));

                float3 _step2;
                _step2.x = dot(_step1, float3(-0.8, 1.2, 0.4));
                _step2.y = dot(_step1, float3(-0.4, -0.8, 0.8));
                _step2.z = dot(_step1, float3(0.8, 0.4, 0.8));

                float3 _step3;
                _step3.x = dot(_step2, float3(-0.6, 0.9, 0.3));
                _step3.y = dot(_step2, float3(-0.3, -0.6, 0.6));
                _step3.z = dot(_step2, float3(0.6, 0.3, 0.6));


                float3 _hnf1 = 0.5 - frac(_step1);
                float3 _hnf2 = 0.5 - frac(_step2);
                float3 _hnf3 = 0.5 - frac(_step3);

                float _min_dot_result = min(dot(_hnf3, _hnf3), min(dot(_hnf2, _hnf2), dot(_hnf1, _hnf1)));

                float _local_127 = (_min_dot_result * _min_dot_result * 7.0f);
                float _causticNoise3DResult = _local_127 * _local_127;

                return _causticNoise3DResult;
            }

            float caustics(float3 p)
            {
                return GenshipCaustic(p);
            }


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.world = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

         

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // 获取当前片元的深度值


                float noise = caustics(_WorldSpaceCameraPos + GetWorldSpaceViewDir(i.world));
                // Use your Perlin noise function here
                col.rgb *= noise;
                return col;
            }
            ENDCG
        }
    }
}