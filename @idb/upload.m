function [status,out] = upload(localpath,remotedir)
% this function rsync the local data to a remote dir by default, and only
% updates the changed files if exists.

commandline = sprintf('rsync -avz --update %s %s',localpath,remotedir);

[status,out] = system(commandline);

if status
    error(out);
end

end

