%% Compute the Special rays coordinates and direction on MERIDIONAL PLANE, such as
% chief ray (or principal ray), marginal rays(upper and lower), coma rays
% (upper and lower)


function [meridionalPlane]=paraxFindMeridionalSpecialRays(Object,cardPoints)

%INPUT
%Object: is a structure containing the following information
%       .z_pos: position of the object on the optical axis
%       .y_ecc: eccentricity on the meridional plane of the object
%       .Radiance.EnP (.diam: y-limits, .z_pos: position in the optical  axis)
%       .Radiance.ExP (.diam: y-limits, .z_pos: position in the optical  axis)
%       .Radiance.chromSTOP (describing if a different wavelength there is
%       a different Aperture Stop
%
%cardPoint: cardinal point for the given image system

%OUTPUT
%meridionalPlane: is a structure containin the following information
%        .chiefRay (.z0 and .y_0 for origin starting point, and . alfa and .alfaParax for angle [rad] )
%        .marginalRay. upper. (.z0 and .y_0 for origin starting point, and . alfa and .alfaParax for angle [rad] )
%        .marginalRay. lower. (.z0 and .y_0 for origin starting point, and . alfa and .alfaParax for angle [rad] )
%        .comaRay. upper. (.z0 and .y_0 for origin starting point, and . alfa and .alfaParax for angle [rad] )
%        .comaRay. lower. (.z0 and .y_0 for origin starting point, and . alfa and .alfaParax for angle [rad] )


if abs(Object.z_pos)<Inf
    % OBJECT at Finite Distance
    if isfield(Object,'Radiance')
        switch Object.Radiance.chromSTOP
            case {'constant','variable'}

                %ON AXIAL 
                %% Marginal rays (from on-axis position of object to both the edges of Entrance Pupils)
                %Upper limit ray
                EnP_Y_up=(Object.Radiance.EnP.diam(:,1)); %y_coord of the upper marginal ray
                EnP_DZ_up=Object.Radiance.EnP.z_pos(:,1)-Object.z_pos;%z_coord of the upper marginal ray
                EnP_alfaParax_up=(EnP_Y_up./EnP_DZ_up); % parax angle for upper marginal limit
                EnP_alfa_up=atan(EnP_Y_up./EnP_DZ_up); % angle for upper marginal limit        
                meridionalPlane.marginalRay.upper.z0=Object.z_pos; %on-Axis Z coord of point source
                meridionalPlane.marginalRay.upper.y0=zeros(size(Object.y_ecc,1),1); %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.marginalRay.upper.angle=EnP_alfa_up; %angle [rad] of the marginal ray
                meridionalPlane.marginalRay.upper.angleParax=EnP_alfaParax_up; %angle [rad] of the marginal ray in paraxial approx
                %Lower limit ray
                EnP_Y_low=(Object.Radiance.EnP.diam(:,2)); %y_coord of the lower marginal ray
                EnP_DZ_low=Object.Radiance.EnP.z_pos(:,2)-Object.z_pos;%z_coord of the lower marginal ray
                EnP_alfaParax_low=(EnP_Y_low./EnP_DZ_low); % parax angle for lower marginal limit
                EnP_alfa_low=atan(EnP_Y_low./EnP_DZ_low); % angle for lower marginal limit        
                meridionalPlane.marginalRay.lower.z0=Object.z_pos; %on-Axis Z coord of point source
                meridionalPlane.marginalRay.lower.y0=zeros(size(Object.y_ecc,1),1); %Y coord (eccentricity) of point source
                meridionalPlane.marginalRay.lower.angle=EnP_alfa_low; %angle [rad] of the marginal ray
                meridionalPlane.marginalRay.lower.angleParax=EnP_alfaParax_low; %angle [rad] of the marginal ray in paraxial approx

                %OFF AXIAL
                %% Coma rays (from off-axis position of object to both the edges of Entrance Pupils)
                %Upper coma ray
                EnP_Y_coma_up=(Object.Radiance.EnP.diam(:,1))-Object.y_ecc; %y_coord of the upper coma ray %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                EnP_DZ_coma_up=Object.Radiance.EnP.z_pos(:,1)-Object.z_pos;%z_coord of the upper coma ray
                EnP_alfaParax_coma_up=(EnP_Y_coma_up./EnP_DZ_coma_up); % parax angle for upper coma limit
                EnP_alfa_coma_up=atan(EnP_Y_coma_up./EnP_DZ_coma_up); % angle for upper coma limit        
                meridionalPlane.comaRay.upper.z0=Object.z_pos; %on-Axis Z coord of point source
                meridionalPlane.comaRay.upper.y0=Object.y_ecc; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.comaRay.upper.angle=EnP_alfa_coma_up; %angle [rad] of the coma ray
                meridionalPlane.comaRay.upper.angleParax=EnP_alfaParax_coma_up; %angle [rad] of the coma ray in paraxial approx
                %Lower coma ray
                EnP_Y_coma_low=(Object.Radiance.EnP.diam(:,2))-Object.y_ecc; %y_coord of the lower marginal ray %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                EnP_DZ_coma_low=Object.Radiance.EnP.z_pos(:,2)-Object.z_pos;%z_coord of the lower marginal ray
                EnP_alfaParax_coma_low=(EnP_Y_coma_low./EnP_DZ_coma_low); % parax angle for lower marginal limit
                EnP_alfa_coma_low=atan(EnP_Y_coma_low./EnP_DZ_coma_low); % angle for lower marginal limit        
                meridionalPlane.comaRay.lower.z0=Object.z_pos; %on-Axis Z coord of point source
                meridionalPlane.comaRay.lower.y0=Object.y_ecc; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.comaRay.lower.angle=EnP_alfa_coma_low; %angle [rad] of the coma ray
                meridionalPlane.comaRay.lower.angleParax=EnP_alfaParax_coma_low; %angle [rad] of the coma ray in paraxial approx

                %Chief ray (from off-axis position of object to center of Entrance Pupil)
                EnP_Ycenter= mean([(Object.Radiance.EnP.diam(:,1)),(Object.Radiance.EnP.diam(:,2))],2)-Object.y_ecc; %Center of the entrance pupil %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                EnP_DZpos=mean([Object.Radiance.EnP.z_pos(:,2),Object.Radiance.EnP.z_pos(:,1)],2)-Object.z_pos; %Distance form object point source to the center of the entrance pupil
                EnP_alfaParax=EnP_Ycenter./EnP_DZpos; % parax angle of the chief ray
                EnP_alfa=atan(EnP_Ycenter./EnP_DZpos); %angle of the chief ray

                meridionalPlane.chiefRay.z0=Object.z_pos; %Z coord of point source
                meridionalPlane.chiefRay.y0=Object.y_ecc; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.chiefRay.angle=EnP_alfa; %angle [rad] of the chief ray
                meridionalPlane.chiefRay.angleParax=EnP_alfaParax; %angle [rad] of the chief ray in paraxial approx

                %% Reference ray (from off-axis position of object to half angular aperture)

                % Chief and Reference rays  are differentiated to considere the
                % definition given in [Chapeter 8-  Canonical and Real-Space
                % Coordinates Used in the Theory of Image-H. H. HOPKINS] {Applied Optics and Optical Engineering Vol. IX}
                % Convention
                %Object Point P(zP,yP); EnP  Upper Edge U(zU,yU), Lower Edge
                %D(zD,yD); Reference Point  R(zR,yR); Upper ang aper(alfaU) UPR, Lower
                %ang aper (alfaL) RPD----->  sin(alfaU)=-sin(alfaD)

                % Relevant parameters            
                teta_CU=EnP_alfa_coma_up;teta_CL=EnP_alfa_coma_low;
                %Paraxial
                tetaR_parax=(teta_CU+teta_CL)/2; %mean

                %Non Paraxial
                A=sin(teta_CU);B=cos(teta_CU);C=sin(teta_CL);D=cos(teta_CL);
                T=(A+C)./(B+D);
                % zR is equal to the position of EnP edge for flat EnP
                EnP_DZR=Object.Radiance.EnP.z_pos(:,2)-Object.z_pos;
                yP=Object.y_ecc;
                yR=yP+EnP_DZR.*atan(T);
                tetaR=atan(T);

                meridionalPlane.referenceRay.z0=Object.z_pos; %Z coord of point source
                meridionalPlane.referenceRay.y0=Object.y_ecc; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.referenceRay.refPoint.yR=yR; %Y coord Reference Point on EnP 
                meridionalPlane.referenceRay.refPoint.zR=Object.Radiance.EnP.z_pos(:,2); %z coord Reference Point on EnP 
                meridionalPlane.referenceRay.angle=tetaR; %angle [rad] of the reference ray
                meridionalPlane.referenceRay.angleParax=tetaR_parax; %angle [rad] of the reference ray in paraxial approx




            otherwise
                warning (' Check the chromatic dependence of the pupils ')
        end
    else
        meridionalPlane=[];
        warning('The object has not been appended to an Imaging System!! Func Output is e')
    end
else
    %% CASE : Object at Infinity
    
    %To find Marginal, Chief rays and Coma usign Lagrange Invariance
    % Find SEMI- FIELD ANGLE
    if Object.u_ecc~=0
        semiFieldAngle=Object.u_ecc; %get input field angle
    else
        semiFieldAngle= Object.Radiance.FoV.obj_rad; %get system angular field of view
    end
    
    
    %get Entrance Pupil parameters
    EnP_posUp=Object.Radiance.EnP.z_pos(:,1);EnP_RadUp=Object.Radiance.EnP.diam(:,1);
    EnP_posLow=Object.Radiance.EnP.z_pos(:,2);EnP_RadLow=Object.Radiance.EnP.diam(:,2);
    EnP_posCenter=zeros(size(Object.Radiance.EnP.z_pos,1),1); %center of entrance pupil
    
    % Check if Entrance Pupil position is in object space or into the
    % optical system. In the later case, create a 'fake' Entrance pupil 
    % that can be used to find build the special rays
    
    %Chief Ray
    CR_posUp=EnP_posUp;CR_RadUp=semiFieldAngle;
    CR_posLow=EnP_posUp;CR_RadLow=semiFieldAngle;
    if semiFieldAngle>=0
        CR_pos=CR_posLow;
    else
        CR_pos=CR_posUp;
    end
    CR_Rad=EnP_posCenter;
    %and the angle
    if size(semiFieldAngle,1)~=size(EnP_posUp,1)
        semiFieldAngle=repmat(semiFieldAngle,size(EnP_posUp,1),1); %angle [rad] of the chief ray                              
    end
    CR_angle=semiFieldAngle;
    
    %Marginal Ray
    MR_posUp=EnP_posUp;MR_RadUp=EnP_RadUp; 
    MR_posLow=EnP_posLow;MR_RadLow=EnP_RadLow; 
    MR_angle=zeros(size(Object.Radiance.EnP.z_pos,1),1); %angle for Marginal Ray
    %Coma Ray
    ComR_posUp=EnP_posUp;ComR_RadUp=EnP_RadUp;
    ComR_posLow=EnP_posLow;ComR_RadLow=EnP_RadLow;
    ComR_angle=semiFieldAngle;
%     fakeEnP=0;
%     
%     for li=1:size(EnP_posUp,1)
%         %UPPER LIMITs
%         if (EnP_posUp(li,1)>cardPoints.lastVertex) && (fakeEnP)
%             deltaZ=EnP_posUp(li)-cardPoints.firstVertex;
%             %Marginal Ray
%             MR_posUp(li,1)=cardPoints.firstVertex-deltaZ;
%             MR_RadUp(li,1)=EnP_RadUp(li,1); %same height
%             %Coma Ray
%             ComR_posUp(li,1)=EnP_posUp(li,1)-2.*deltaZ;
%             ComR_RadUp(li,1)=EnP_RadUp(li,1)-2*deltaZ*tan(semiFieldAngle);
%             %Chief Ray
%             CR_posUp(li,1)=EnP_posUp(li,1)-2.*deltaZ;
%             CR_RadUp(li,1)=-2*deltaZ*tan(semiFieldAngle);
%         else
%             %Marginal Ray
%             MR_posUp(li,1)=EnP_posUp(li,1); MR_RadUp(li,1)=EnP_RadUp(li,1); 
%             %Coma Ray
%             ComR_posUp(li,1)=EnP_posUp(li,1);ComR_RadUp(li,1)=EnP_RadUp(li,1);
%             %Chief Ray
%             CR_posUp(li,1)=EnP_posUp(li,1);CR_RadUp(li,1)=EnP_posCenter(li,1);
%         end
%         %LOWER LIMITS
%         if (EnP_posLow(li,1)>cardPoints.lastVertex) && (fakeEnP)
%             deltaZ=EnP_posLow(li)-cardPoints.firstVertex;
%             %Marginal Ray
%             MR_posLow(li,1)=cardPoints.firstVertex-deltaZ;
%             MR_RadLow(li,1)=EnP_RadLow(li,1); %same height
%             %Coma Ray
%             ComR_posLow(li,1)=EnP_posLow(li,1)-2.*deltaZ;
%             ComR_RadLow(li,1)=EnP_RadLow(li,1)-2*deltaZ*tan(semiFieldAngle);
%             %Chief Ray
%             CR_posLow(li,1)=EnP_posLow(li,1)-2.*deltaZ;
%             CR_RadLow(li,1)=-2*deltaZ*tan(semiFieldAngle);
%         else
%             %Marginal Ray
%             MR_posLow(li,1)=EnP_posLow(li,1);MR_RadLow(li,1)=EnP_RadLow(li,1); 
%             %Coma Ray
%             ComR_posLow(li,1)=EnP_posUp(li,1);ComR_RadLow(li,1)=EnP_RadLow(li,1);
%             %Chief Ray
%             CR_posLow(li,1)=EnP_posLow(li,1);CR_RadLow(li,1)=EnP_posCenter(li,1);
%         end        
%     end
    % Set CR surce according to semiFieldAngle values
%     if semiFieldAngle>=0
%         CR_pos=CR_posLow;CR_Rad=CR_RadLow;
%     else
%         CR_pos=CR_posUp;CR_Rad=CR_RadUp;
%     end
    
    if isfield(Object,'Radiance')
        switch Object.Radiance.chromSTOP
            case {'constant','variable'}
                % CHECK ENTRANCE PUPIL POSITION:
                % for object at infinity che Ray can be considered starting
                % at Entrance Pupil Position. If EnP is after the first
                % surface of the optical system (NB EnP is the image of the
                % Aperture Stop, so can be placed 'everywhere').                
                %So, here we create a 'fake' source in the object space
                %spreading the rays which will reach the EnP with the
                %request directions and position
                               

                %ON AXIAL 
                %% Marginal rays (from on-axis position of object to both the edges of Entrance Pupils)
%                 %Upper limit ray
                meridionalPlane.marginalRay.upper.z0=MR_posUp; %on-Axis Z coord coincides with EnP for object at infinity
                meridionalPlane.marginalRay.upper.y0=MR_RadUp; %on-Axis Ycoord coincides with  the rim of EnP for object at infinity
                meridionalPlane.marginalRay.upper.angle=MR_angle; %marginal ray for object at infinity is ZERO
                meridionalPlane.marginalRay.upper.angleParax=MR_angle; %marginal ray for object at infinity is ZERO
                %Lower limit ray
%                 EnP_Y_low=(Object.Radiance.EnP.diam(:,2)); %y_coord of the lower marginal ray
                 meridionalPlane.marginalRay.lower.z0=MR_posLow; %on-Axis Z coord coincides with EnP for object at infinity
                meridionalPlane.marginalRay.lower.y0=MR_RadLow; %on-Axis Ycoord coincides with  the rim of EnP for object at infinity
                meridionalPlane.marginalRay.lower.angle=MR_angle; %marginal ray for object at infinity is ZERO
                meridionalPlane.marginalRay.lower.angleParax=MR_angle; %marginal ray for object at infinity is ZERO
                
                %OFF AXIAL
                %% Coma rays (from off-axis position of object to both the edges of Entrance Pupils)
                
                %Upper coma ray        
                meridionalPlane.comaRay.upper.z0=ComR_posUp; %on-Axis Z coord of point source
                meridionalPlane.comaRay.upper.y0=ComR_RadUp; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.comaRay.upper.angle=ComR_angle; %angle [rad] of the coma ray
                meridionalPlane.comaRay.upper.angleParax=ComR_angle; %angle [rad] of the coma ray in paraxial approx
                %Lower coma ray
                meridionalPlane.comaRay.lower.z0=ComR_posLow; %on-Axis Z coord of point source
                meridionalPlane.comaRay.lower.y0=ComR_RadLow; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.comaRay.lower.angle=ComR_angle; %angle [rad] of the coma ray
                meridionalPlane.comaRay.lower.angleParax=ComR_angle; %angle [rad] of the coma ray in paraxial approx

                %Chief ray (from off-axis position of object to center of Entrance Pupil)
                
                meridionalPlane.chiefRay.z0=CR_pos; %Z coord of point source
                meridionalPlane.chiefRay.y0=CR_Rad; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
%                 if size(semiFieldAngle,1)==size(EnP_posUp,1)
                meridionalPlane.chiefRay.angle=CR_angle; %angle [rad] of the chief ray
                meridionalPlane.chiefRay.angleParax=CR_angle; %angle [rad] of the chief ray in paraxial approx                
%                 else
%                     meridionalPlane.chiefRay.angle=repmat(semiFieldAngle,size(EnP_posUp,1),1); %angle [rad] of the chief ray
%                     meridionalPlane.chiefRay.angleParax=repmat(semiFieldAngle,size(EnP_posUp,1),1); %angle [rad] of the chief ray in paraxial approx                                  
%                 end

                %% Reference ray (from off-axis position of object to half angular aperture)

                % Chief and Reference rays  are differentiated to considere the
                % definition given in [Chapeter 8-  Canonical and Real-Space
                % Coordinates Used in the Theory of Image-H. H. HOPKINS] {Applied Optics and Optical Engineering Vol. IX}
                % Convention
                %Object Point P(zP,yP); EnP  Upper Edge U(zU,yU), Lower Edge
                %D(zD,yD); Reference Point  R(zR,yR); Upper ang aper(alfaU) UPR, Lower
                %ang aper (alfaL) RPD----->  sin(alfaU)=-sin(alfaD)
                
                
                %FOR OBJECT AT INFINITY REFERENCE RAY = CHIEF RAY

                % Relevant parameters            
                meridionalPlane.referenceRay.z0=meridionalPlane.chiefRay.z0; %Z coord of point source
                meridionalPlane.referenceRay.y0=meridionalPlane.chiefRay.y0; %Y coord (eccentricity) of point source %VALID FOR POINT SOURCE (not EXTENDED SOURCE)
                meridionalPlane.referenceRay.angle=meridionalPlane.chiefRay.angle; %angle [rad] of the reference ray
                meridionalPlane.referenceRay.angleParax=meridionalPlane.chiefRay.angleParax; %angle [rad] of the reference ray in paraxial approx




            otherwise
                warning (' Check the chromatic dependence of the pupils ')
        end
    else
        meridionalPlane=[];
        warning('The object has not been appended to an Imaging System!! Func Output is e')
    end
end
