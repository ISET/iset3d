% HUMAN EYE MODELs


function [HumanImagingSyst,varargout]=paraxModelHumanEyeOptics(wave,type_model,varargin)

%INPUT
%wave: sampling wavelength of the system (column vector)
%type_model: 'model' choosen to describe the system

%OUTPUT
%HumanImagingSyst: Imaging System describing human eye optics features

n_ob=1;
n_im=1.336;
unit='mm';
%Pupil parameters
% pupil_posZ=2.75;
% pupil_diam=2;

switch type_model
    
    case {'FullGullstrand','fullgullstrand','FullGulls'}
        
        if nargin>2
            pupil_diam=varargin{1};
        else
            pupil_diam= 3; %3 mm pupil diameter [rest]
        end
               
        %RELAXED   Chapter 36-Human Eye- Handbook Optical System -pag 28
        Radius_rel=[7.7,6.8,10,7.911,-5.76,-6,-17.2];
        surf_type={'refr','refr','refr','refr','refr','refr','film'};
        surf_name={'cornea','ant chamber','front lens capsule','crystalline lens','rear lens capsule','vitreous humor','retina'};
        DistZ_rel=[0,0.5,3.1,0.546,2.419,0.635,17.185];
        for i=1:length(DistZ_rel)
            PosZ_rel(i)=sum(DistZ_rel(1:i));
        end
        Diam_rel=[11.5,11.5,9.5,9.5,9.5,20,20]; %diameter aperture
        N_rel=[1.376,1.336,1.386,1.406,1.386,1.336,1.336];
        N_rel=repmat(N_rel,size(wave,2),1);
        %build surfaces
        for k=1:(length(Radius_rel))
            R(k)=Radius_rel(k);
            z_pos(k)=PosZ_rel(k);
            n(:,k)=N_rel(:,k);
            diam(k)=Diam_rel(k);
            switch surf_type{k}
                case {'refr'}          
                    surf_rel{k}=paraxCreateSurface(z_pos(k),diam(k),unit,wave,surf_type{k},R(k),n(:,k));
                case {'diaphragm','diaph'}
                    surf_rel{k}=paraxCreateSurface(z_pos(k),diam(k),unit,wave,surf_type{k});
            end
            surf_rel{k}.name=surf_name{k}; % associate a name to the surface
        end
        %Iris
        pupil_posZ=PosZ_rel(3);

        surf_rel{(length(Radius_rel))}=paraxCreateSurface(pupil_posZ,pupil_diam,unit,wave,'diaphragm');        
        %Retina %to substitue with createFilm
         film.z_pos=PosZ_rel(end);film.R=Radius_rel(end);film.Diam=diam(end);
      
        %Create Optical System
        [OptSys.rel]=paraxCreateOptSyst(surf_rel,n_ob,n_im,unit,wave);
        
        %ACCOMODATED
        Radius_acc=[7.7,6.8,5.33,2.655,-2.655,-5.33,-17.2];
        surf_type={'refr','refr','refr','refr','refr','refr','film'};
        surf_name={'cornea','ant chamber','front lens capsule','crystalline lens','rear lens capsule','vitreous humor','retina'};
        DistZ_acc=[0,0.5,2.7,0.6725,2.655,0.6725,16.8];
        for i=1:length(DistZ_acc)
            PosZ_acc(i)=sum(DistZ_acc(1:i));
        end
        Diam_acc=[11.5,20,9.5,9.5,9.5,20,20]; %diameter aperture
        N_acc=[1.376,1.336,1.386,1.406,1.386,1.336,1.336];
        N_acc=repmat(N_acc,size(wave,2),1);
        %build surfaces
        for k=1:(length(Radius_acc))
            R(k)=Radius_acc(k);
            z_pos(k)=PosZ_acc(k);
            n(:,k)=N_acc(:,k);
            diam(k)=Diam_acc(k);
            switch surf_type{k}
                case {'refr'}          
                    surf_acc{k}=paraxCreateSurface(z_pos(k),diam(k),unit,wave,surf_type{k},R(k),n(:,k));
                case {'diaphragm','diaph'}
                    surf_acc{k}=paraxCreateSurface(z_pos(k),diam(k),unit,wave,surf_type{k});
            end
            surf_acc{k}.name=surf_name{k}; % associate a name to the surface
        end
        %Iris
        pupil_posZ=PosZ_acc(3);
        
       
        surf_acc{(length(Radius_rel))}=paraxCreateSurface(pupil_posZ,pupil_diam,unit,wave,'diaphragm');        
        %Retina %to substitue with createFilm
         film.z_pos=PosZ_rel(end);film.R=Radius_rel(end);film.Diam=diam(end);
      
        %Create Optical System
        [OptSys.acc]=paraxCreateOptSyst(surf_acc,n_ob,n_im,unit,wave);
        
        %SET OUTPUT
        HumanImagingSyst.relaxed=OptSys.rel;
        HumanImagingSyst.accomodated=OptSys.acc;
        HumanImagingSyst.film=film;
        
        
    case {'SchematicEye','Schematic Eye','Navarro'}
        warning('Code Missing!')
        none=[];


    
end