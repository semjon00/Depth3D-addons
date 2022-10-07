// Version 1.0

uniform float fSplitDistance <
    ui_label = "Split apart distance";
    ui_tooltip = "How far to move the halfs of the image from eachother.";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = BUFFER_WIDTH / 2;
    ui_step = 1.0;
> = 0.0;

#include "ReShade.fxh"

//pixel shaders
float4 PS_AreaCopy(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float splitCoff = fSplitDistance * ReShade::PixelSize.x;
	float borderX = BUFFER_WIDTH / 2.0;
	float2 pos = texcoord / ReShade::PixelSize;
	
    if (pos.x >= borderX + fSplitDistance) {
        float2 destCoord = texcoord - float2(splitCoff, 0.0);
		float4 colorDest = tex2Dlod(ReShade::BackBuffer, float4(destCoord, 0, 0));
		return colorDest;
	} else if (pos.x <= borderX - fSplitDistance) {
		float2 destCoord = texcoord + float2(splitCoff, 0.0);
		float4 colorDest = tex2Dlod(ReShade::BackBuffer, float4(destCoord, 0, 0));
		return colorDest;
    } else {
		return float4(0.0, 0.0, 0.0, 0.0);
	}
}

//techniques
technique SplitApart {
    pass {
        VertexShader = PostProcessVS;
        PixelShader = PS_AreaCopy;
    }
}
