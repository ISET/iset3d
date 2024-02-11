classdef recipe < matlab.mixin.Copyable
% The recipe class contains essential information to render PBRT files
%
% Syntax
%   thisR = recipe;
%
% Default version is PBRT version 4.
%
% TL Scien Stanford, 2017, updated to pbrt-v4 2022

%% PROGRAMMING TODO
%

%%
    properties (GetAccess=public, SetAccess=public)
        % Can be set by user
        %
        name = 'recipe';
        
        % These are all structs that contain the parameters necessary
        % for piWrite to convert the structs to text output in the
        % scene.pbrt file.

        % CAMERA - struct of camera parameters, including the lens
        % file
        camera;
        sampler;     % Sampling algorithm.  Only a few are allowed
        film;        % Equivalent to ISET sensor
        filter;      % Usually pixel filter
        integrator;  % Usually SurfaceIntegrator
        renderer;    %
        lookAt;      % from/to/up struct
        scale;       % Optional scale factor to flip handedness
        world;       % A cell array with all the WorldBegin/End contents
        lights;       % Light sources
        transformTimes; % Transform start and end time

        % INPUTFILE -
        inputFile = '';    % Original PBRT input file
        outputFile = '';   % Where outputFile = piWrite(recipe);
        renderedFile = ''; % Where piRender puts the radiance
        version = 4;     % A PBRTv4 file
        materials;       % struct containing info about the materials, parsed from *_material.pbrt file
        textures;        % struct containing info about the textures used in the scene
        assets;          % assets list parsed from *_geometry.pbrt file
        exporter = '';
        media;           % Volumetric rendering media.
        metadata;
        recipeVer = 2;   % NB: Is this still true?

        hasActiveTransform = false; % flag to allow CPU rendering until GPU support works
        verbose = 2;    % default for how much debugging output to emit.
    end

    properties (Dependent)
    end

     methods (Static)
        files = list(varargin);
     end
     
    methods
        % Constructor
        function obj = recipe(varargin)
            
            obj.materials.list = containers.Map;
            obj.materials.order = {};
            obj.materials.lib = [];
            
            obj.media.list = containers.Map;
            obj.media.order = {};
            obj.media.lib = [];
            
            obj.assets = tree();
            % Who knows what we will do in the future.
        end

        function val = get(obj,varargin)
            % Master function to return derived parameters of the recipe.
            % Many of these require some computation
            val = recipeGet(obj,varargin{:});
        end

        function [obj, val] = set(obj,varargin)
            % Master function to set the recipe parameters.
            [obj, val] = recipeSet(obj,varargin{:});
        end

        function oFile = save(thisR,varargin)
            % Save the recipe in a mat-file.
            % By default, save it as sceneName-recipe.mat  in the input
            % directory.
            %
            % recipe.save('recipeFileName');

            if ~isempty(varargin)
                oFile = varargin{1};
            else
                oFile = thisR.get('input basename');
                oFile = sprintf('%s-recipe',oFile);

                oDir = thisR.get('input dir');
                oFile = fullfile(oDir,oFile);
            end

            save(oFile,'thisR');
        end

        function T = show(obj,varargin)
            %
            % thisR.show('assets) - Brings up a window
            % thisR.show('object materials') - Prints a table (returns T,
            %              too)
            %
            % Optional
            %   window - Shows the whole node tree
            %   node names
            %   object positions
            %   object sizes
            %   materials
            %   lights
            %   textures
            %   instances

            if isempty(varargin), showType = 'window';
            else,                 showType = varargin{1};
            end

            T = [];

            % We should probably use nodes and objects/assets distinctly
            switch ieParamFormat(showType)
                case {'window'}
                    % Brings up the window that you can click through
                    % showing all the nodes.
                    if isempty(obj.assets), disp('No assets in this recipe');
                    else, obj.assets.show;
                    end
                case {'nodenames'}
                    % List all the nodes, not just the objects
                    names = obj.get('node names')';
                    rows = cell(numel(names),1);
                    for ii=1:numel(names), rows{ii} = sprintf('%d',ii); end
                    T = table(categorical(names),'VariableNames',{'assetName'}, 'RowNames',rows);
                    disp(T);
                case {'objects','assets'}
                    % Tabular summary of object materials, positions, sizes
                    %
                    % Should we be showing the instances of the objects
                    % also?
                    if isempty(obj.assets)
                        disp('No assets in this recipe.')
                        return;
                    end
                    indices = obj.get('objects');
                    names   = obj.get('object names no id')';
                    matT    = obj.get('object materials');
                    coords  = obj.get('object coordinates');
                    oSizes  = obj.get('object sizes');
                    
                    % When there are ObjectInstances, we have multiple
                    % objects with the same name. We remove the duplicates
                    % before displaying in the table. 
                    [uNames,idx] = unique(names);
                    if ~isequal(numel(names),numel(uNames))                        
                        names    = uNames;
                        indices  = indices(idx);
                        matT     = matT(idx);
                        coords   = coords(idx,:);
                        oSizes   = oSizes(idx,:);
                        % unique() returns a different order. We return to
                        % the ordering by indices
                        [indices,ia] = sort(indices);
                        names = names(ia); matT = matT(ia);
                        coords = coords(ia,:); oSizes = oSizes(ia,:);
                    end

                    positionT = cell(size(names));
                    sizeT = cell(size(names));
                    for ii=1:numel(names), positionT{ii} = sprintf('%.2f %.2f %.2f',coords(ii,1), coords(ii,2),coords(ii,3)); end
                    for ii=1:numel(names), sizeT{ii} = sprintf('%.2f %.2f %.2f',oSizes(ii,1), oSizes(ii,2),oSizes(ii,3)); end
                    T = table(indices(:), matT, positionT, sizeT,...
                        'VariableNames',{'index','material','positions (m)','sizes (m)'}, ...
                        'RowNames',names);
                    
                    % Start printing
                    fprintf('\n----- Summary of recipe: %s\n\n',obj.get('name'));
                    disp(T);
                    fprintf('From [%.2f, %2f, %2f] to [%.2f, %2f, %2f] up [%.2f, %2f, %2f]\n',...
                        obj.get('from'), obj.get('to'), obj.get('up'));

                case {'objectpositions','objectposition','assetpositions','assetspositions'}
                    % Print out the positions
                    names = obj.get('object names')';
                    coords = obj.get('object coordinates');
                    positionT = cell(size(names));
                    for ii=1:numel(names), positionT{ii} = sprintf('%.2f %.2f %.2f',coords(ii,1), coords(ii,2),coords(ii,3)); end
                    T = table(positionT,'VariableNames',{'positions (m)'}, 'RowNames',names);
                    disp(T);
                case {'objectsizes','assetsizes','objectsize'}
                    names = obj.get('object names')';
                    sizeT = cell(size(names));
                    oSizes = obj.get('object sizes');
                    for ii=1:numel(names), sizeT{ii} = sprintf('%.2f %.2f %.2f',oSizes(ii,1), oSizes(ii,2),oSizes(ii,3)); end
                    T = table(sizeT,'VariableNames',{'sizes (m)'}, 'RowNames',names);
                    disp(T);
                case {'instances'}
                    % Show the objects and the corresponding
                    % instances.
                    ids = obj.get('instances')';
                    sizeT = cell(size(ids));
                    names = cell(numel(ids),1);
                    for ii=1:numel(ids)
                        names{ii} = obj.get('node',ids(ii),'name'); 
                        % names{ii} = names{ii}(10:end); 
                    end
                    T = table(sizeT,'VariableNames',{'sizes (m)'}, 'RowNames',names);
                    disp(T);
                case 'materials'
                    % Prints a table
                    piMaterialPrint(obj);
                case 'lights'
                    % Prints a table of light parameters
                    piLightPrint(obj);
                case 'textures'
                    piTexturePrint(obj);
                case 'skymap'
                    % Brings up image of the skymap (global
                    % illumination)
                    lNames = obj.get('light','names');
                    nLights = numel(lNames);
                    for ii=1:nLights
                        if isequal(obj.get('light',lNames{ii},'type'),'infinite')
                            mapname = obj.get('light',lNames{ii},'filename');
                            if ~isempty(mapname)
                                mapname = fullfile(obj.get('outputdir'),mapname);
                                img = exrread(mapname);
                                ieNewGraphWin;
                                img = abs(img .^0.6);
                                imagesc(img);
                                [~,str,ext] = fileparts(mapname);
                                title([str,ext]); axis image; axis off
                            end
                        end
                    end
                case {'textures'}
                    tNames = obj.get('textures','names');
                    if isempty(tNames)
                        disp('No textures in this recipe.');
                    else
                        disp('Textures:  NYI');
                    end

                otherwise
                    error('Unknown show %s\n',varargin{1});
            end

        end
    end

end
