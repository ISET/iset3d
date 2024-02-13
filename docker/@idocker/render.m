function output = render(obj, command)
% Run a Docker command remotely using Docker context
dockerCmd = ['docker ' command];
[status, cmdout] = system(dockerCmd);
if status == 0
    disp('Docker command executed successfully.');
    output = cmdout;
else
    disp('Error executing Docker command.');
    output = '';
end
end
