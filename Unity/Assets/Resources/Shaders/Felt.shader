// The tilted oval card table, drawn analytically per pixel so it is crisp at any resolution.
//
// Mirrors the Flutter felt: a wooden-rimmed oval put through rotateX(-50deg) with perspective 1/760,
// anchored at its top-centre, so it widens toward the player and tapers into an arc at the top.
// Each fragment is mapped back into the flat oval plane and shaded there: drop shadow, rim gradient,
// radial felt, a top inner shadow and a faint gold keyline.
Shader "Blackjack/Felt"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Canvas ("Canvas size (units)", Vector) = (384, 600, 0, 0)
        _Oval ("Oval width, height, top", Vector) = (500, 540, 56, 0)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex : POSITION;
                float4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 texcoord : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            fixed4 _Color;
            float4 _ClipRect;
            float4 _Canvas;
            float4 _Oval;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                OUT.worldPosition = v.vertex;
                OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
                OUT.texcoord = v.texcoord;
                OUT.color = v.color * _Color;
                return OUT;
            }

            // Approximate signed distance to an axis-aligned ellipse (negative inside), good to ~1 unit.
            float EllipseSd(float2 p, float2 r)
            {
                float k = sqrt((p.x * p.x) / (r.x * r.x) + (p.y * p.y) / (r.y * r.y));
                if (k < 1e-5) return -min(r.x, r.y);
                float2 grad = p / (r * r);
                return (k * k - k) / max(length(grad), 1e-5);
            }

            float3 FeltRamp(float t)
            {
                const float3 c0 = float3(0.1647, 0.5608, 0.4392);   // #2A8F70
                const float3 c1 = float3(0.0863, 0.3843, 0.2824);   // #166248
                const float3 c2 = float3(0.0431, 0.2078, 0.1529);   // #0B3527
                const float3 c3 = float3(0.0314, 0.1647, 0.1255);   // #082A20
                if (t < 0.42) return lerp(c0, c1, t / 0.42);
                if (t < 0.78) return lerp(c1, c2, (t - 0.42) / 0.36);
                return lerp(c2, c3, (t - 0.78) / 0.22);
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                // Canvas position in units, y growing downward, then relative to the oval's top-centre.
                float2 cpos = float2(IN.texcoord.x * _Canvas.x, (1.0 - IN.texcoord.y) * _Canvas.y);
                float sx = cpos.x - _Canvas.x * 0.5;
                float sy = max(cpos.y - _Oval.z, -200.0);

                const float tilt = 0.8726646;          // 50 degrees
                const float persp = 1.0 / 760.0;
                float cs = cos(tilt);
                float sn = sin(tilt);

                // Invert: sy = cs*y / (1 - sn*persp*y);  sx = x / (1 - sn*persp*y).
                float y = sy / (cs + sn * persp * sy);
                float w = 1.0 - sn * persp * y;
                float x = sx * w;
                float2 p = float2(x, y - _Oval.y * 0.5);   // centred oval-plane coordinates

                float ow = _Oval.x;
                float oh = _Oval.y;
                const float inset = 20.0;
                float2 outerR = float2(ow * 0.5, oh * 0.5);
                float2 innerR = float2(ow * 0.5 - inset, oh * 0.5 - inset);

                // Drop shadow: the oval shifted down 30 and blurred.
                float shadowD = EllipseSd(p - float2(0, 30), outerR);
                float shadowA = 0.62 * exp(-pow(max(shadowD, 0.0) / 38.0, 2.0));
                float4 col = float4(0, 0, 0, shadowA);

                float rimSd = EllipseSd(p, outerR);
                float rimCover = saturate(0.5 - rimSd / max(fwidth(rimSd), 1e-4));
                if (rimCover > 0.0)
                {
                    float t = saturate(y / oh);
                    const float3 rimTop = float3(0.4784, 0.2902, 0.1725);   // #7A4A2C
                    const float3 rimMid = float3(0.2902, 0.1647, 0.0941);   // #4A2A18
                    const float3 rimLow = float3(0.1647, 0.0902, 0.0549);   // #2A170E
                    float3 rim = t < 0.4 ? lerp(rimTop, rimMid, t / 0.4) : lerp(rimMid, rimLow, (t - 0.4) / 0.6);
                    col.rgb = lerp(col.rgb, rim, rimCover);
                    col.a = rimCover + col.a * (1.0 - rimCover);
                }

                float feltSd = EllipseSd(p, innerR);
                float feltCover = saturate(0.5 - feltSd / max(fwidth(feltSd), 1e-4));
                if (feltCover > 0.0)
                {
                    float shortest = min(innerR.x, innerR.y) * 2.0;
                    float2 centre = float2(0.0, -0.48 * innerR.y);
                    float dist = length(p - centre) / (0.9 * shortest);
                    float3 felt = FeltRamp(saturate(dist));
                    // Top inner shadow: black 40% fading out over the top third of the felt.
                    float ty = saturate((p.y + innerR.y) / (innerR.y * 2.0) / 0.34);
                    felt = lerp(felt, float3(0, 0, 0), lerp(0.4, 0.0, ty));
                    // Gold keyline just inside the felt edge.
                    float keyline = saturate(1.0 - abs(feltSd + 1.0)) * 0.16;
                    felt = lerp(felt, float3(0.8627, 0.7490, 0.4784), keyline);
                    col.rgb = lerp(col.rgb, felt, feltCover);
                    col.a = max(col.a, feltCover);
                }

                fixed4 color = fixed4(col) * IN.color;

                #ifdef UNITY_UI_CLIP_RECT
                color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                #endif
                #ifdef UNITY_UI_ALPHACLIP
                clip(color.a - 0.001);
                #endif
                return color;
            }
            ENDCG
        }
    }
}
