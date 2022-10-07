// Version 1.0

#include "FXShaders/Common.fxh"
#include "Reshade.fxh"

#ifndef VIRTUAL_RESOLUTION_UPFILTER
#define VIRTUAL_RESOLUTION_UPFILTER POINT
#endif

#ifndef VIRTUAL_RESOLUTION_DOWNFILTER
#define VIRTUAL_RESOLUTION_DOWNFILTER LINEAR
#endif

#ifndef VIRTUAL_RESOLUTION_DYNAMIC
#define VIRTUAL_RESOLUTION_DYNAMIC 1
#endif

#ifndef VIRTUAL_RESOLUTION_WIDTH
#define VIRTUAL_RESOLUTION_WIDTH BUFFER_WIDTH
#endif

#ifndef VIRTUAL_RESOLUTION_HEIGHT
#define VIRTUAL_RESOLUTION_HEIGHT BUFFER_HEIGHT
#endif

namespace FXShaders
{

#if VIRTUAL_RESOLUTION_DYNAMIC

uniform float fResolutionX <
	ui_label = "Virtual Resolution Width";
	ui_type = "drag";
	ui_min = 1.0;
	ui_max = BUFFER_WIDTH;
	ui_step = 1.0;
> = BUFFER_WIDTH;

uniform float fResolutionY <
	ui_label = "Virtual Resolution Height";
	ui_type = "drag";
	ui_min = 1.0;
	ui_max = BUFFER_HEIGHT;
	ui_step = 1.0;
> = BUFFER_HEIGHT;

#define Resolution float2(fResolutionX, fResolutionY)

#else

static const float2 Resolution = float2(
	VIRTUAL_RESOLUTION_WIDTH,
	VIRTUAL_RESOLUTION_HEIGHT);

#endif

texture BackBufferTex : COLOR;

sampler BackBufferDownSample {
	Texture = BackBufferTex;
	MinFilter = VIRTUAL_RESOLUTION_DOWNFILTER;
	MagFilter = VIRTUAL_RESOLUTION_DOWNFILTER;
	AddressU = BORDER;
	AddressV = BORDER;
};

#if VIRTUAL_RESOLUTION_DYNAMIC

sampler BackBufferUpSample {
	Texture = BackBufferTex;
	MinFilter = VIRTUAL_RESOLUTION_UPFILTER;
	MagFilter = VIRTUAL_RESOLUTION_UPFILTER;
	AddressU = BORDER;
	AddressV = BORDER;
};

#else

texture DownSampledTex {
	Width = VIRTUAL_RESOLUTION_WIDTH;
	Height = VIRTUAL_RESOLUTION_HEIGHT;
};
sampler DownSampled {
	Texture = DownSampledTex;
	MinFilter = VIRTUAL_RESOLUTION_UPFILTER;
	MagFilter = VIRTUAL_RESOLUTION_UPFILTER;
	AddressU = BORDER;
	AddressV = BORDER;
};

#endif

float2 Stretch(float2 uv)
{
	float2 ar_real = GetResolution();
	return ScaleCoord(uv, float2(ar_real[0] / Resolution.x, ar_real[1] / Resolution.y));
}

float4 DownSamplePS(float4 pos : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	#if VIRTUAL_RESOLUTION_DYNAMIC
		float2 scale = Resolution * GetPixelSize();
		float4 color = tex2D(BackBufferDownSample, ScaleCoord(uv, 1.0 / scale));
		
		return color;
	#else
		return tex2D(BackBufferDownSample, uv);
	#endif
}

float4 UpSamplePS(float4 pos : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	uv = Stretch(uv);

	#if VIRTUAL_RESOLUTION_DYNAMIC
		float2 scale = Resolution * GetPixelSize();
		uv = ScaleCoord(uv, scale);

		float4 color = tex2D(BackBufferUpSample, uv);
	#else
		float4 color = tex2D(DownSampled, uv);
	#endif

	return color;
}

technique DownscaleWithBorders
{
	pass DownSample
	{
		VertexShader = PostProcessVS;
		PixelShader = DownSamplePS;

		#if !VIRTUAL_RESOLUTION_DYNAMIC
			RenderTarget = DownSampledTex;
		#endif
	}
	pass UpSample
	{
		VertexShader = PostProcessVS;
		PixelShader = UpSamplePS;
	}
}

} // Namespace.
