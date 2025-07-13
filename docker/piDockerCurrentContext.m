function currentContext = piDockerCurrentContext()
% piDockerCurrentContext Returns the name of the currently active Docker context.
%
%   This function executes 'docker context ls' and parses the output
%   to find the context marked with an asterisk (*).
%
% See also
%   isetdocker.render, isetdocker.startPBRT
%

% Execute the docker context ls command
[status, cmdout] = system('docker context ls');

% Check if the command executed successfully
if status ~= 0
    error('Docker command failed with status %d:\n%s', status, cmdout);
end

% Split the output into lines
lines = strsplit(cmdout, '\n');

% Iterate through each line to find the one with the asterisk
currentContext = '';
for i = 1:length(lines)
    line = strtrim(lines{i}); % Remove leading/trailing whitespace

    % Look for lines containing '*' (which denotes the active context)
    if contains(line, '*')
        % Split the line by whitespace
        parts = strsplit(line, ' ');

        % The context name is typically the first non-empty part
        for j = 1:length(parts)
            if ~isempty(parts{j})
                currentContext = parts{j};
                break; % Found the context name
            end
        end

        if ~isempty(currentContext)
            break; % Found the active context line and name
        end
    end
end

if isempty(currentContext)
    warning('Could not determine the current Docker context. No active context found.');
    % You might want to throw an error here instead, depending on your needs
end

end