function [status, result] = gpuStatus(obj)
%GPUSTATUS check status of Nvidia GPU, if available
%
% Usage:
%   <dockerObject>.gpuStatus();
%
%   January 2022 David Cardinal Stanford University

    if obj.gpuRendering == false
        status = -1;
        result = "This docker object does not use the GPU";
    elseif isempty(obj.remoteMachine)
        % check local GPU        
        [status, result] = system("nvidia-smi");
    else
        % check the remote machine
        rUser = obj.remoteUser;
        if isempty(rUser)
            % if not set try our current username
            rUser = obj.getUserName();
        end
        statusCmd = sprintf('ssh %s@%s nvidia-smi', rUser, obj.remoteMachine);
        [status, result] = system(statusCmd);
    end
    disp(result);

end

