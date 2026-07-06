function [surface]=paraxCreateSurface(z_pos,diam,unit,wavelength,type,varargin)
% Create a Surface of the Optical System
%
%       [surface]=paraxCreateSurface(z_pos,diam,unit,wavelength,type,varargin)
%
%INPUT
% z_pos: position along the optical axis (z) of the surface
% diam: aperture diameter of the surface [unit]  in plane perpendicular tothe optical axis
% unit: unit witch referes to eache distance e.g. 'mm' ,'m'
% wavelength: (c.v) of the wavelength of refractive indices sampling in unit
% type: string refering the surface type
% varargin: depends on the surface type
%
%   'refractive':[ varargin{1}=radius of curvature (scalar), varargin{2}= refractive index after surface (c.v.),varargin{3}= abbe number , varargin{4}= aspherical profile]
%   'mirror':    [varargin{1}= radius of curvature (scalar)]
%   'plane':     [varargin{1}= refractive index beyond refraction(c.v.),varargin{2}=refractive index after surface (c.v.)]
%   'thinlens':  [varargin{1}=optical power (scalar,optical power [1/unit]); varargin{2}=refr. index before lens (cv);varargin{3}=refr. index after lens (cv);
%   'thicklens': [varargin{1}=radii of curvature [2x1] (first and second surface);varargin{2}=thickness [unit] ;varargin{3}=refr. index in the lens; varargin{4}=refr. index before lens (cv);varargin{5}=refr. index after lens (cv);%           
%   'GRIN':      [varigin{1}=string for the profile type('parabolic  n(r)=no(1-1/2*alfa^2*r^2)');varargin{2}= lens thickness; varargin{3}=(profile parameters(n0,alfa);varargin{4}=refr. index before lens (cv);varargin{5}=refr. index after lens (cv)]
%   'diaphragm': none
%
%OUTPUT
%surface: struct with the information needed for matrix formulation
%
% MP Vistasoft 2014

%c.v. =column vector for wavelenght dependence

%% TODO
%
% We should merge MP's larger notion of a surface into our surfaceC class.
% He has many types of surfaces, which we will account for using a subtype
% in the surface.
%

%% CHECK of PREREQUISITEs

%Wavelength is a column vector
if length(wavelength)>1 && size(wavelength,2)>1
    wavelength=wavelength';            
end


%% ASSIGN values at the Structure fields

switch  type
    case {'refractive','refr'}
        surface.unit=unit;
        surface.wave=wavelength;
        surface.z_pos=z_pos;
        surface.diam=diam;
        surface.type='refractive';
        surface.R=varargin{1}; %radius of curvature
        surface.N=checkNandWave(varargin{2},wavelength);
        if nargin>=8
            surface.abbeNumber=varargin{3}; %param for aspherical profile 
        else
            surface.abbeNumber=[];
        end
        if nargin>=9
            surface.k=varargin{4}; %param for aspherical profile 
        else
            surface.k=[];
        end
        
        
        
    case {'mirror','reflection', 'refl'}
        surface.unit=unit;
        surface.wave=wavelength;
        surface.z_pos=z_pos;        
        surface.diam=diam;
        surface.type='mirror';
        surface.R=varargin{1}; %radius of curvature
        if nargin>=7
            surface.abbeNumber=varargin{2}; %param for aspherical profile 
        end
         if nargin>=8
            surface.k=varargin{3}; %param for aspherical profile 
        else
            surface.k=[];
        end
    
    case {'plane','flat'}
        surface.unit=unit;
        surface.wave=wavelength;
        surface.z_pos=z_pos;        
        surface.diam=diam;
        surface.type='flat';
        surface.N=checkNandWave(varargin{2},wavelength);
        if nargin>=8
            surface.abbeNumber=varargin{3}; %param for aspherical profile 
        else
            surface.abbeNumber=[];
        end
        
    case {'thin','thinlens'}
        surface.unit=unit;
        surface.wave=wavelength;
        surface.z_pos=z_pos;
        surface.diam=diam;
        surface.type='thin';
        surface.optPower=varargin{1}; %[1/unit]
        %object space
        surface.N(:,1)=checkNandWave(varargin{2},wavelength);
        %image space
        surface.N(:,2)=checkNandWave(varargin{3},wavelength);
        if nargin>=9
            surface.abbeNumber=varargin{4}; %param for aspherical profile 
        else
            surface.abbeNumber=[];
        end
 

    case {'thick','thicklens'}
            surface.unit=unit;
            surface.wave=wavelength;
            surface.diam=diam;
            surface.z_pos=z_pos;
            surface.R=varargin{1}; %radius of curvature 
            surface.type='thick';            
            [optPower,f_im,f_ob,bfl,ffl]=paraxThickLens(varargin{1}(1),varargin{1}(2),varargin{2},varargin{3},varargin{4},varargin{5},wavelength);
            surface.th=varargin{2}; %thickness[unit]
            surface.optPower=optPower; % optical power [1/unit]
            surface.f_im=f_im; % focal length in image space [unit]
            surface.bfl_im=bfl; % back focal length in image space [unit]
            surface.f_ob=f_ob; % focal length in object space [unit]
            surface.ffl_ob=ffl; % forward focal length in object space [unit]
            %object space
            surface.N(:,1)=checkNandWave(varargin{4},wavelength);
            %image space
            surface.N(:,3)=checkNandWave(varargin{5},wavelength);
            %lens medium
            surface.N(:,2)=checkNandWave(varargin{3},wavelength);
             if nargin>=11
                surface.abbeNumber=varargin{6}; %param for aspherical profile 
            else
                surface.abbeNumber=[];
            end
            %DEBUG
%             a=1+(surface.th./surface.N(:,2)).*(surface.N(:,1)-surface.N(:,2))./varargin{1}(2);
%             b=surface.th./surface.N(:,2);
%             c=-surface.optPower;
%             d=1+(surface.th./surface.N(:,2)).*(surface.N(:,2)-surface.N(:,1))./varargin{1}(1);
%             surface.abcd=ones(2,2,size(wavelength,1));
%             surface.abcd(1,1,:)=a;surface.abcd(1,2,:)=b;surface.abcd(2,1,:)=c;surface.abcd(2,2,:)=d;
    
     case {'GRIN','GRINlens'} 
            surface.unit=unit;
            surface.wave=wavelength;
            surface.diam=diam;
            surface.z_pos=z_pos;
            surface.type='GRIN';
            surface.th=varargin{2};% thickness
            switch varargin{1}
                case {'parabolic','parab'}
                surface.profile.type='parabolic';
                surface.profile.n0=varargin{3}(:,1);
                surface.profile.alfa=varargin{3}(2);
            end
            %object space
            surface.N(:,1)=checkNandWave(varargin{4},wavelength);
            %image space
            surface.N(:,2)=checkNandWave(varargin{5},wavelength);
            if nargin>=11
                surface.abbeNumber=varargin{6}; %param for aspherical profile 
            else
                surface.abbeNumber=[];
            end
            
    case {'diaphragm','diaph','aperture','apert','stop'}
            surface.unit=unit;
            surface.wave=wavelength;
            surface.diam=diam;
            surface.z_pos=z_pos;
            surface.type='diaphragm';
end
        
%% SET Augmented parameter for not-centered surface
surface.augParam.Dy_dec=[];
surface.augParam.Du_tilt=[];