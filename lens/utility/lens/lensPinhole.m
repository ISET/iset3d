function lens = lensPinhole(diameter)
% Make a pinhole with a specific diameter
%
% The pinhole is returned in the form of a lensC
%

% Examples:
%{
   thisPinhole = lensPinhole(3);
   thisPinhole.draw; 
   set(gca,'xlim',[-10 70]);
%}

%% Start with a two-element simple lens
lens = lensC('file','2ElLens.json');

% Make the surfaces very flat
lens.surfaceArray(1).sRadius = 5000;
lens.surfaceArray(1).sCenter = [0 0 4999.5];

lens.surfaceArray(3).sRadius = -5000;
lens.surfaceArray(3).sCenter = [0 0 -4999.5];
lens.surfaceArray(1).n(:) = 1;

%% Set the aperture diameter
lens.surfaceArray(2).apertureD = diameter;  % millimeters

% Position the aperture just to the left of the first surface
lens.surfaceArray(2).sCenter = [0 0 -.6];

end
