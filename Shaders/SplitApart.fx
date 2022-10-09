// Version 1.1

#include "ReShade.fxh"
#define NONE_POSITION float2(-100.0, -100.0)
#define IsNonePosition(a) (a.x < -99.0)

uniform float fSplitCoff <
    ui_label = "Split Apart Distance";
    ui_tooltip = "How far to move the halfs of the image from eachother.";
    ui_type = "slider";
    ui_min = -0.5;
    ui_max = +0.5;
    ui_step = 0.0001;
> = 0.0;

float4 PosToColor(float2 pos) {
	if (!IsNonePosition(pos)) {
		return tex2Dlod(ReShade::BackBuffer, float4(pos, 0, 0));
	} else {
		return float4(0.0, 0.0, 0.0, 0.0);
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

float4 PS_AreaCopy(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
	texcoord = PosReverseSplitApart(texcoord);
	return PosToColor(texcoord);
}

technique SplitApart {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_AreaCopy;
    }
}
