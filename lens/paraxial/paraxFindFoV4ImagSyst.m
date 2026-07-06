% Find the Field of View in the object space for the given Imaging System


function [FoV,varargout]=paraxFindFoV4ImagSyst(ImagSyst,varargin)


%INPUT
%ImagSyst
%varargin  {1}: specify the distance to evaluate the field of view


%OUTPUT
%FoV: field of view at the given distance


%% SPECIFY or GET DISTANCE
if nargin>1
    vett_z=varargin{1}; 
else
    vett_log_z=[0:1:10]; %in unit
    vett_z=-10.^(vett_log_z); %in uni
end

%% INITIALIZE PARAMETER
unit=ImagSyst.unit;
profile='point'; %object modelled as point source
 y_obj=0; %eccentricity as height
%Create vector for eccentricity as angle
% vett_angle_ecc=[0:pi/100:pi/4];
% vett_angle_ecc=[0];

for zi=1:length(vett_z)       
        %Create object
        [Obj1]=paraxCreateObject(vett_z(zi),y_obj,profile,unit);
        %Add to the Imaging System
        [ImagSyst]=paraxAddObject2ImagSyst(ImagSyst,Obj1);
        for li=1:size(ImagSyst.wave,1)            
             FoV(:,zi)=(ImagSyst.object{end}.Radiance.FoV.obj_deg(:)); 
%              %EnP Position
%              EnP_pos(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.EnP.z_pos(li,:),2);
%              %ExP Position
%              ExP_pos(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.ExP.z_pos(li,:),2);
%              %EnW Position
%              EnW_pos(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.EnW.z_pos(li,:),2);
%              %ExW Position
%              Exw_pos(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.ExW.z_pos(li,:),2);
%              %Field of View
%              FoVobj(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.FoV.obj_deg(li,:),2);
%              FoVim(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.FoV.im_deg(li,:),2);
%              %Effective Fnumber
%              effFnum(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.Fnumber.eff(li,:),2);
%              idealFnum(yi,zi,li)=mean(ImagSyst.object{end}.Radiance.Fnumber.ideal(li,:),2);
        end  
end


%Set OUTPUT
varargout{1}=vett_z;
