function [scene, oi, cMosaic, previews] = computeConeMosaic(obj, options)
%COMPUTECONEMOSAIC Compute the foveal response to a character sample
%   Used in creating data samples for reading recognition
% Returns both the computed cone mosaic and the oi used to generate it
%
% Parameters:
%
% Examples:
%
%
% D. Cardinal, Stanford University, 2022
%

arguments
    obj;
    options.name = 'character sample' % obj.name; % assuming the object has a name
    options.fov = [1 1]; % default of 1 degree
end

%  Needs ISETBio -- and set parallel to thread pool for performance
if piCamBio
    warning('Cone Mosaic requires ISETBio');
    return
end
% Create an oi if we aren't passed one
if ~isempty(obj.oi)
    oi=obj.oi;
    scene = []; % Probably needs to be set to the default if we have one
else
    scene = obj.scene;
    oi = oiCreate('wvf human');
end

%for faster pool init
piUseThreadPool();

% Create the coneMosaic object
% We want this to be about .35mm in diameter
% or 1 degree FOV
cMosaic = coneMosaic;
cMosaic.fov = options.fov; 
cMosaic.emGenSequence(50);

% I think we only need to do oiCompute if we don't have an OI?
if ~isempty(scene)
    oi = oiCompute(scene, oi);
end
cMosaic.name = options.name;
cMosaic.compute(oi);
cMosaic.computeCurrent;

%% Generate previews
% First Frame mean absorptions is a start
% Figure out how to show these? Record as jpeg in db or separate?
previews.oi = oiGet(oi,'rgb image');
previews.scene = sceneGet(scene,'rgb image');
previews.mosaic = cMosaic.absorptions(:,:,1);

