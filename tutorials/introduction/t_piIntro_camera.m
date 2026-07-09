%% Camera introduction
%
% This tutorial shows the default perspective camera, a few film/camera
% parameters, and one low-cost render.  Lens-specific behavior is covered
% in t_piIntro_lens.
%
% See also
%   t_piIntro_lens, t_cameraParameters

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Initialize a default recipe for a simple scene

thisR = piRecipeCreate('SimpleScene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);

fprintf('Camera type: %s\n',thisR.get('camera subtype'));
fprintf('FOV: %.1f deg\n',thisR.get('fov'));
fprintf('Film resolution: %d x %d pixels\n',thisR.get('film resolution'));

%% Use one environment light

thisR.set('light','all','delete');
thisR.set('skymap','room.exr');
thisR.set('light','room_L','specscale',1500);
thisR.show('lights');

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered simple scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
