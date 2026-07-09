function apertureIndex(obj,index)
% Set a surface subtype to 'diaphragm'  (not sure why not aperture)
%  
% Part of the lens class. This function is required to compute the Black
% Box Model. 
%
%  In this format, it creates the BBM with n_ob and n_im = 1
%     BBM = lens.set('aperture index', index)
%    
%  It is also possible to simply call the function
%      BBM = lens.apertureIndex(index)
%
%INPUT
%   obj: lens object of SCENE3D
%   index: specify the number of the surface which works as 'diaphrgam'
%   
%Example:
%     thisLens = lens; 
%     thisLens.set('aperture index',2);
%     thisLens.get('surface array',2)
%
% See also:  lens, surfaceC
%
% MP Vistasoft Team, Copyright 2014


%% CHECK FOR NUMERIC INPUT

if not(exist('index','var')) || not(isnumeric(index))
    error('Specify a numeric value for INDEX')
end

%% GET OLD SURFACE
surf = obj.get('surface array',index);

%% SET the SUBTYPE as 'diaphragm'
surf.set('subtype','diaphragm')

%% Append to lens structure
obj.set('surface array index',surf,index)

%% END
