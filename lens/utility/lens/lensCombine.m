function [combinedLens,uLens, iLens, dockerCmd] = lensCombine(uLens,iLens,uLensHeight,nMicrolens)
% Deprecated:  Combines the microlens and imaging lens into a single
% lens file.  We are now performing this using piMicrolensWrite.
%
% Synopsis
%  [combinedLens,filmHeight,filmWidth,dockerCmd] = lensCombine(uLens,iLens,uLensHeight,nMicrolens)
%
% Brief description
%  Create a json file that incorporates the imaging lens and the
%  microlens information in a format that can be used by PBRT (omni
%  camera).  This method is used for calculating the impact of
%  microlenses.
%   
% Inputs:
%   uLens - Microlens file name
%   iLens - Imaging lens file name
%   uLensHeight - Not sure what this is doing here
%   nMicrolens  - 2-vector of microlens counts in x,y
%
% Optional key/value pairs
%    N/A
%
% Outputs:
%   combinedLens = file name of the combined lens
%   uLens - ISETLens lensC
%   iLens - ISETLens lensC
%   dockerCmd - Command used to call the lenstool
%
% Description:
%  
%  Choose an even number for nMicrolens.  This assures that the sensor
%  and ip data have the right integer relationships.  
%
% See also
%   piMicrolensWrite

%% Parse

%%
uLens     = lensC('filename',uLens);
uLens.adjustSize(uLensHeight);
%{
fprintf('Focal length =  %.3f (mm)\nHeight = %.3f (mm)\nF-number %.3f\n',...
    uLens.focalLength,uLens.get('lens height'),...
    uLens.focalLength/uLens.get('lens height'));
%}

%% Choose the imaging lens 

% For the dgauss lenses 22deg is the half width of the field of view
iLens     = lensC('filename',iLens);
%{
fprintf('Focal length =  %.3f (mm)\nHeight = %.3f\n',...
    imagingLens.focalLength,imagingLens.get('lens height'))
%}

%% Set up the microlens array and film size
% 
filmheight = nMicrolens(1)*uLens.get('lens height');
filmwidth  = nMicrolens(2)*uLens.get('lens height');

% Array beneath each microlens

%% Build the combined lens file using the docker lenstool

[combinedLens,dockerCmd] = piCameraInsertMicrolens(uLens,iLens, ...
    'xdim',nMicrolens(1),  'ydim',nMicrolens(2),...
    'film width',filmwidth,'film height',filmheight);

end
