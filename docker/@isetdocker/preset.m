function preset(obj, presetName, varargin)
% Store the default parameters for one of our presets
%
%
% See also
%   isetdocker

%%
presetName = ieParamFormat(presetName);

validNames = {'localgpu','localgpu-alt','remotemux','remotemux-0','remotemux-1','remoteorange','remoteorange-0', ...,
    'remoteorange-1','humaneye', 'remotecnidl','orange-cpu'};
if ~ismember(presetName,validNames)
    disp('Valid Names (allowing for ieParamFormat): ')
    disp(validNames);
    error('%s not in valid set %s\n',presetName);
end

switch presetName
    case {'humaneye', 'orange-cpu'}
        obj.dockerImage = 'digitalprodev/pbrt-v4-cpu';
        obj.device = 'cpu';
        if isequal(presetName,'orange-cpu')
            obj.renderContext =  'remote-orange';
            obj.remoteHost = 'orange.stanford.edu';
        end
        % for use on Linux servers with their own GPU
    case {'localgpu', 'localgpu-alt'}
        % Render locally on Fastest GPU
        obj.device = 'gpu';
        obj.remoteHost = '';
        obj.remoteUser = '';
        obj.renderContext = 'default';

        % Different machines have diffrent GPU configurations
        [status, host] = system('hostname');
        if status, disp(status); end

        host = strtrim(host); % trim trailing spaces
        switch host
            case 'orange'
                obj.dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
                switch presetName
                    case 'localgpu'
                        obj.deviceID = 1;
                    case 'localgpu-alt'
                        obj.deviceID = 0;
                end
            case {'mux', 'muxreconrt'}
                obj.dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
                switch presetName
                    case 'localgpu'
                        obj.deviceID = 0;
                    case 'localgpu-alt'
                        obj.deviceID = 1;
                end
            otherwise
                obj.deviceID=-1;
        end

    case {'remotemux', 'remoteorange', 'remoteorange-0', 'remoteorange-1','remotemux-0','remotemux-1', 'remotecnidl'}
        % Render remotely on GPU
        obj.device = 'gpu';

        % pick the correct context
        switch presetName
            case {'remotemux', 'remotemux-0','remotemux-1'}
                obj.renderContext = 'remote-mux';
                obj.remoteHost = 'mux.stanford.edu';
            case {'remoteorange', 'remoteorange-0','remoteorange-1'}
                obj.renderContext =  'remote-orange';
                obj.remoteHost = 'orange.stanford.edu';
            case {'remote-cnidl'}
                obj.renderContext = 'remote-cnidl';
                obj.remoteHost = 'cni-dl.stanford.edu';
        end

        % also pick GPU and docker image
        switch presetName
            case {'remotemux','remotemux-0'}
                obj.dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-mux';
                obj.deviceID = 0;
            case 'remotemux-1'
                obj.dockerImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
                obj.deviceID = 1;
            case {'remoteorange','remoteorange-1'}
                obj.dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
                obj.deviceID = 1;
            case 'remoteorange-0'
                obj.dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
                obj.deviceID = 0;
            case 'remotecnidl'
                obj.dockerImage = 'camerasimulation/pbrt-v4-gpu-ampere-cnidl';
                obj.deviceID = 9; % pick the last one for now
        end

    otherwise
        validNames_str = string(validNames);
        validNames_str{end+1} = ' ';
        warning('Preset Name is not valid. Consider using these valid names: %s',strjoin(flip(validNames_str),'\n'));


end

setpref('ISETDocker','device',  obj.device);
setpref('ISETDocker','deviceID',obj.deviceID);
setpref('ISETDocker','dockerImage',  obj.dockerImage);
setpref('ISETDocker','remoteHost',  obj.remoteHost);
setpref('ISETDocker','remoteUser',  obj.remoteUser);
setpref('ISETDocker','renderContext',  obj.renderContext);

end







