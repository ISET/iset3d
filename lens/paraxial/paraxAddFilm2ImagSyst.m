%% Add a film to an Imaging System


function [ImagSyst]=paraxAddFilm2ImagSyst(ImagSyst,Film,Zpos_film,augParam_Film,varargin)

% %INPUT
% %ImagSyst: Structures of the ImagSyst system
% %Film: Structures of the optical system
% %Zpos_film: position in [unit] where Film vertex is placed
% %augParam: [Dy_dec;%Du_tilt: tilting angle of the surface refered to the optical axis [radiant]]
% %optAxis: Structure describig the optical axis (TO BE INCLUDED)
% %varargin: 
% 
% %OUTPUT
% %ImagSyst: struct of the imagSyst with a new film
% 

if isfield(ImagSyst,'film')
    index=length(ImagSyst.film)+1;
else
    index=1;
end

if Zpos_film<=ImagSyst.surfs.list{ImagSyst.surfs.order(end)}.z_pos;
    error (['Film position is not physical possible, last System surface ',num2str(ImagSyst.surfs.list{ImagSyst.surfs.order(end)}.z_pos), ' and film position ',num2str(Zpos_film), 'mm'])
end


ImagSyst.film{index}.profile=Film.profile;
ImagSyst.film{index}.size_pixel=Film.size_pixel;
ImagSyst.film{index}.size_unit=Film.size_unit;
ImagSyst.film{index}.pixel_pitch=Film.size_unit./Film.size_pixel;
if isfield(Film,'mapX')
    ImagSyst.film{index}.map.X=Film.mapX;ImagSyst.film{1}.map.Y=Film.mapY;ImagSyst.film{1}.map.Z=Film.mapZ;
else
%     warning ('Film MESH  is not AVAILABLE!')
end




%compute abcd matrix from last vertex of the system to the film

switch ImagSyst.film{index}.profile
    
    case {'flat','plane'} %all pixel are at the same distance from the last vertex of the Optical System
        %Set position along the optical axis and (possibly) augmented parameter
        ImagSyst.film{index}.z_pos=Zpos_film;
        ImagSyst.film{index}.augParam=augParam_Film;
        %HERE
        %modify X,Y coordinate according to augmented parameter  and the film
        %orientation
        
        lV=paraxGet(ImagSyst,'lastvertex');
        th=ImagSyst.film{index}.z_pos-lV;
%         th=ImagSyst.film{index}.z_pos-ImagSyst.cardPoints.lastVertex;
        M_red=paraxComputeTranslationMatrix(th,ImagSyst.n_im,'reduced');
        M=paraxComputeTranslationMatrix(th,ImagSyst.n_im,'not-reduced');
        %with augmented parameter       
        M_aug_red(1:2,1:2,:)=M_red;
        M_aug(1:2,1:2,:)=M;
        %intermediate variables
        for n=1:size(ImagSyst.wave,1)            
            M_aug_red(1:2,3,n)=augParam_Film;
            M_aug(1,3,n)=augParam_Film(1);
            M_aug(2,3,n)=augParam_Film(2).*ImagSyst.n_im(n);
        end
        M_aug_red(3,1:2,:)=0;
        M_aug_red(3,3,:)=1;
        M_aug(3,1:2,:)=0;
        M_aug(3,3,:)=1;
        

    case {'spherical','sphere'} %all pixel are at difference distance from the last vertex of the Optical System
        warning ('This section has to be completed!! Missing spherical-dependent thickness') 
        %Set position along the optical axis and (possibly) augmented parameter
        ImagSyst.film{index}.z_pos=Zpos_film;
        ImagSyst.film{index}.augParam=augParam_Film;
        %HERE
        %modify X,Y coordinate according to augmented parameter  and the film
        %orientation
        %%%%%%
        lV=paraxGet(ImagSyst,'lastvertex');
        th=ImagSyst.film{index}.z_pos-lV;
