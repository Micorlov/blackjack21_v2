// The Seat: the table seen from a player's chair, drawn analytically per pixel so it is crisp at any size.
//
// Top to bottom on the felt canvas (units, y down): the wooden edge on the dealer's side, the green felt with
// its dashed arc of betting spots, the padded leather rail (a parabola across the canvas, with a highlight,
// a stitched seam and a dark lower lip), and the dark room below it. No loops, no noise: every layer is a
// closed-form distance, so it stays cheap on a phone GPU.
Shader "Blackjack/Felt"
{
    Properties
    {
        [PerRendererData] _MainTex ("Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Canvas ("Canvas size (units)", Vector) = (384, 600, 0, 0)
        _Rail ("Rail side y, rail middle y, overhang, wood height", Vector) = (360, 520, 40, 10)

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
            float4 _Rail;

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

            // A parabola across the canvas through (-over, side), (w/2, mid), (w+over, side): the curve of the rail.
            // Returns the signed distance to it, positive below, measured across the curve rather than straight down.
            float CurveDistance(float2 p, float side, float mid)
            {
                float over = _Rail.z;
                float span = _Canvas.x + 2.0 * over;
                float u = (p.x + over) / span;
                float y = side + 4.0 * (mid - side) * u * (1.0 - u);
                float slope = 4.0 * (mid - side) * (1.0 - 2.0 * u) / span;
                return (p.y - y) / sqrt(1.0 + slope * slope);
            }

            // Coverage of a line of the given width centred on distance 0, antialiased to a pixel.
            float Line(float d, float width)
            {
                float aa = max(fwidth(d), 1e-4);
                return saturate((width * 0.5 - abs(d)) / aa + 0.5);
            }

            float3 Ramp3(float t, float3 a, float3 b, float3 c, float split)
            {
                return t < split ? lerp(a, b, t / split) : lerp(b, c, (t - split) / (1.0 - split));
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                float2 p = float2(IN.texcoord.x * _Canvas.x, (1.0 - IN.texcoord.y) * _Canvas.y);
                float side = _Rail.x;
                float mid = _Rail.y;
                float wood = _Rail.w;

                const float3 roomTop = float3(0.1098, 0.0588, 0.0275);   // #1C0F07
                const float3 roomDeep = float3(0.0549, 0.0314, 0.0196);  // #0E0805
                float3 col = lerp(roomTop, roomDeep, saturate(p.y / (_Canvas.y * 0.3)));

                // Felt: the radial ramp of the design, brightest a little below the middle.
                float railD = CurveDistance(p, side, mid);
                float feltCover = saturate((p.y - wood) / max(fwidth(p.y), 1e-4)) * saturate(-railD / max(fwidth(railD), 1e-4) + 0.5);
                if (feltCover > 0.0)
                {
                    float2 centre = float2(_Canvas.x * 0.5, wood + (mid - wood) * 0.62);
                    float2 radius = float2(_Canvas.x * 0.8, (mid - wood) * 0.7);
                    float t = saturate(length((p - centre) / radius));
                    float3 felt = Ramp3(t, float3(0.0902, 0.3490, 0.2627), float3(0.0784, 0.3137, 0.2235), float3(0.0392, 0.1882, 0.1333), 0.6);
                    // A shadow cast by the wooden edge onto the top of the felt.
                    felt *= lerp(0.55, 1.0, saturate((p.y - wood) / 26.0));

                    // The dashed arc the bets sit on: 2 on, 5 off, faint gold.
                    float arcD = CurveDistance(p, side - 80.0, mid - 57.0);
                    float dash = step(frac(p.x / 7.0), 2.0 / 7.0);
                    felt = lerp(felt, float3(0.902, 0.780, 0.478), Line(arcD, 1.0) * dash * 0.18);
                    col = lerp(col, felt, feltCover);
                }

                // The wooden edge on the dealer's side.
                if (p.y < wood + 2.0)
                {
                    float t = saturate(p.y / max(wood, 1.0));
                    float3 woodCol = lerp(float3(0.5412, 0.3333, 0.1882), float3(0.2902, 0.1569, 0.0706), t);   // #8A5530 -> #4A2812
                    float cover = saturate((wood - p.y) / max(fwidth(p.y), 1e-4) + 0.5);
                    col = lerp(col, woodCol, cover);
                    col = lerp(col, float3(0.07, 0.03, 0.01), Line(p.y - wood, 1.5) * 0.8);
                }

                // The padded leather rail: 56 units across, lit from above, with its seam and lip.
                const float railHalf = 28.0;
                float railCover = Line(railD, railHalf * 2.0);
                if (railCover > 0.0)
                {
                    float t = saturate((railD + railHalf) / (railHalf * 2.0));
                    float3 leather = Ramp3(t, float3(0.4157, 0.1961, 0.1020), float3(0.2784, 0.1255, 0.0588), float3(0.1176, 0.0392, 0.0118), 0.35);
                    leather = lerp(leather, float3(1.0, 0.839, 0.667), Line(railD + 20.0, 1.3) * 0.28);     // highlight
                    float stitch = step(frac(p.x / 7.0), 4.0 / 7.0);
                    leather = lerp(leather, float3(0.941, 0.824, 0.667), Line(railD + 10.0, 1.0) * stitch * 0.4); // seam
                    col = lerp(col, leather, railCover);
                }
                col = lerp(col, float3(0.0706, 0.0235, 0.0078), Line(railD - railHalf, 2.0));                   // lower lip
                if (railD > railHalf + 1.0) col = lerp(col, roomDeep, saturate((railD - railHalf) / 30.0));

                fixed4 color = fixed4(col, 1.0) * IN.color;

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
