function tf = isSymlink(p)
% Return true if p is a symbolic link (Unix/macOS).
% On Windows this returns false and we fall back to copyfile.
if ispc
    tf = false;
    return;
end
% test -L exits 0 if p is a symlink
[status, ~] = system(sprintf('test -L %s', escapeShellArg(p)));
tf = (status == 0);
end