%         th=ImagSyst.film{index}.z_pos-ImagSyst.cardPoints.lastVertex;
        M_red=paraxComputeTranslationMatrix(th,ImagSyst.n_im,'reduced');
        M=paraxComputeTranslationMatrix(th,ImagSyst.n_im,'not-reduced');
        %with augmented parameter       
        M_aug_red(1:2,1:2,:)=M_red;
        M_aug(1:2,1:2,:)=M;
        %intermediate variables
        for n=1:size(ImagSyst.wave,1)            
            M_aug_red(1:2,3,n)=augParam_Film;
            M_aug(1,3,n)=augParam_Film(1);
            M_aug(2,3,n)=augParam_Film(2).*ImagSyst.n_im(n);
        end
        M_aug_red(3,1:2,:)=0;
        M_aug_red(3,3,:)=1;
        M_aug(3,1:2,:)=0;
        M_aug(3,3,:)=1;
        %%%%%
    otherwise
        warning ('Not valid Film profile (e.g. plane, spherical,etc.')
        
end
%% Compute the images of the film  through the optical syst (called here as Entrance Pupil and Exit Pupil) needed later to estimate Field Stop of the System.

%Check Film position
indK=[];
for k=1:length(ImagSyst.surfs.order)
    if ImagSyst.film{index}.z_pos<=ImagSyst.surfs.list{ImagSyst.surfs.order(k)}.z_pos
        indK=[indK,k];
    end
    
end

%%  The image from the first side of the system (defines Entrance Pupil)


type_conj1='im2ob';
if isempty(indK)
    %distance Film-Optical System
    t_ob_film1=ImagSyst.film{index}.z_pos-ImagSyst.surfs.list{ImagSyst.surfs.order(end)}.z_pos; 
    [t_im_film1, m_lat_film1,m_ang_film1]= paraxConjImagingMatrix(ImagSyst,type_conj1,t_ob_film1);
else
    %distance Film-Optical System
    t_ob_film1=ImagSyst.film{index}.z_pos-ImagSyst.surfs.list{ImagSyst.surfs.order(indK(1)-1)}.z_pos; 
    %subsystem
    sub_index1=ImagSyst.surfs.order(1:indK(1)-1);
    %find refranctive index in the Sub-Space for SubSystem
    if sub_index1(1)==ImagSyst.surfs.order(1)
        n_ob1=ImagSyst.n_ob;
    else
        space_type='object';l=1;
        ind_obj1=find(ImagSyst.surfs.order==sub_index1(1));
        [n_ob1]=paraxFindN4SubSyst(ImagSyst,ind_obj1,l,space_type);
    end
    if sub_index1(end)==ImagSyst.surfs.order(end)
        n_im1=ImagSyst.n_im;
    else
        space_type='image';l=1;
        ind_im1=find(ImagSyst.surfs.order==sub_index(end));
        [n_im1]=paraxFindN4SubSyst(ImagSyst,ind_im1,l,space_type);
    end
    %Create Sub System
    [subOptSyst1]=paraxCreateSubSyst(ImagSyst,sub_index1,n_ob1,n_im1);
    %Image the film through the Sub System
    [t_im_film1, m_lat_film1,m_ang_film1]= paraxConjImagingMatrix(subOptSyst1,type_conj1,t_ob_film1);
end
% EnP position
z_im_film1=ImagSyst.surfs.list{ImagSyst.surfs.order(1)}.z_pos-t_im_film1;
% EnP dimension
% check if there is a relation to 'real world' coordinates and the
% coordinate used to rotattionally-symmetric system in parax approx

if isfield(ImagSyst,'realWorldTransf')
    %To complete when defined a way to move from relative coords to real
    %world coords
    %The augmented parameters ar used to take into account the possible
    %tilting (deltaU) and not-centering (deltaY_ecc)
%     warning ('For real world coordinates the code has to be COMPLETED!')
else
%     warning ('The radius of the circle inscribed in the film has been selected!')
    diam_film1= min(ImagSyst.film{index}.size_unit).*m_lat_film1.*cos(augParam_Film(2)); %smallest diameter tilted by deltaU
    diam_up1=diam_film1/2+augParam_Film(1); %upper limit
    diam_down1=-diam_film1/2+augParam_Film(1); %lower limit
