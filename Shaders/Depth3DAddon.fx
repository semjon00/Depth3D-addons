// Version 4.0

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
	ui_min = -0.1;
	ui_max = +0.1;
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

uniform float fGeoDistrK1 <
	ui_label = "First coefficient";
	ui_tooltip = "Radial distortion coefficient k1.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
	ui_category = "Geometric distortions";
> = 0.0;

uniform float fGeoDistrK2 <
	ui_label = "Second coefficient";
	ui_tooltip = "Radial distortion coefficient k2.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
	ui_category = "Geometric distortions";
> = 0.0;

uniform float fGeoDistrK3 <
	ui_label = "Third coefficient";
	ui_tooltip = "Radial distortion coefficient k3.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = 1.0;
	ui_step = 0.0001;
	ui_category = "Geometric distortions";
> = 0.0;

uniform float fChromaticAberrationCoff <
	ui_label = "Red-Blue correction";
	ui_tooltip = "Correct for chromatic aberration.";
	ui_type = "slider";
	ui_min = 0.0;
	ui_max = +0.020;
	ui_step = 0.001;
	ui_category = "Color distortions";
> = 0.0;

uniform bool bTestingImage <
	ui_label = "Testing image";
	ui_tooltip = "Use this to test how well\nthe parameters map to the glasses";
> = false;

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
	
	float eyeCenterDelta = 0.25 * fResolutionX + fSplitCoff;
	int eye = texcoord.x >= 0.5 ? +1 : -1;
	float2 eyeCenter = float2(0.5 + eye * eyeCenterDelta, 0.5);
	float2 diff = (texcoord - eyeCenter);
	
	{ // Reverse chromatic abberation
		diff *= 1.0 + (float(channel) - 1.0) * fChromaticAberrationCoff;
	}
	
	{ // Reverse "fisheye"
		float2 mappingCoff = float2(4.0 / fResolutionX, 2.0 / fResolutionY);
		float2 mapped = diff * mappingCoff;
		float r = length(mapped);
		
		float2 distortionCoff = 1.0 + fGeoDistrK1 * pow(r, 2) + fGeoDistrK2 * pow(r, 4) + fGeoDistrK3 * pow(r, 6);
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

float4 TestingImage(float2 texcoord) {
		int eye = texcoord.x >= 0.5 ? +1 : -1;
		float2 pos = texcoord * float2(4.0, 2.0) - float2(2.0 + eye, 1);
		uint2 grid = uint2(uint(0.5 + abs(100 * pos.x)), uint(0.5 + abs(100 * pos.y)));
		
		bool isWhite = false;
		
		if (grid.x % 9 == 0 && grid.y % 9 == 0) isWhite = true;
		
		if ((grid.x == 81 || grid.y == 81) && (grid.x < 82 && grid.y < 82)) isWhite = true;
		if (grid.x == 90 || grid.y == 90) isWhite = true;
		if (grid.x > 90 || grid.y > 90) isWhite = false;
		
		return isWhite ? float4(1.0,1.0,1.0,0.0) : float4(0.0,0.0,0.0,0.0);
}

float4 PosToColor(float2 texcoord) {
	if (!bTestingImage) {
		return tex2D(BackBufferDownSample, texcoord);
	} else {
		return TestingImage(texcoord);
	}
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

void PostProcessVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD)
{
	texcoord.x = (id == 2) ? 2.0 : 0.0;
	texcoord.y = (id == 1) ? 2.0 : 0.0;
	position = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

technique Depth3DAddon < ui_tooltip = "A tool for modifying Depth3D output.\nMake sure to put in directly after SuperDepth3D or To_Else shader."; >
{
	pass {
		VertexShader = PostProcessVS;
		PixelShader = MappingPS;
	}
}
