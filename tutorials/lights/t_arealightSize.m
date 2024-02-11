%% t_arealightSize 
%
% Change the area light size and compensate by changing the area light
% SPD specscale.
%
% See also
%  t_arealight*
%

%% Start fresh with a small Cube
ieInit;
if ~piDockerExists, piDockerConfig; end

clear area;

%% Start fresh with the scene.  Not necessary, but ...
thisR = piRecipeCreate('flat surface');
thisR.set('rays per pixel',128);
specScale = 50;

area{1} = piLightCreate('area1',...
    'type','area',...
    'spd spectrum','D65', ...
    'specscale',specScale);
thisR.set('lights',area{1},'add');
thisR.set('light','area1','spread',15);  % Narrow spread so the size will be easier to see
thisR.set('light','area1','rotate',[0 180 0]);
thisR.show('lights');

% We cannot use the shape scale parameter as part of the create
% because it is a method, not a parameter.  That could be changed by
% adding it to piLightCreate for the area light.
thisR.set('light',area{1},'shape scale',0.1);

%% Reduce the light's size a couple of times.  
% We change the SPD scaling and Shape scaling together.
scene = piWRS(thisR,'mean luminance',-1,'render flag','rgb');
fprintf('Mean (max) luminance: %.4g (%.4g)\n',...
    sceneGet(scene,'mean luminance'), ...
    sceneGet(scene,'max luminance'));

% The specscale is an absolute level.  So we keep decreasing relative
% to that original specscale level.  This time by 0.3.
thisR.set('light',area{1},'shape scale',0.3);
thisR.set('light',area{1},'specscale',specScale/(0.3)^2);
scene = piWRS(thisR,'mean luminance',-1,'render flag','rgb');
fprintf('Mean (max) luminance: %.4g (%.4g)\n',...
    sceneGet(scene,'mean luminance'), ...
    sceneGet(scene,'max luminance'));

% The specscale is now reduced again so 0.3*0.3
thisR.set('light',area{1},'shape scale',0.3);
thisR.set('light',area{1},'specscale',specScale/(0.3*0.3)^2);
scene = piWRS(thisR,'mean luminance',-1,'render flag','rgb');
fprintf('Mean (max) luminance: %.4g (%.4g)\n',...
    sceneGet(scene,'mean luminance'), ...
    sceneGet(scene,'max luminance'));