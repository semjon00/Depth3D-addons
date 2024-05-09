### Depth3D addons - ReShade shaders for better Depth3D experience
**What is Depth3D?**<br/>
[Depth3D](https://github.com/BlueSkyDefender/Depth3D) is a shader collection for [ReShade](https://reshade.me/).
In simple terms, these shaders allow you to play a lot of 3D games
in VR glasses, even if the game does not originally support VR!


**What are the Depth3D alternatives?**<br/>
One alternative is [Geo3D](https://github.com/BlueSkyDefender/Depth3D).
It provides significantly more accurate and convincing 3D, but it also significantly degrades performance and has some glitches.
Another alternative is [geo-11](https://www.mtbs3d.com/phpbb/viewtopic.php?t=26264). The 3D effect provided is similar to the one of Geo3D, but geo-11 has better performance.
The drawback is that it only supports DirectX 11 games and that has a different set of glitches.
This project works well with both of these alternatives.


**Why add anything extra?**<br/>
Depth3D shaders are great and work just fine with may VR glasses.
However, there are some complications that arise
if you use SuperDepth3D with a simple VR set,
for example a Google Cardboard. Now, the setup that I found most comfortable
involved streaming the game picture directly to the phone, that is installed
into the VR set (for example, with the means of [Sunshine](https://github.com/LizardByte/Sunshine) and [Moonlight](https://github.com/moonlight-stream/moonlight-android)).
However, the result is lacking - the picture may end up too large and/or distorted.


**What do shaders in this repository do?**<br/>
The only shader so far is Depth3DAddon.
It allows you to change the size of the rendered image
and move the images for two lenses apart.
Using these features, you can fit
the images into the field of view of your VR set.
Aside from that, the shader allows you to correct
geometric distortion and chromatic aberration.
In simple terms, this means that you can achieve a
better, more realistic image.


**How can I install the shaders?**<br/>
First, install ReShade. Do not forget to install Depth3D shaders with it.
Then, open the reshade-shaders folder. It is positioned inside the folder where
your game is located. After that, copy the files from this repository to the
reshade-shaders folder (it is sufficient to copy the Shaders folder only).
After that, open the game, press the Home key and configure the shaders as you like.

Happy gaming!
