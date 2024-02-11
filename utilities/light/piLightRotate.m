function lght = piLightRotate(lght, varargin)
% Rotate the direction of a light source
%
% SOMETHING IS WRONG HERE. DOC DOESN"T MATCH CODE
%
% Synopsis
%   thisR = piLightRotate(thisR, idx,varargin)
%
% Inputs:
%   thisR:   recipe
%   idx:     Index to a light
%
% Optional key/value pairs
%   
% Returns
%   thisR:  the modified recipe
%
% Description
%   
%   Spot lights can be 


% Examples
%{
    ieInit;
    thisR = piRecipeDefault;
    thisR.set('lights','all','delete');
    spotLight = piLightCreate('new spot', 'type', 'spot',...
                'cameracoordinate', true,...
                'spd val', 'D50',...
                'coneangle val', 5);
    spotLight = piLightRotate(spotLight, 'x rot', 5);
    thisR.set('light', spotLight, 'add');

    piWrite(thisR, 'overwritematerials', true);

    % Render
    [scene, result] = piRender(thisR, 'render type','radiance');
    sceneWindow(scene);

%}
%{
    % Another way of setting rotation
    ieInit;
    thisR = piRecipeDefault;
    thisR.set('lights','all','delete');
    spotLight = piLightCreate('new spot', 'type', 'spot',...
                'cameracoordinate', true,...
                'spd val', 'D50',...
                'coneangle val', 5);
    thisR.set('light', spotLight, 'add');
    thisR.set('light', 'new spot', 'rotate', [5 0 0]);

    piWrite(thisR, 'overwritematerials', true);

    % Render
    [scene, result] = piRender(thisR, 'render type','radiance');
    sceneWindow(scene);

%}
%% parse

% Remove spaces, force lower case
varargin = ieParamFormat(varargin);
p = inputParser;

p.addRequired('lght', @isstruct);

p.addParameter('xrot', 0, @isscalar);
p.addParameter('yrot', 0, @isscalar);
p.addParameter('zrot', 0, @isscalar);
p.addParameter('order',['x', 'y', 'z'], @isvector);

p.parse(lght, varargin{:});

lght  = p.Results.lght;
xrot   = p.Results.xrot;
yrot   = p.Results.yrot;
zrot   = p.Results.zrot;
order  = p.Results.order;

%% Rotate the light

switch lght.type
    case 'infinite'
        % Ask (ZL)^2 about this.  Probably piWrite() does something with
        % these parameters.  What do they each mean?
       lght = piLightSet(lght, 'rotation val', {[0 0 1 0], [xrot,yrot,zrot, 0]});

    otherwise
        if ~isfield(lght, 'to')
            warning('This light does not have a to field! Doing nothing.');
            return;
        end
        
        for ii = 1:numel(order)
            thisAxis = order(ii);
            
            toVal   = piLightGet(lght, 'to val');
            fromVal = piLightGet(lght, 'from val');
            toDir   = toVal - fromVal;
            
            if isempty(toDir)
                warning('Cannot use this routine to rotate a skymap');
                return;
            end
            
            switch thisAxis
                case 'x'
                    rotationMatrix = rotationMatrix3d([deg2rad(xrot),0,0]);
                case 'y'
                    rotationMatrix = rotationMatrix3d([0,deg2rad(yrot),0]);
                case 'z'
                    rotationMatrix = rotationMatrix3d([0,0,deg2rad(zrot)]);
                otherwise
                    error('Unknown axis: %s.\n', thisAxis);
            end
            
            
            newto = reshape(toDir, [1, 3]) * rotationMatrix;
            
            %{
            if ii ~= 1
                idx = numel(thisR.lights);
            end
            %}
            lght = piLightSet(lght, 'to val', fromVal + newto);
            % piLightSet(thisR, idx, 'to', thisR.lights{idx}.from + newto);
        end
end
end
