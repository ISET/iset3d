%% t_eyeAccommodate.m
%
% We recommend you go through t_eyeIntro.m before running
% this tutorial.
%
% This tutorial renders a retinal image of "slanted bar." We can then use
% this slanted bar to estimate the modulation transfer function of the
% optical system.
%
% We also show how the color fringing along the edge of the bar due to
% chromatic aberration. 
%
% Depends on: ISETBIO, Docker, ISETCam
%
%  
% See also
%   t_eyeArizona, t_eyeNavarro
%

%% Check ISETBIO and initialize

if piCamBio
    fprintf('%s: requires ISETBio, not ISETCam\n',mfilename); 
    return;
end
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up the slanted bar scene

thisSE = sceneEye('slantedEdge','eye model','navarro');
thisSE.set('to',[0 0 0]);

thisLight = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1]);
thisSE.set('light',thisLight, 'add');
thisSE.set('light',thisLight.name,'specscale',0.5);

% Set up the image
thisSE.set('fov',2);                % Field of view
thisSE.set('spatial samples',[64, 256]);  % Number of OI sample points
thisSE.set('rays per pixel',256);
thisSE.set('n bounces',2);
thisSE.set('focal distance',thisSE.get('object distance','m'));

thisSE.set('lens density',0);       % Remove pigment. Yellow irradiance is harder to see.
thisSE.set('diffraction',false);
thisSE.set('pupil diameter',3);

oDistance = 1;
thisSE.set('object distance',oDistance);
fprintf('Object distance %.2f m\n',oDistance);

piAssetGeometry(thisSE.recipe);
thisSE.recipe.show('lights');

%% Scene

thisDockerGPU = dockerWrapper;
thisSE.set('use pinhole',true);
thisSE.piWRS('docker wrapper',thisDockerGPU,'name','pinhole');  % Render and show

%% Render with model eye, varying diffraction setting

% Use model eye
thisSE.set('use optics',true);

% This sets the chromaticAberrationEnabled flag and the integrator to
% spectral path.
% Now works in V4 - May 28, 2023 (ZL)
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);

thisSE.set('accommodation',1/oDistance);
inFocusAcc = 1/oDistance;
delta = 0.15*inFocusAcc;

% We step the accommodation to see the blur change.
humanDocker = dockerWrapper.humanEyeDocker;
for aa =  (-2*delta + inFocusAcc):delta:(2*delta + inFocusAcc)
    thisSE.set('accommodation',aa);
    name = sprintf('TL distance %.3f',1/aa);

    thisSE.summary;
    oi = thisSE.piWRS('name',name,'docker wrapper',humanDocker,'show',true);
    % oi = piAIdenoise(oi); ,oiWindow(oi);
end

%% Now the arizona eye

thisSE = sceneEye('slantedEdge','eye model','arizona');
thisSE.set('to',[0 0 0]);

thisLight = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1]);
thisSE.set('light',thisLight, 'add');
thisSE.set('light',thisLight.name,'specscale',0.5);

% Set up the image
thisSE.set('fov',2);                % Field of view
thisSE.set('spatial samples',256);  % Number of OI sample points
thisSE.set('rays per pixel',256);
thisSE.set('focal distance',thisSE.get('object distance','m'));
thisSE.set('lens density',0);       % Remove pigment. Yellow irradiance is harder to see.
piAssetGeometry(thisSE.recipe);
thisSE.recipe.show('lights');

%% Render with model eye, varying diffraction setting

% Use model eye
thisSE.set('use optics',true);

% This sets the chromaticAberrationEnabled flag and the integrator to
% spectral path.
% Now works in V4 - May 28, 2023 (ZL)
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);

% With diffraction and big pupil
thisSE.set('diffraction',false);
thisSE.set('pupil diameter',3);

thisSE.set('object distance',oDistance);
fprintf('Object distance %.2f m\n',oDistance);

thisSE.set('accommodation',1/oDistance);
humanDocker = dockerWrapper.humanEyeDocker;
inFocusAcc = 1/oDistance;
delta = 0.1*inFocusAcc;

% We step the accommodation to see the blur change.
for aa =  (-2*delta + inFocusAcc):delta:(2*delta + inFocusAcc)
    thisSE.set('accommodation',aa);
    name = sprintf('TL distance %.3f',1/aa);

    thisSE.summary;
    oi = thisSE.piWRS('name',name,'docker wrapper',humanDocker,'show',true);
    % oi = piAIdenoise(oi); oiWindow(oi);
end

%% END