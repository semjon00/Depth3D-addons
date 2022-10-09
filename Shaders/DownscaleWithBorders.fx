// Version 1.1

#include "Reshade.fxh"

#ifndef VIRTUAL_RESOLUTION_DOWNFILTER
#define VIRTUAL_RESOLUTION_DOWNFILTER LINEAR
#endif

uniform float fResolutionX <
	ui_label = "Virtual Resolution Width";
	ui_type = "drag";
	ui_min = 0.05;
	ui_max = 1.0;
	ui_step = 0.0001;
> = 1.0; // BUFFER_WIDTH

uniform float fResolutionY <
	ui_label = "Virtual Resolution Height";
	ui_type = "drag";
	ui_min = 0.05;
	ui_max = 1.0;
	ui_step = 0.0001;
> = 1.0; // BUFFER_HEIGHT

float2 ScaleCoord(float2 uv, float2 scale, float2 pivot)
{
	return (uv - pivot) * scale + pivot;
}

texture BackBufferTex : COLOR;

sampler BackBufferDownSample {
	Texture = BackBufferTex;
	MinFilter = VIRTUAL_RESOLUTION_DOWNFILTER;
	MagFilter = VIRTUAL_RESOLUTION_DOWNFILTER;
	AddressU = BORDER;
	AddressV = BORDER;
};

float2 PosReverseDownscale(float2 texcoord) {
	// ReShade::PixelSize
	float2 scale = float2(fResolutionX, fResolutionY);
	return ScaleCoord(texcoord, 1.0 / scale, 0.5);
}

float4 DownSamplePS(float4 pos : SV_POSITION, float2 texcoord : TEXCOORD) : SV_TARGET
{
	float4 color = tex2D(BackBufferDownSample, PosReverseDownscale(texcoord));
	return color;
}

technique DownscaleWithBorders
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = DownSamplePS;
	}
}
