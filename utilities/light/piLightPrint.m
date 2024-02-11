function [nLights,lightNames] = piLightPrint(thisR)
% Print a table of lights in the recipe
%
% Synopsis
%   [nLights,lightNames] = piLightPrint(thisR)
%
% To get information about light names or their IDs use
%
%   thisR.get('lights')
%   thisR.get('lights','names')
%   thisR.get('lights','names id')
%   thisR.get('light simple names')
%   val = thisR.get('light positions')
%
% For a single light, use
%
%   thisR.get('light',id,'name')
%   thisR.get('light',id,'name simple')
%   

% See also
%

nLights = thisR.get('n lights');
lightNames = {};

if nLights == 0
    disp('---------------------')
    disp('No lights in this recipe');
    disp('---------------------')
    return;
end

%% Initialize

% For the car scene in objectInstance there is a difference in the
% count of assets.mapLgtShort and assets.mapLgtFull ... That is a
% problem in building this table.
lightNames = thisR.get('light', 'names');
lightIDs   = thisR.get('light','ids');
specscale  = ones(nLights,1);

rows  = cell(nLights,1);
names = rows;
types = rows;
spdT  = rows;

positionT = rows;
position  = zeros(nLights,3);

%% Get data
fprintf('\nLights\n');
fprintf('-------------------------------\n');
for ii =1:numel(lightNames)
    thisLight = thisR.get('light', lightNames{ii}, 'lght');
    rows{ii, :} = num2str(ii);
    names{ii,:} = lightNames{ii};
    types{ii,:} = thisLight.type;
    if isfield(thisLight,'specscale') && ~isempty(thisLight.specscale.value)
        specscale(ii) = thisLight.specscale.value;
    end
    if isequal(thisLight.type,'distant') || isequal(thisLight.type,'infinite') 
        % These lights are infinitely far away.
        position(ii,:) = Inf;
    else
        % Is the camera coordinate logical set to true? Then the light
        % is at the camera.
        if isfield(thisLight,'cameracoordinate') && thisLight.cameracoordinate
            position(ii,:) = thisR.get('from');  % The camera position
        else
            % Different lights specify positions in different ways.
            switch thisLight.type
                case {'point','spot','projection','goniometric'}
                    position(ii,:) = thisR.get('lights',thisLight.name,'from');
                case {'area'}
                    position(ii,:) = thisR.get('assets',thisLight.name,'world position');
                case {'infinite','skymap','environment'}
                    position(ii,:) = [Inf,Inf,Inf];
                otherwise
                    error('Unknown light type %s.',thisLight.type);
            end
        end
    end

    % We have mapnames stored in spd or filenames in different cases
    % (e.g., default chess set light) 
    if ~isfield(thisLight,'filename') || isempty(thisLight.filename.value)
        spdT{ii} = num2str(thisLight.spd.value(:)');
    else
        spdT{ii} = thisLight.filename.value;
    end
end

%% Display the table

for ii=1:numel(names), positionT{ii} = num2str(position(ii,:)); end

T = table(lightIDs(:),categorical(names), categorical(types),positionT,spdT,specscale(:),'VariableNames',{'node id','name','type','position','spd/rgb','specscale'}, 'RowNames',rows);

disp(T);
fprintf('-------------------------------\n');

end
