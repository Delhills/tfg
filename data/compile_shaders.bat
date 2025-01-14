%VK_SDK_PATH%/Bin/glslc.exe shaders/prueba.comp -o shaders/output/prueba.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/prueba.comp -o ../x64/Release/data/shaders/output/prueba.comp.spv


%VK_SDK_PATH%/Bin/glslc.exe shaders/prepareIndirect.comp -o shaders/output/prepareIndirect.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/prepareIndirect.comp -o ../x64/Release/data/shaders/output/prepareIndirect.comp.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/gridReset.comp -o shaders/output/gridReset.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/gridReset.comp -o ../x64/Release/data/shaders/output/gridReset.comp.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/surfelRandomPos.comp -o shaders/output/surfelRandomPos.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/surfelRandomPos.comp -o ../x64/Release/data/shaders/output/surfelRandomPos.comp.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/updateSurfels.comp -o shaders/output/updateSurfels.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/updateSurfels.comp -o ../x64/Release/data/shaders/output/updateSurfels.comp.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/gridOffset.comp -o shaders/output/gridOffset.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/gridOffset.comp -o ../x64/Release/data/shaders/output/gridOffset.comp.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/surfelbinning.comp -o shaders/output/surfelbinning.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/surfelbinning.comp -o ../x64/Release/data/shaders/output/surfelbinning.comp.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/deferred.frag -o shaders/output/deferred.frag.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/deferred.frag -o ../x64/Release/data/shaders/output/deferred.frag.spv

%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/surfelRayGen.rgen -o shaders/output/surfelRayGen.rgen.spv
%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/surfelRayGen.rgen -o ../x64/Release/data/shaders/output/surfelRayGen.rgen.spv

%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/surfelMiss.rmiss -o shaders/output/surfelMiss.rmiss.spv
%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/surfelMiss.rmiss -o ../x64/Release/data/shaders/output/surfelMiss.rmiss.spv

%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/surfelHit.rchit -o shaders/output/surfelHit.rchit.spv
%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/surfelHit.rchit -o ../x64/Release/data/shaders/output/surfelHit.rchit.spv

%VK_SDK_PATH%/Bin/glslc.exe shaders/surfelshade.comp -o shaders/output/surfelshade.comp.spv
%VK_SDK_PATH%/Bin/glslc.exe shaders/surfelshade.comp -o ../x64/Release/data/shaders/output/surfelshade.comp.spv


%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/shadowRayGen.rgen -o shaders/output/shadowRayGen.rgen.spv
%VK_SDK_PATH%/Bin/glslc.exe --target-spv=spv1.5 shaders/shadowRayGen.rgen -o ../x64/Release/data/shaders/output/shadowRayGen.rgen.spv
