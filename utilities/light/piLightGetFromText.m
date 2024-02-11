function [lightSources, lightTextRanges] = piLightGetFromText(intext, varargin)
% Read a light source struct based on the parameters in the recipe
%
% This routine only works for light sources that are exported from
% Cinema 4D.  It will not work in all cases.  We should fix that.
%
% Inputs
%   intext: Usually this is the thisR.world slot
%
% Optional key/val pairs
%   print info:   Printout the list of lights (default is true)
%
% Returns
%   lightSources:  Cell array of light source structures
%
% Zhenyi, SCIEN, 2019
% Zheng Lyu    , 2020, 2021
% See also
%   piLightDeleteWorld, piLightAddToWorld

% Examples
%{
%}

%% Parse inputs

varargin = ieParamFormat(varargin);
p  = inputParser;
p.addRequired('intext', @iscell);
p.addParameter('printinfo',true);

p.parse(intext, varargin{:});

%%   Find the indices of the lines the .world slot that are a LightSource

AttBegin  =  find(piContains(intext,'AttributeBegin'));
AttEnd    =  find(piContains(intext,'AttributeEnd'));

light     =  piContains(intext,'LightSource');
lightIdx  =  find(light);   % Find which lines have LightSource on them.

%%
nLights = sum(light);
lightSources = cell(1, nLights);
lightTextRanges = cell(1, nLights);
for ii = 1:nLights
    % Find the attributes sections of the input text from the World.
    %

    % Check if the light line falls in any range of AttBegin-AttEnd.
    % If yes, process the whole section. Otherwise, process that line.
    % This can lead to problems for the file having a lot of transforms
    % without grouping them by AttributeBegin/End.

    for jj = 1:numel(AttBegin)
        if lightIdx(ii) > AttBegin(jj) &&...
                lightIdx(ii) < AttEnd(jj)
            lightLines  = intext(AttBegin(jj):AttEnd(jj));
            lightTextRanges{ii} = [AttBegin(jj), AttEnd(jj)];
        end
    end
    if isempty(lightTextRanges{ii})
        lightLines  = intext(lightIdx(ii));
        lightTextRanges{ii} = lightIdx(ii);
    end

    % The txt below is derived from the intext stored in the
    % lightSources.line slot.
    if find(piContains(lightLines, 'AreaLightSource'))
        lightName = sprintf('#%d_Light_type:%s', ii, 'area');
        thisLightSource = piLightCreate(lightName, 'type', 'area');

        thisLine = lightLines{piContains(lightLines, 'AreaLightSource')};

        % Spectrum
        spec = piParameterGet(thisLine, 'L');
        thisLightSource = piLightSet(thisLightSource, 'spd val', spec);
        
        % Spectrum Scale
        specscale = piParameterGet(thisLine, 'float scale');
        thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);
        
        % Twosided
        twoside = piParameterGet(thisLine, 'bool twosided');
        if twoside
            if strcmp(twoside, 'false')
                thisLightSource = piLightSet(thisLightSource, 'twosided val', false);
            else
                thisLightSource = piLightSet(thisLightSource, 'twosided val', true);
            end
        end

        % n samples
        nSamples = piParameterGet(thisLine, 'integer nsamples');
        thisLightSource = piLightSet(thisLightSource, 'nsamples val', nSamples);

        % spread angle
        spread = piParameterGet(thisLine, 'float spread');
        thisLightSource = piLightSet(thisLightSource, 'spread val', spread);
    else
        % Assign type
        lightType = lightLines{piContains(lightLines,'LightSource')};
        lightType = strsplit(lightType, ' ');
        lightType = lightType{2}(2:end-1); % Remove the quote mark
        lightName = sprintf('#%d_Light_type:%s', ii, lightType);
        thisLightSource = piLightCreate(lightName, 'type', lightType);

        if any(piContains(lightLines, 'CoordSysTransform "camera"'))
            thisLightSource = piLightSet(thisLightSource, 'cameracoordinate', true);
        end

        % Find the line that defines the LightSource
        thisLine = lightLines{piContains(lightLines, 'LightSource')};
        switch lightType
            case 'infinite'
                % Spectrum
                spec = piParameterGet(thisLine, 'L');
                if piContains(thisLine, 'blackbody') || numel(spec)==1
                    spec = spec(1);
                    thisLightSource.spd.type = 'blackbody';
                end
                
                thisLightSource = piLightSet(thisLightSource, 'spd val', spec);

                % Spectrum Scale
                specscale = piParameterGet(thisLine, 'float scale');
                thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);

                % n samples
                nsamples = piParameterGet(thisLine, 'integer nsamples');
                thisLightSource = piLightSet(thisLightSource, 'nsamples val', nsamples);

                % mapname -- in v4 seems to have changed to filename
                mapname = piParameterGet(thisLine, 'string filename');
                thisLightSource = piLightSet(thisLightSource, 'filename val', mapname);

            case 'spot'
                % Spectrum
                spec = piParameterGet(thisLine, 'I');
                thisLightSource = piLightSet(thisLightSource, 'spd val', spec);
                
                % Spectrum Scale
                specscale = piParameterGet(thisLine, 'float scale');
                thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);
                
                % from
                from = piParameterGet(thisLine, 'point3 from');
                if ~isempty(from)
                    thisLightSource = piLightSet(thisLightSource, 'from val', from);
                end
                % to
                to = piParameterGet(thisLine, 'point3 to');
                if ~isempty(to)
                    thisLightSource = piLightSet(thisLightSource, 'to val', to);
                end

                % cone angle
                coneangle = piParameterGet(thisLine, 'float coneangle');
                thisLightSource = piLightSet(thisLightSource, 'coneangle val', coneangle);

                % conedeltaangle
                conedeltaangle = piParameterGet(thisLine, 'float conedelataangle');
                thisLightSource = piLightSet(thisLightSource, 'conedeltaangle val', conedeltaangle);

            case 'point'
                % Spectrum
                spec = piParameterGet(thisLine, 'I');
                thisLightSource = piLightSet(thisLightSource, 'spd val', spec);
        
                % Spectrum Scale
                specscale = piParameterGet(thisLine, 'float scale');
                thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);
        
                % from
                from = piParameterGet(thisLine, 'point3 from');
                if ~isempty(from)
                    thisLightSource = piLightSet(thisLightSource, 'from val', from);
                end

            case 'goniometric'
                % Spectrum
                spec = piParameterGet(thisLine, 'I');
                thisLightSource = piLightSet(thisLightSource, 'spd val', spec);
                % Spectrum Scale
                specscale = piParameterGet(thisLine, 'float scale');
                thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);
                % mapname
                mapname = piParameterGet(thisLine, 'string filename');
                thisLightSource = piLightSet(thisLightSource, 'filename val', mapname);

            case 'distant'
                % Spectrum
                spec = piParameterGet(thisLine, 'L');
                thisLightSource = piLightSet(thisLightSource, 'spd val', spec);
                % Spectrum Scale
                specscale = piParameterGet(thisLine, 'float scale');
                thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);
                % from
                from = piParameterGet(thisLine, 'point3 from');
                if ~isempty(from)
                    thisLightSource = piLightSet(thisLightSource, 'from val', from);
                end 
                % to
                to = piParameterGet(thisLine, 'point3 to');
                if ~isempty(to)
                    thisLightSource = piLightSet(thisLightSource, 'to val', to);
                end

            case 'projection'
                % Spectrum
                spec = piParameterGet(thisLine, 'I');
                thisLightSource = piLightSet(thisLightSource, 'spd val', spec);
                % Spectrum Scale
                specscale = piParameterGet(thisLine, 'float scale');
                thisLightSource = piLightSet(thisLightSource, 'specscale', specscale);
                % FOV
                fov = piParameterGet(thisLine, 'float fov');
                thisLightSource = piLightSet(thisLightSource, 'fov val', fov);

                % mapname
                mapname = piParameterGet(thisLine, 'string filename');
                thisLightSource = piLightSet(thisLightSource, 'filename val', mapname);
        end
    end

    % For the lines after the AttributeBegin
    for kk = 2:numel(lightLines)-1
        thisLine = lightLines{kk};
        %{
        % Zheng: To check with Zhenyi - do we need all rot, position and
        % ctform?
        % Parse ConcatTransform
        concatTrans = find(piContains(thisLine, 'ConcatTransform'));
        if concatTrans
            [rotation, translation, ctform] = piParseConcatTransform(thisLine);
            curRotation = piLightGet(thisLightSource, 'rotation val');
            curRotation{end + 1} = rotation;
            curTrans = piLightGet(thisLightSource, 'translation val');
            curTrans{end + 1} = translation;
            thisLightSource = piLightSet(thisLightSource, 'rotation val', curRotation);
            thisLightSource = piLightSet(thisLightSource, 'translation val', curTrans);
            % thisLightSource = piLightSet(thisLightSource, 'ctform val', ctform);
        end

        % Parse rotation
        rot = find(piContains(thisLine, 'Rotate'));
        if rot
            [~, rotation] = piParseVector(thisLine);
            curRotation = piLightGet(thisLightSource, 'rotation val');
            curRotation{end + 1} = rotation;
            thisLightSource = piLightSet(thisLightSource, 'rotation val', curRotation);
        end

        % Look up translation
        tran = find(piContains(thisLine, 'Translate'));
        if tran
            [~, translation] = piParseVector(thisLine);
            curTrans = piLightGet(thisLightSource, 'translation val');
            curTrans{end + 1} = translation;
            thisLightSource = piLightSet(thisLightSource, 'translation val', curTrans);
        end
        
        % Look up scale
        scl = find(piContains(thisLine, 'Scale'));
        if scl
            [~, scle] = piParseVector(thisLine);
            curScale = piLightGet(thisLightSource, 'scale val');
            curScale{end + 1} = scle;
            thisLightSource = piLightSet(thisLightSource, 'scale val', curScale);
        end
        %}

        % Parse shape. Two possible cases: geometry is defined inline or
        % included in another file
        shp = find(piContains(thisLine, 'Shape'));
        if shp
            shape = piParseShape(thisLine);
            thisLightSource = piLightSet(thisLightSource, 'shape val', shape);
        end
        % Look up Include geometry line
        geo = find(piContains(thisLine, 'Include'));
        if geo
            geometryFname = erase(thisLine,{'Include "','"'});
            [~, n, ~] = fileparts(geometryFname);
            fname = which([n, '.pbrt']);
            if exist(fname, 'file')
                fileID = fopen(fname);
                tmp = textscan(fileID,'%s','Delimiter','\n');
                geometryLines = tmp{1};
                fclose(fileID);

                % convert geometryLines into from the standard block indented format in
                % to the single line format.
                geometryLinesFormatted = piFormatConvert(geometryLines);

                % There should be only one line for the actual geometry,
                % others might be comments.
                for gg = 1:numel(geometryLinesFormatted)
                    if ~isequal(geometryLinesFormatted{gg}(1), '#')
                        shape = piParseShape(geometryLinesFormatted{gg});
                    end
                end
                thisLightSource = piLightSet(thisLightSource, 'shape val', shape);
            else
                error('Geometry file: %s does not exist or is not added in path', [n, '.pbrt'])
            end
        end



        scl = find(piContains(thisLine, 'CoordSysTransform'));
        if scl
            % What should we do?  Perhaps this is not enough.
            if piContains(thisLine,'camera')
                thisLightSource = piLightSet(thisLightSource, 'cameracoordinate', true);
            end
        end

    end

    lightSources{ii} = thisLightSource;
end

%%
if p.Results.printinfo
    disp('---------------------')
    disp('*****Light Type******')
    for ii = 1:length(lightSources)
        fprintf('%d: name: %s     type: %s\n', ii,lightSources{ii}.name,lightSources{ii}.type);
    end
    disp('*********************')
    disp('---------------------')
end


end
