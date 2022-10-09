// Version 2.1

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

uniform float fFishEyeCoffA <
    ui_label = "Fish Eye Coefficient";
    ui_tooltip = "How much fish eye to apply.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.3183;
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

float2 PosReverseRoundify(float2 texcord) {
	float eyeCenterDelta = 0.25 * fResolutionX + fSplitCoff;
	int eye = texcord.x >= 0.5 ? +1 : -1;
	float2 eyeCenter = float2(0.5 + eye * eyeCenterDelta, 0.5);
	float2 diff = texcord - eyeCenter;
	
	float2 morfPoint2 = float2(abs(diff.x), abs(diff.y)) * float2(2.0, 1.0);
	morfPoint2 = float2(min(morfPoint2.x, morfPoint2.y), max(morfPoint2.x, morfPoint2.y));
	morfPoint2.y = max(morfPoint2.y, 0.000001);
	float morfPoint = morfPoint2.x / morfPoint2.y;

	float2 distortionCoff = 1 + fFishEyeCoffA * morfPoint * morfPoint;
	float2 result = eyeCenter + distortionCoff * diff;
	
	int eyeResult = result.x >= 0.5 ? +1 : -1;
	
	if (eyeResult == eye) {
		return result;
	} else {
		return NONE_POSITION;
	}
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

float4 PosToColor(float2 texcoord) {
	return tex2D(BackBufferDownSample, texcoord);
}

float4 ChainPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	texcoord = PosReverseRoundify(texcoord);
	texcoord = PosReverseSplitApart(texcoord);
	texcoord = PosReverseDownscale(texcoord);
	return PosToColor(texcoord);
}

technique Depth3DAddon < ui_tooltip = "A tool for modifying Depth3D output."; >
{
    pass {
        VertexShader = PostProcessVS;
        PixelShader = ChainPS;
    }
}
