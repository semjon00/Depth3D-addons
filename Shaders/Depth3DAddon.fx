// Version 2.0

#include "ReShade.fxh"

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

uniform float fSplitCoff <
    ui_label = "Split Apart Distance";
    ui_tooltip = "How far to move the halfs of the image from eachother.";
    ui_type = "slider";
    ui_min = -0.5;
    ui_max = +0.5;
    ui_step = 0.0001;
> = 0.0;

texture BackBufferTex : COLOR;
sampler BackBufferDownSample {
	Texture = BackBufferTex;
	MinFilter = VIRTUAL_RESOLUTION_DOWNFILTER;
	MagFilter = VIRTUAL_RESOLUTION_DOWNFILTER;
	AddressU = BORDER;
	AddressV = BORDER;
};

#define NONE_POSITION float2(-100.0, -100.0)

float4 PosToColor(float2 texcoord) {
	return tex2D(BackBufferDownSample, texcoord);
}

float2 PosReverseSplitApart(float2 texcoord) {
	float coordX = texcoord.x;
	if (coordX >= 0.5 && coordX - fSplitCoff >= 0.5) {
		return texcoord - float2(fSplitCoff, 0.0);
	} else if (coordX < 0.5 && coordX + fSplitCoff < 0.5) {
		return texcoord + float2(fSplitCoff, 0.0);
	} else {
		return NONE_POSITION;
	}
}

float2 PosReverseDownscale(float2 texcoord) {
	// ReShade::PixelSize
	float2 scale = float2(fResolutionX, fResolutionY);
	float2 pivot = float2(0.5, 0.5);
	return (texcoord - pivot) / scale + pivot;
}

float4 ChainPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	texcoord = PosReverseSplitApart(texcoord);
	texcoord = PosReverseDownscale(texcoord);
	return PosToColor(texcoord);
}

technique Depth3DAddon {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ChainPS;
    }
}
