%% Function: Create an object in the object space 


function [Obj]=paraxCreateObject(z_pos,y_ecc,profile,unit,varargin)

%INPUT
%z_pos: position along the optical axis (z) of the surface
%y_ecc: eccentricity from optical axis 
%profile: 'point','flat','spherical,'aspherical' and related  parameters specified in varargin
%unit: ofr z_pos,pixel_pitch
%varargin: depends on the film type
%           
%OUTPUT
%Obj: struct with the information about the Object



%% Append Value


Obj.unit=unit;
Obj.profile=profile;

if abs(z_pos)<Inf
    switch Obj.profile
        case {'point','point source'}
            %unique point source
            Obj.z_pos=z_pos;        
            Obj.y_ecc=y_ecc; 
            Obj.u_ecc=atan(y_ecc./z_pos); %angular eccentricity
        case {'flat','spherical'}
            %using varargin{...} specifying how to sample the plane source
%             warning('To be completed! It is considered as a Point Source')
            %%%%% then to be substitute and differenciated between flat and
            %%%%% spherical
            Obj.z_pos=z_pos;
            Obj.y_ecc=y_ecc;
            Obj.u_ecc=atan(y_ecc./z_pos); %angular eccentricity
            %____till here
        case {'spherical'}
    end
else
    switch Obj.profile
    case {'point','point source'}
            %unique point source
            Obj.z_pos=z_pos;        
            Obj.u_ecc=varargin{1}; %angular eccentricity
            Obj.y_ecc=NaN;
    case {'flat','spherical'}
        %using varargin{...} specifying how to sample the plane source
%         warning('To be completed! It is considered as a Point Source')
        %%%%% then to be substitute and differenciated between flat and
        %%%%% spherical
        Obj.z_pos=z_pos;
        Obj.y_ecc=NaN;
        Obj.u_ecc=varargin{1}; %angular eccentricity [vector]
        %____till here
        case {'spherical'}
    end
     
end
