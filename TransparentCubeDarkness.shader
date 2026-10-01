Shader "CustomRenderTexture/TransparentCubeDarkness"
{
    Properties
    {
        _BackDarkness    ("Back Wall Darkness",   Range(0,1)) = 1.0
        _SideFalloff     ("Side Gradient Power",  Range(0.1,5)) = 1.5
        _SideMaxAlpha    ("Side Max Darkness",    Range(0,1)) = 0.85
        _EdgeOffset      ("Edge Transparent Zone",Range(0,0.9)) = 0.1
    }

    SubShader
    {
        Tags
        {
            "Queue"           = "Transparent"
            "RenderType"      = "Transparent"
            "IgnoreProjector" = "True"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Front

            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _BackDarkness;
            float _SideFalloff;
            float _SideMaxAlpha;
            float _EdgeOffset;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos      : SV_POSITION;
                float3 localPos : TEXCOORD0;
                float3 localNrm : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos      = UnityObjectToClipPos(v.vertex);
                o.localPos = v.vertex.xyz;
                o.localNrm = v.normal;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 n = normalize(i.localNrm);
                float absX = abs(n.x);
                float absY = abs(n.y);
                float absZ = abs(n.z);
                float maxC = max(absX, max(absY, absZ));

                float alpha = 0.0;

                if (maxC == absZ && n.z < 0.0)
                {
                    alpha = _BackDarkness;
                }
                else
                {
                    float2 uv;
                    if (maxC == absX)
                        uv = float2(i.localPos.y, i.localPos.z);
                    else if (maxC == absY)
                        uv = float2(i.localPos.x, i.localPos.z);
                    else
                        uv = float2(i.localPos.x, i.localPos.y);

                    uv = uv + 0.5;

                    float2 d = abs(uv - 0.5) * 2.0;
                    float edgeDist = max(d.x, d.y);

                    float depth = saturate((-i.localPos.z + 0.5));

                    float t = saturate((depth - _EdgeOffset) / (1.0 - _EdgeOffset + 0.001));
                    alpha = pow(t, _SideFalloff) * _SideMaxAlpha;
                }

                return fixed4(0.0, 0.0, 0.0, saturate(alpha));
            }
            ENDCG
        }
    }

    FallBack "Transparent/Diffuse"
}
