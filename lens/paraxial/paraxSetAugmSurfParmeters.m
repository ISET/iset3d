% Add the information about the not-center parameters (aka Augment Parameters) of the surface

function [surf]=paraxSetAugmSurfParmeters(surf,Dy_dec,Du_tilt)

%INPUT
%surf: surface structure
%y_dec: decentring of the surface refered to the optical axis [unit= surface.unit]
%u_tilt: tilting angle of the surface refered to the optical axis [radiant]


%OUTPUT
%%surf: surface structure



surf.augParam.Dy_dec=Dy_dec;
surf.augParam.Du_tilt=Du_tilt;