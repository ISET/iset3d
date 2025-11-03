function s = escapeShellArg(p)
% Minimal shell-arg escaping for POSIX shells
s = ['"' strrep(p, '"', '\"') '"'];
end