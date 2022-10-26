// Version 3.0

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
	ui_category = "Basic";
> = 1.0; // BUFFER_WIDTH

uniform float fResolutionY <
	ui_label = "Virtual Resolution Height";
	ui_type = "drag";
	ui_min = 0.05;
	ui_max = 1.0;
	ui_step = 0.0001;
	ui_category = "Basic";
> = 1.0; // BUFFER_HEIGHT

uniform float fSplitCoff <
	ui_label = "Split Apart Distance";
	ui_tooltip = "How far to move the halfs of the image from each other.";
	ui_type = "slider";
	ui_min = -0.3;
	ui_max = +0.3;
	ui_step = 0.0001;
	ui_category = "Basic";
> = 0.0;

uniform float fElevation <
	ui_label = "Elevation";
	ui_tooltip = "Move the images up or down.";
	ui_type = "slider";
	ui_min = -0.25;
	ui_max = +0.25;
	ui_step = 0.0001;
	ui_category = "Basic";
> = 0.0;

uniform float fLensCenterOffset <
	ui_label = "Lens Center Offset";
	ui_tooltip = "Adjust the center of the lens to get better\neffect from advanced image corrections.";
	ui_type = "slider";
	ui_min = -0.1;
	ui_max = +0.1;
	ui_step = 0.0001;
	ui_category = "Advanced";
> = 0.0;

uniform float fFishEyeCoffA <
	ui_label = "Fish Eye A";
	ui_tooltip = "Correct for geometric distortion.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
	ui_category = "Advanced";
> = 0.0;

uniform float fFishEyeCoffB <
	ui_label = "Fish Eye B";
	ui_tooltip = "Correct for geometric distortion.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 5.0;
	ui_step = 0.0001;
	ui_category = "Advanced";
> = 0.0;

uniform float fChromaticAberrationCoff <
	ui_label = "Red-Blue correction";
	ui_tooltip = "Correct for chromatic aberration.";
	ui_type = "slider";
	ui_min = -0.100;
	ui_max = +0.100;
	ui_step = 0.001;
	ui_category = "Advanced";
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

// Receives the target position.
// Seeks corresponding position to sample from, for a given channel
float2 PosReverseModify(float2 texcoord, int channel) {
	{ // Reverse elevation
		texcoord = texcoord - float2(0.0, fElevation);
	}
	
	float eyeCenterDelta = (0.25 + fLensCenterOffset) * fResolutionX + fSplitCoff;
	int eye = texcoord.x >= 0.5 ? +1 : -1;
	float2 eyeCenter = float2(0.5 + eye * eyeCenterDelta, 0.5);
	float2 diff = (texcoord - eyeCenter);
	
	{ // Reverse chromatic abberation
		diff *= 1.0 + (float(channel) - 1.0) * (fChromaticAberrationCoff * 0.25);
	}
	
	{ // Reverse "fisheye"
		float2 mappingCoff = float2(4.0 / fResolutionX, 2.0 / fResolutionY);
		float2 mapped = diff * mappingCoff;
		float distortionCurveParam = length(mapped);
		float fFishEyeCoffAPrime = pow(max(0.0, fFishEyeCoffA), 2.71828182846);
		float fFishEyeCoffBPrime = pow(fFishEyeCoffB, 2);
		float2 distortionCoff = 1 + fFishEyeCoffAPrime * pow(distortionCurveParam, fFishEyeCoffBPrime);
		texcoord = eyeCenter + distortionCoff * diff;
		
		int eyeResult = texcoord.x >= 0.5 ? +1 : -1;
		if (eyeResult != eye) {
			return NONE_POSITION;
		}
	}
	
	{ // Reverse downscale
		float2 scale = float2(fResolutionX, fResolutionY);
		float2 pivot = float2(0.5, 0.5);
		texcoord = (texcoord - pivot) / scale + pivot;
	}
	
	{ // Reverse split apart
		float coordX = texcoord.x;
		if (coordX >= 0.5 && coordX - fSplitCoff >= 0.5) {
			texcoord = texcoord - float2(fSplitCoff, 0.0);
		} else if (coordX < 0.5 && coordX + fSplitCoff < 0.5) {
			texcoord = texcoord + float2(fSplitCoff, 0.0);
		} else {
			return NONE_POSITION;
		}
	}
	
	return texcoord;
}

float4 PosToColor(float2 texcoord) {
	return tex2D(BackBufferDownSample, texcoord);
}

float4 MappingPS(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	texcoord = PosReverseModify(texcoord, 0);
	
	float4 ans = PosToColor(PosReverseModify(texcoord, 1));
	if (abs(fChromaticAberrationCoff) > 0.001) {
		ans.x = PosToColor(PosReverseModify(texcoord, 0)).x;
		ans.z = PosToColor(PosReverseModify(texcoord, 2)).z;
	}
	
	return ans;
}

technique Depth3DAddon < ui_tooltip = "A tool for modifying Depth3D output."; >
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = MappingPS;
	}
}
