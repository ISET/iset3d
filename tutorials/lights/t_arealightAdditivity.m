%% t_arealightAdditivity
% 
% NYI
%
% Check additivity of lights in PBRT and ISET3d.  We should also check
% additivity of spot lights and such.  Maybe this should become
% t_lightAdditivity.
%
% See also
%  t_arealight*

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Make the lights.  
% They will be in a circle around the camera. The camera is pointed in
% this direction.
nLights = 4;
thisL = cell(nLights,1);

direction = thisR.get('fromto');
[pts, radius] = piRotateFrom(thisR, direction, ...
    'n samples',nLights+1, ...
    'radius',velscopeRadius,...
    'show',false);

for ii=1:nLights
    % Point all the lights down the z-axis.
    thisL{ii} = piLightCreate(sprintf('light-%d',ii),...
        'type','spot', ...
        'from',pts(:,ii),'to',pts(:,ii) + direction(:), ...
        'spd spectrum','Velscope2023');

    thisL{ii} = piLightSet(thisL{ii},'coneangle',coneangle);
    thisL{ii} = piLightSet(thisL{ii},'conedeltaangle',conedeltaangle);
end

%% Render one light at a time.

mLum = 0;
rect = [117   128   101    72];
for ll = 1:numel(thisL)
    thisR.set('lights','all','delete');
    thisR.set('lights',thisL{ll},'add');

    % Do not scale the signal on the way back.  The absolute number is
    % meaningless, but the relative levels are meaningful.
    scene = piWRS(thisR,...
        'name',sprintf('Light #%d',ll),...
        'mean luminance',-1, ...
        'denoise',false, ...
        'render flag','gray');

    mLum = mLum + sceneGet(scene,'roi mean luminance',rect);
end

%% Now insert all the lights

% The output does not equal the sum of the separately calculated
% scenes.  I am guessing this is because the way the ray tracer works
% it does not calculate the same rays and the physical calculation is
% just wrong.

thisR.set('lights','all','delete');
for ll = 1:numel(thisL)
    thisR.set('lights',thisL{ll},'add');
end

% Do not scale the signal on the way back.  The absolute number is
% meaningless, but the relative levels are meaningful.
scene = piWRS(thisR,...
    'name',sprintf('Lights'),...
    'mean luminance',-1, ...
    'denoise',false, ...
    'render flag','gray');
    
mLum = sceneGet(scene,'roi mean luminance',rect);
