function piPrefsInit
% If ISET3d pref is not set, we set them.
%
% See also
%  
if ~ispref('ISET3d') || ~ispref('ISET3d','wave')
    setpref('ISET3d','verbose',1);
    setpref('ISET3d','meanluminance',100);
    setpref('ISET3d','meanilluminance',10);
    setpref('ISET3d','wave', 400:10:700);
end

end