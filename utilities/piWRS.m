function [obj, results, thisD] = piWRS(thisR,varargin)
% Write, Render, Show a scene specified by a recipe (thisR).
%
% Brief description:
%   We often write, render and show a scene or oi.  This executes that
%   sequence, allowing the user to set a few parameters.  It is possible to
%   control some of the parameters in key/val options.
%
%   If you set the render type in the calling argument, we just adjust the
%   recipe locally.  The recipe will not be changed upon return.
%
% Synopsis
%   [isetObj, results] = piWRS(thisR, varargin)
%
% Inputs
%   thisR - A recipe
%
% Optional key/val pairs
%
%   'render type' - Cell array of render objectives ('radiance','depth',
%           ... others).  If it is a char, then we convert it to a cell.
%   'show' -  Call a window to show the object and insert it in
%             the vcSESSION database (Default: true);
%   'docker wrapper' - Specify the docker wrapper we will pass to
%                      piRender ('our docker') is an equivalent.
%
%   'name'  - Set the Scene or OI name
%   'gamma'      - Set the display gamma for the window
%   'render flag' - {'hdr','rgb','gray','clip'}  (default: 'rgb' or
%                   whatever is already in the window, if it is open.
%   'speed' - Reduces the spatial resolution and other parameters to speed
%             up the rendering at the cost of precision.  Useful for
%             checking asset geometry quickly.  Default value: 1 (leaves
%             the recipe unchanged).  A value of N reduces the resolution
%             by a factor of N.  Bounces and number of rays are reduced,
%             too.
%    'remote resources' - Applies to cases when the remote device has all
%             of the graphics resources needed (textures, meshes) and the
%             main PBRT file will be able to reference them without copying
%             from the local computer.  (Better comment needed)
%    'denoise' - Run the piAIdenoise prior to returning
%    'main file only' - piWrite flag
%
% Returns
%   obj     - a scene or oi
%   results - The piRender text outputs
%   thisD   - a docker with the parameters for this run
%
% Description
%   
%
% See also
%   piRender, sceneWindow, oiWindow

%%
varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('thisR',@(x)(isa(x,'recipe')));

% You can over-ride the render type with this argument
p.addParameter('rendertype','',@(x)(ischar(x) || iscell(x)));

p.addParameter('docker','');
p.addParameter('name','',@ischar);
p.addParameter('show',true,@islogical);
p.addParameter('gamma',[],@isnumeric);
p.addParameter('denoise',false,@islogical);
p.addParameter('renderflag','',@ischar);
p.addParameter('speed',1,@isscalar);     % Spatial resolution divide
p.addParameter('meanluminance',-1,@isscalar);
p.addParameter('replace',false,@islogical);
p.addParameter('mainfileonly',false,@islogical);
p.addParameter('pushresources',false,@islogical);

% allow parameter passthrough
p.KeepUnmatched = true;

p.parse(thisR,varargin{:});

g          = p.Results.gamma;
renderFlag = p.Results.renderflag;
replace    = p.Results.replace;

% meanLuminance = p.Results.meanluminance;

% Determine whether we over-ride or not
renderType = p.Results.rendertype;
if isempty(renderType),     renderType = thisR.get('render type'); % Use the recipe render type
elseif ischar(renderType),  renderType = {renderType};     % Turn a string to cell
elseif iscell(renderType)        % Good to go  
end

% Fix empty rendertypes to be the default:
if isempty(renderType)
    renderType = [{'radiance'},{'depth'},{'normal'}];
end

if ~isempty(p.Results.docker)
    thisD = p.Results.docker;
else
    thisD = isetdocker();
end

name = p.Results.name;
show = p.Results.show;
speed = p.Results.speed;
if ~(speed == 1)
    fprintf('\n***\nRender speedup %d X. Reducing resolution, bounces, and nrays.\n***\n',speed)
    % Set the resolution and bounces very low
    ss = thisR.get('film resolution');
    thisR.set('film resolution',round(ss/speed));
    nb = thisR.get('nbounces');
    thisR.set('nbounces',1);
    nrays = thisR.get('rays per pixel');
    thisR.set('rays per pixel',128);
end

%% In version 4 we set the render type this way

% We preserve the render type in the recipe.
oldRenderType = thisR.get('render type');

% But the user may have given us a new render type
thisR.set('render type',renderType);

% Write the local/pbrt directory being aware about whether the resources
% are expected to be present remotely.
piWrite(thisR);

[obj, results, thisD] = piRender(thisR, 'docker', thisD);

if isempty(obj),  error('Render failed.'); end

switch obj.type
    case 'scene'
        if ~isempty(name), obj = sceneSet(obj,'name',name); end
        if show
            if replace, ieReplaceObject(obj); sceneWindow;
            else,       sceneWindow(obj);
            end

            if ~isempty(g), sceneSet(obj,'gamma',g); end
            if ~isempty(renderFlag)
                % Removed test for ISETBio. Aug 2023.
                sceneSet(obj,'render flag',renderFlag);
            end
            
        end
    case 'opticalimage'
        if ~isempty(name), obj = oiSet(obj,'name',name); end
        if show
            if replace, ieReplaceObject(obj); oiWindow;
            else,       oiWindow(obj);
            end
            
            if ~isempty(g), oiSet(obj,'gamma',g); end
            if ~isempty(renderFlag) 
                % Removed test for ISETBio. Aug 2023
                oiSet(obj,'render flag',renderFlag);                 
            end
        end
        % Store the recipe camera on the oi.  Not sure why, but it
        % seems like a good idea.  I considered the film, too, but
        % that doesn't have much extra.
        obj.camera = thisR.get('camera');
end

if p.Results.denoise
    obj = piAIdenoise(obj);
end

%% Put parameters back.
thisR.set('render type',oldRenderType);
if ~(speed == 1)
    thisR.set('film resolution',ss);
    thisR.set('nbounces',nb);
    thisR.set('rays per pixel',nrays);
end

end