end
%set output
ImagSyst.film{index}.Pupils.EnP.z_pos=z_im_film1;
ImagSyst.film{index}.Pupils.EnP.m_lat=m_lat_film1;
ImagSyst.film{index}.Pupils.EnP.diam(:,1)=diam_up1;
ImagSyst.film{index}.Pupils.EnP.diam(:,2)=diam_down1;

%% The image from the last side of the system (defines Exit Pupil)
type_conj2='ob2im';
if isempty(indK) 
    %distance Film-Optical System
    t_ob_film2=0;t_im_film2=ImagSyst.film{index}.z_pos-ImagSyst.surfs.list{ImagSyst.surfs.order(end)}.z_pos;
    m_lat_film2=1;m_ang_film2=1;
    
elseif (ImagSyst.film{index}.z_pos==ImagSyst.surfs.list{ImagSyst.surfs.order(indK(1))}.z_pos)
    %distance Film-Optical System
    t_ob_film2=0;t_im_film2=0;m_lat_film2=1;m_ang_film2=1;
else
    %distance Film-Optical System
    t_ob_film2=ImagSyst.surfs.list{ImagSyst.surfs.order(indK(1))}.z_pos-ImagSyst.film{index}.z_pos; 
    %subsystem
    sub_index2=ImagSyst.surfs.order(indK(1):end);
    %find refranctive index in the Sub-Space for SubSystem
    if sub_index2(1)==ImagSyst.surfs.order(1)
        n_ob2=ImagSyst.n_ob;
    else
        space_type='object';l=1;
        ind_obj2=find(ImagSyst.surfs.order==sub_index1(1));
        [n_ob2]=paraxFindN4SubSyst(ImagSyst,ind_obj2,l,space_type);
    end
    if sub_index2(end)==ImagSyst.surfs.order(end)
        n_im2=ImagSyst.n_im;
    else
        space_type='image';l=1;
        ind_im2=find(ImagSyst.surfs.order==sub_index2(end));
        [n_im2]=paraxFindN4SubSyst(ImagSyst,ind_im2,l,space_type);
    end
    %Create Sub System
    [subOptSyst2]=paraxCreateSubSyst(ImagSyst,sub_index2,n_ob2,n_im2);
    %Image the film through the Sub System
    [t_im_film2, m_lat_film2,m_ang_film2]= paraxConjImagingMatrix(subOptSyst2,type_conj2,t_ob_film2);
end
% EnP position
z_im_film2=ImagSyst.surfs.list{ImagSyst.surfs.order(end)}.z_pos+t_im_film2;
% EnP dimension
% check if there is a relation to 'real world' coordinates and the
% coordinate used to rotattionally-symmetric system in parax approx

if isfield(ImagSyst,'realWorldTransf')
    %To complete when defined a way to move from relative coords to real
    %world coords
    %The augmented parameters ar used to take into account the possible
    %tilting (deltaU) and not-centering (deltaY_ecc)
%     warning ('For real world coordinates the code has to be COMPLETED!')
else
%     warning ('The radius of the circle inscribed in the film has been selected!')
    diam_film2= min(ImagSyst.film{index}.size_unit).*m_lat_film2.*cos(augParam_Film(2)); %smallest diameter tilted by deltaU
    diam_up2=diam_film2/2+augParam_Film(1); %upper limit
    diam_down2=-diam_film2/2+augParam_Film(1); %lower limit
end
%set output
ImagSyst.film{index}.Pupils.ExP.z_pos=z_im_film2;
ImagSyst.film{index}.Pupils.ExP.m_lat=m_lat_film2;
ImagSyst.film{index}.Pupils.ExP.diam(:,1)=diam_up2;
ImagSyst.film{index}.Pupils.ExP.diam(:,2)=diam_down2;


%% append matrices
ImagSyst.film{index}.matrix.abcd_red=M_red;
ImagSyst.film{index}.matrix.abcd=M;
ImagSyst.film{index}.matrix.abcdef_red=M_aug_red;
ImagSyst.film{index}.matrix.abcdef=M_aug;