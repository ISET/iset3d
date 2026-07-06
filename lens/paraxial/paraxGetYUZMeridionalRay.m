% Get the parameters of the imaging system required to estimate tha
% aberration for a given object (point source)


function [Ray]=paraxGetYUZMeridionalRay(object,wave,ray_type,angle_type,varargin)


%INPUT
%object:  structure describing the object which is imaged through the
%imaging system
%wave: sampling wavelength
%ray_type: ['default','chief','referencep]
% angle_type: type of angle to get and compute: [paraxial or real (non-paraxial)]
% varargin rays type  {1}  ray secondary parameters
%                      (case:marginal -upper,-lower)
%                      (case: zonal  number between[-1 +1], +1=upper marginal  0.5semi upper field   0   -0.5semi lower field   -1=lower marginal)
%                       (case:coma -upper,-lower)
%                       (case:coma zonal number between[-1 +1], +1=upper coma  0.5semi upper field   0   -0.5semi lower field   -1=lower coma)


%OUTPUT
%Ray:   .u: angle;
%       .y: eccentricity
%       .z:position


%NOTE: N: #sampling wavelength
%      M: #of surface




%% COMPUTE  transfer of CHIEF and MARGINAL Rays to the first surface of the system


switch ray_type
    
    case {'default';'chief';'Chief'}
        %Chief ray
        switch angle_type
            case {'parax';'paraxial'}
                Ray_u=object.meridionalPlane.chiefRay.angle; %angle
            case {'real';'non-approx';'non-paraxial'}
                 Ray_u=object.meridionalPlane.chiefRay.angleParax; %angle
            otherwise
                error('Not valid SELECTION of angle [paraxial/non-paraxial]')
        end
        Ray_y=object.meridionalPlane.chiefRay.y0; %eccentricity
        Ray_z=object.meridionalPlane.chiefRay.z0; %position
        
      
        
    case {'reference';'Reference'}  
        %Reference RAY is defined for CANONICAL COORDINATEs as the ray from OFF AXIS point which shows equal sine-angle distance from UPPER and LOWER COMA 
        % See Chapter 8-Theory of Image Formation
         
        switch angle_type
            case {'parax';'paraxial'}
                Ray_u=object.meridionalPlane.referenceRay.angle; %angle
            case {'real';'non-approx';'non-paraxial'}
                 Ray_u=object.meridionalPlane.referenceRay.angleParax; %angle
            otherwise
                error('Not valid SELECTION of angle [paraxial/non-paraxial]')
        end
        Ray_y=object.meridionalPlane.referenceRay.y0; %eccentricity
        Ray_z=object.meridionalPlane.referenceRay.z0; %position
        
        
    case {'marginal','Marginal'}
        % Marginal Ray
        %Check if it is available a preferece between upper and lower
        if nargin>4
            select_ray=varargin{1}; %selected ray            
        else
            [Ray_umax,Ray_in]=max([max(abs(object.meridionalPlane.marginalRay.upper.angleParax)),max(abs(object.meridionalPlane.marginalRay.lower.angleParax))]);
            if Ray_in==1
                select_ray='upper';
            elseif Ray_in==2
                select_ray='lower';
            else
                error ('Not valid marginal ray is present for the selected object!')
            end
        end
        %Get the Special ray
        switch select_ray
            case {'upper';'Upper';'Up';'up'}
                RayStruct=object.meridionalPlane.marginalRay.upper; %upper marginal ray
            case {'lower';'Lower';'Low';'low'}
                RayStruct=object.meridionalPlane.marginalRay.lower; %lower marginal ray      
            otherwise
                
        end
         %Get the Special Ray parameter
         Ray_y=RayStruct.y0;Ray_z=RayStruct.z0; %position
        switch angle_type
            case {'parax';'paraxial'}
                Ray_u=RayStruct.angleParax; %angle
            case {'real';'non-approx';'non-paraxial'}
                 Ray_u=RayStruct.angle; %angle
            otherwise
                error('Not valid SELECTION of angle [paraxial/non-paraxial]')
        end

    case{'zonal';'Zonal';'zonals';'Zonals'}
        % Zonal Ray
        %Check if it is available a preferece between upper and lower
        if nargin>4
            relFieldAngle=varargin{1}; %relative Field Angle
        else
            error ('For a Zonal Ray the relative field angle has to be specifyed, range [1 -1]!!')
        end        
        %Get the Special ray
        if relFieldAngle==0
            % It is the OPTICAL AXIS
            RayStruct.angleParax=zeros(size(wave,1),1);
            RayStruct.angle=zeros(size(wave,1),1);
            RayStruct.z0=mean([object.meridionalPlane.marginalRay.upper.z0,object.meridionalPlane.marginalRay.lower.z0],2);            
            RayStruct.y0=zeros(size(wave,1),1); 
            
        elseif (relFieldAngle>0) && (relFieldAngle<=1)
            RayStruct=object.meridionalPlane.marginalRay.upper;
            RayStruct.angleParax=RayStruct.angleParax./relFieldAngle; %set angle to the given relative field
            RayStruct.angle=RayStruct.angle./relFieldAngle; %set angle to the given relative field
        elseif (relFieldAngle<0) && (relFieldAngle>=-1)
            RayStruct=object.meridionalPlane.marginalRay.lower;
            RayStruct.angleParax=RayStruct.angleParax./abs(relFieldAngle); %set angle to the given relative field
            RayStruct.angle=RayStruct.angle./abs(relFieldAngle); %set angle to the given relative field
        else
            error ('Not valid value for a zonal ray  relative field angle, range [1 -1]!!')
        end
        
         %Get the Special Ray parameter
         Ray_y=RayStruct.y0;Ray_z=RayStruct.z0; %position
        switch angle_type
            case {'parax';'paraxial'}
                Ray_u=RayStruct.angleParax; %angle
            case {'real';'non-approx';'non-paraxial'}
                 Ray_u=RayStruct.angle; %angle
            otherwise
                error('Not valid SELECTION of angle [paraxial/non-paraxial]')
        end
        
    case{'coma';'Coma'}
        % Coma Ray
        %Check if it is available a preferece between upper and lower
        if nargin>4
            select_ray=varargin{1}; %selected ray
        else
            [Ray_umax,Ray_in]=max([max(abs(object.meridionalPlane.comaRay.upper.angleParax)),max(abs(object.meridionalPlane.comaRay.lower.angleParax))]);
            if Ray_in==1
                select_ray='upper';
            elseif Ray_in==2
                select_ray='lower';
            else
                error ('Not valid marginal ray is present for the selected object!')
            end
        end
        %Get the Special ray
        switch select_ray
            case {'upper';'Upper';'Up';'up'}
                RayStruct=object.meridionalPlane.comaRay.upper; %upper coma ray
            case {'lower';'Lower';'Low';'low'}
                RayStruct=object.meridionalPlane.comeRay.lower; %lower coma ray
        end
         %Get the Special Ray parameter
         Ray_y=RayStruct.y0;Ray_z=RayStruct.z0; %position
        switch angle_type
            case {'parax';'paraxial'}
                Ray_u=RayStruct.angleParax; %angle
            case {'real';'non-approx';'non-paraxial'}
                 Ray_u=RayStruct.angle; %angle
            otherwise
                error('Not valid SELECTION of angle [paraxial/non-paraxial]')
        end
        
    case{'coma zonal';'Coma zonal'; 'Coma Zonal'}
        
        % Coma Zonal Ray
        %Check if it is available a preferece between upper and lower
        if nargin>4
            relFieldAngle=varargin{1}; %relative Field Angle
        else
            error ('For a Coma Zonal Ray the relative field angle has to be specifyed, range [1 -1]!!')
        end        
        %Get the Special ray
        if relFieldAngle==0
            % It is the OPTICAL AXIS
            RayStruct.angleParax=zeros(size(wave,1),1);
            RayStruct.angle=zeros(size(wave,1),1);
            RayStruct.z0=mean([object.meridionalPlane.comaRay.upper.z0,object.meridionalPlane.comaRay.lower.z0],2);            
            RayStruct.y0=zeros(size(wave,1),1); 
            
        elseif (relFieldAngle>0) && (relFieldAngle<=1)
            RayStruct=object.meridionalPlane.comaRay.upper;
            RayStruct.angleParax=RayStruct.angleParax./relFieldAngle; %set angle to the given relative field
            RayStruct.angle=RayStruct.angle./relFieldAngle; %set angle to the given relative field
        elseif (relFieldAngle<0) && (relFieldAngle>=-1)
            RayStruct=object.meridionalPlane.comaRay.lower;
            RayStruct.angleParax=RayStruct.angleParax./abs(relFieldAngle); %set angle to the given relative field
            RayStruct.angle=RayStruct.angle./abs(relFieldAngle); %set angle to the given relative field
        else
            error ('Not valid value for a zonal ray  relative field angle, range [1 -1]!!')
        end
        
         %Get the Special Ray parameter
         Ray_y=RayStruct.y0;Ray_z=RayStruct.z0; %position
        switch angle_type
            case {'parax';'paraxial'}
                Ray_u=RayStruct.angleParax; %angle
            case {'real';'non-approx';'non-paraxial'}
                 Ray_u=RayStruct.angle; %angle
            otherwise
                error('Not valid SELECTION of angle [paraxial/non-paraxial]')
        end
        
    otherwise
        error('Not valid selection for rays [marginal/zonal/coma/marginal-reference')
        
end


%% Check dimension of the output to be homogenoues with wavelengths
if not(size(Ray_y,1)==size(wave,1))
    Ray_y=repmat(Ray_y,size(wave,1)); % check element dimension
end
if not(size(Ray_y,1)==size(wave,1))
    Ray_y=repmat(Ray_y,size(wave,1)); % check element dimension
end

%% OUTPUT
Ray.y=Ray_y;Ray.u=Ray_u;Ray.z=Ray_z;




       