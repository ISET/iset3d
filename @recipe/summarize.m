function [out, namelist] = summarize(thisR,str)
% Summarize the recipe 
%
% Syntax
%   [out, namelist] = recipe.summarize(str)
%
% Description
%   Prints a summary of the PBRT recipe parameters to the console. This
%   routine has a lot of options.  We might simplify them or at least make
%   the default more useful.  Have a look at sceneEye.summary().
%
% Inputs
%   str:  'all','file','render','camera','film',lookat','assets',
%         'materials',or 'metadata' 
%
% Key/value pairs
%   N/A
%
% Outputs:
%   out  - Either the object described our empty
%   namelist - If str = 'assets', a sorted list of the names of the assets,
%              or if str = 'materials' the names of the materials
%
% Description
%    A quick summary of the critical rendering recipe parameters. In
%    several cases the object described is returned
%
% Wandell
%
% See also
%  sceneEye.summary, recipe, recipeGet
%

% Examples:
%{
 c = thisR.summarize('camera');
%}
%{
 [assets, sortedNames] = thisR.summarize('assets');
  sortedNames
%}
%{
 [~,sortedNames] = thisR.summarize('all');
%}
%% Parse

validStr = {'all','file','render','camera','film','lookat','assets','materials','metadata'};
p = inputParser;
p.addRequired('thisR',@(x)(isequal(class(x),'recipe')));
p.addRequired('str',@(x)(ismember(x,validStr)));

% Default for str is 'all'.  Force to lower case.
if ~exist('str','var'),str = 'all'; end
str = ieParamFormat(str);

p.parse(thisR,str);

namelist = [];
out = [];
%% Build descriptions

switch str
    case 'all'
        thisR.summarize('file');
        thisR.summarize('render');
        thisR.summarize('camera');
        thisR.summarize('film');
        thisR.summarize('lookat');
        [~,namelist] = thisR.summarize('assets');
        % thisR.summarize('materials');  % Included in asset summary
        thisR.summarize('metadata');
    case 'file'
        fprintf('\nFile information\n-----------\n');
        fprintf('Input:  %s\n',thisR.get('input file'));
        fprintf('Output: %s\n',thisR.get('output file'));
        if isfield(thisR,'exporter'), fprintf('Exported by %s\n',thisR.exporter); end
        
    case 'render'
        fprintf('\nRenderer information\n-----------\n');
        fprintf('Rays per pixel %d\n',thisR.get('rays per pixel'));
        fprintf('Bounces %d\n',thisR.get('n bounces'));
        namelist = thisR.world;  % Abusive.  Change variable name.
        
    case {'camera','film'}
        fprintf('\nCamera\n-----------\n');
        if isempty(thisR.camera), return; end
        out = thisR.camera;
        
        fprintf('Sub type:\t%s\n',thisR.get('camera subtype'));
        fprintf('Lens file name:\t%s\n',thisR.get('lens file'));
        switch thisR.get('optics type')
            case 'pinhole'
                % No aperture, focal distance or film distance for
                % pinhole.  Only a diagonal fov.
                fprintf(' Film distance, diagonal, aperture and object distance\n are not used for pinhole rendering.\n\n')
            otherwise
                fprintf('Aperture diameter (mm): %0.2f\n',thisR.get('aperture diameter'));
                fprintf('Focal distance (m):\t%0.2f\n',thisR.get('focal distance'));
                fprintf('Film distance (mm):\t%0.2f\n',thisR.get('film distance','mm'));
                fprintf('Film diagonal (mm):\t%.1f\n',thisR.get('film diagonal','mm'));
                fprintf('Sample spacing (um):\t%.1f\n',thisR.get('sample spacing','um'));
        end
        fprintf('Exposure time (s):\t%.4f\n',thisR.get('exposure time'));
        fprintf('FOV (deg):\t\t%.1f\n',thisR.get('fov'));
        fprintf('Spatial samples:\t%d %d\n',thisR.get('spatial samples'));
                
    case 'lookat'
        fprintf('\nLookat parameters\n-----------\n');
        if isempty(thisR.lookAt), return; end
        out = thisR.lookAt;
        fprintf('from:\t%.3f %.3f %.3f\n',thisR.get('from'));
        fprintf('to:\t%.3f %.3f %.3f\n',thisR.get('to'));
        fprintf('up:\t%.3f %.3f %.3f\n',thisR.get('up'));
        fprintf('object distance: %.3f (m)\n',thisR.get('object distance'));
        
    case 'assets'
        if isempty(thisR.assets)
            fprintf('\nNo assets \n-----------\n');
            return;
        else
            try
                thisR.show('objects');
            catch
            end
        end
                
    case 'materials'
        if isempty(thisR.materials)
            fprintf('\nNo materials \n-----------\n');
            return;
        else
            try
                thisR.show('objects');
            catch
            end
        end
        
    case 'metadata'

        fprintf('\nMetadata\n-----------\n');
        if isempty(thisR.metadata), return; end
        out = thisR.metadata;

        namelist = fieldnames(thisR.metadata);
        fprintf('Fields:\n');
        for ii=1:numel(namelist)
            fprintf('%d\t%s\n',ii,namelist{ii});
        end
        
    otherwise
        error('Unknown parameter %s\n',str);
end

end