### Depth3D addons - ReShade shaders for better Depth3D experience
**What is Depth3D?**<br/>
[Depth3D](https://github.com/BlueSkyDefender/Depth3D) is a shader collection for [ReShade](https://reshade.me/).
In simple terms, these shaders allow you to play a lot of 3D games
in VR glasses, even if the game does not originally support VR!


**Why add anything extra?**<br/>
Depth3D shaders are great and work just fine with may VR glasses.
However, there are some complications if you use Google Cardboard,
especially if you stream the picture directly to the phone
of the Google Cardboard setup
(for example, with the means of Moonlight). The picture may be distorted over
some ax, too large to fit into the field of view of the VR glasses,
or overly detailed, whereas the phone does not support such a high resolution.


**What do shaders in this repository do?**<br/>
DownscaleWithBorders shader allows you to change the size of the rendered image,
so it would fit into FOV of your Google Cardboard. Pro tip: if you play in
full-screen, you can lower the resolution. If you do this carefully,
the picture quality will not suffer.
SplitApart shader allows you to, well, split apart images for two lenses of the glasses.
This is absolutely necessary if you use the first shader, because otherwise
you will not be able to focus your eyes on the image, which is painful and
completely destroys 3D effect.


**How can I install the shaders?**<br/>
First, install ReShade. Do not forget to install Depth3D shaders.
Then, open the reshade-shaders folder, that was created in the folder where
your game is located. Now, copy the files from this repository to the
reshade-shaders folder (it is sufficient to copy the Shaders folder only).
After that, open the game, press the Home key, and configure the shaders as you like.