function resourceFileName = piResourceFind(rType, rName)
%PIRESOURCEFind A unified way of finding resource files

%   Input --
%     rType -- Starting with Textures

resourceFileName = ''; % default to none
switch rType
    case 'texture'
        % For legacy, always check the iset3d texture folder:
        if exist(fullfile(piDirGet('textures'),rName),'file')
            resourceFileName = fullfile(piDirGet('textures'), rName);
            return
        end
                
        % Then check the user path (in case they want to over-ride)
        if (which(rName))
            resourceFileName = which(rName);
            return
        end

        % Then check our textures library


    otherwise
        warning("Resource type %s unknown\n", rType);
end

