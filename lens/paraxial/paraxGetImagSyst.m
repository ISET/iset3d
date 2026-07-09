function [value]=paraxGetImagSyst(ImagSyst,pName,varargin)
% Function: get specific value from an Imaging  system
%
%    [value]=paraxGetImagSyst(syst,systType,pName)
%
%
%INPUT
%  ImagSyst: System structure [Optical System or Imaging System]
%  pName: specify which features to get
%  varargin:  in case of multiple choice (e.g. serveral films or point
%  source [object] specify which one, otherwise get the last one
%
%OUTPUT
%  value: 
%
%
% MP Vistasoft 2014


%% Which feature or field?
pName=ieParamFormat(pName);



%% SWITCH for CASE

switch pName
    case {'wave';'unit';'n_ob';'objectrefractiveindex'; 'objrefrindex';'objectspacerefractiveindex';...
            'n_im';'imagerefractiveindex'; 'imrefrindex';'imagespacerefractiveindex';'surforder'; ...
            'surflist';...
            'abcdmatrix';'abcd';'abcdmatrixreduced';'abcdreduced';'abcdmatrixred';'abcdred';...
            'firstvertex';'lastvertex';'cardinalpoints';'cardpoint';'effectivefocallength';'efl';...
            'imagefocallength';'objectfocallength';'focalradius';'petzval';'petzvalradius';...
            'focalpoint';'imagefocalpoint';'objectfocalpoint';'principalpoint';'imageprincipalpoint';...
            'objectprincipalpoint';'objprincipalpoint';'nodalpoint';'imagenodalpoint';...
            'objectnodalpoint';'objnodalpoint';'entrancepupils';'enps';'exitpupils';'exps'}  % Possible Exit Pupils
        % These fields are in common to the Optical System    
        [value]=paraxGetOptSyst(ImagSyst,pName);
         % Image formation     
    case {'numericalaperture';'numapert';'numaperture';'na'}
        value=ImagSyst.imageFormation.NA; % numerical aperure 
    case {'fieldofview';'FoV';'fov'}
        value=ImagSyst.imageFormation.FoV; % field of view
    
    case {'primaryaberration';'seidelaberration';'4thorderwaveaberration'}
        value=ImagSyst.aberration.paCoeff; % primary aberration
    case {'defocus'}
        value=ImagSyst.aberration.defocusCoeff; % defocus coeff for aberration
        
    %% Object (Point Source} and related features [image point]    
    case {'pointsource';'psource';'object';'obj'}
        if nargin>2
            ind=varargin{1};
            value=ImagSyst.object{ind};
        else
            value=ImagSyst.object{end};
        end
     case {'fnumber';'fnum';'f-num';'effectivef-number';'efffnumber'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');
        end   
        value=obj.Radiance.Fnumber.eff; %effective f-number
     case {'fieldofview';'FoV';'fov'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');
        end   
        value=obj.Radiance.FoV; % field of view
        
        
     case {'idealfnumber';'idealfnum';'idealf-num'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');
        end   
        value=obj.Radiance.Fnumber.ideal; %effective f-number
        
     case {'gaussianimagepoint';'gaussianpoint';'gausspoint';'imagepoint'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');
        end   
        value=obj.ConjGauss; 
        
      case {'imagepointposition';'imageposition';'imagepos';'imagepointpos'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'imagepoint',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'imagepoint');
        end   
        value=obj.z_im;
      
    case {'imagepointheight';'imageheight';'imageh';'imagepointheight'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'imagepoint',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'imagepoint');
        end   
        value=obj.y_im;
    case {'imagepointmagnification';'imagemagnification';'imagemagn';'imagepointmagn'}
        if nargin>2
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'imagepoint',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'imagepoint');
        end   
        value=obj.m_lat;
          
    %% PUPILS    
    case {'pupils'}  % Possible  Pupils
        value=ImagSyst.Pupils;
        
    % Entrance pupil
     case {'entrancepupil';'enp';'entrancep'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object'); 
         end
        value=obj.Radiance.ExP; % entrance pupil
     case {'entrancepupilposition';'enppos';'entrancepupilpos'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'entrancepupil',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'entrancepupil');   
         end
        value=obj.z_pos; % entrance pupil
    case {'entrancepupildiameter';'enpdiam';'entrancepupildiam'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'entrancepupil',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'entrancepupil');
         end
        value=obj.diam; % entrance pupil
    % Exit pupil
     case {'exitpupil';'exp';'exitp'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');   
         end
        value=obj.Radiance.ExP; % exit pupil
     case {'exitpupilposition';'exppos';'exitpupilpos'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'exitpupil',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'exitpupil'); 
         end
        value=obj.z_pos; % exit pupil
    case {'exitpupildiameter';'expdiam';'exitpupildiam'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'exitpupil',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'exitpupil');  
         end
        value=obj.diam; % exit pupil
        
    %% WINDOWS
    % Entrance window
     case {'entrancewindow';'enw';'entrancew'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');  
         end
        value=obj.Radiance.ExP; % entrance pupil
     case {'entrancewindowposition';'enwpos';'entrancewindowpos'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'entrancewindow',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'entrancewindow');  
         end
        value=obj.z_pos; % entrance pupil
    case {'entrancewindowdiameter';'enwdiam';'entrancewindowdiam'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'entrancewindow',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'entrancewindow'); 
         end
        value=obj.diam; % entrance pupil
    % Exit window
     case {'exitwindow';'exw';'exitw'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'object',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'object');   
         end
        value=obj.Radiance.ExP; % exit pupil
     case {'exitwindowposition';'exwpos';'exitwindowpos'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'exitwindow',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'exitwindow'); 
         end
        value=obj.z_pos; % exit pupil
    case {'exitwindowdiameter';'exwdiam';'exitwindowdiam'}
         if nargin>2 % Which object?
            ind=varargin{1};
            obj=paraxGetImagSyst(ImagSyst,'exitwindow',ind);
        else
            obj=paraxGetImagSyst(ImagSyst,'exitwindow');      
         end
        value=obj.diam; % exit pupil
    
        
        %% FILM and related feature
    case{'film'}
        if nargin>2
            ind=varargin{1};
            value=ImagSyst.film{ind};
        else
            value=ImagSyst.film{end};
        end
    case{'filmposition';'filmpos'}
        if nargin>2
            ind=varargin{1};
            value=ImagSyst.film{ind}.z_pos;
        else
            value=ImagSyst.film{end}.z_pos;
        end          
     otherwise
        error(['Non valid: ',type,' as system type!'])
end