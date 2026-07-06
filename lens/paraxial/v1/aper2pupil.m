function [Pupil]=aper2pupil(OptSys,Aper,type)

%% INPUT

%OptSys: 
%Aper: aperture structure .V :position (or vertex) along z axis [unit]
%                         .Diam: diameter             [unit] 
% type: select with pupil to find (Entrance Pupil or Exit pupil)




switch type
    
    
    case {'entrance','entrance pupil', 'EnP'}
        index=find(OptSys.V<Aper.V); % find vertices of refr. surface before the aperture
        if isempty(index)
            %CASE of First Aperture to image, ENTRANCE PUPIL coincides to   the APERTURE
            Pupil.V=Aper.V;
            Pupil.Diam=Aper.Diam;
        else
            %CASE  Aperture different to the first 
            %% STEP 1: create sub-Optical System including all the refractive surface  before the aperture under evaluation
            %Invert index to perform imaging
            index1=index(end:-1:1);
            %set refr. indices of corresponding image and obj space
            n_obj1=OptSys.N(index(end));
            n_im1=OptSys.n_obj;
            [subOptSys]=createOptSys(OptSys.R(index),OptSys.V(index),OptSys.A(index),OptSys.wl,OptSys.N(index),n_obj1,n_im1,OptSys.Diap,OptSys.unit);
            % STEP 2: imaging the evaluated aperture thorugh the sub-Optical System
            dist_obj=Aper.V-subOptSys.V(1); %distance between the surface/diaph to be image and the first vertwx of the sub-Optical System
            [dist_im,magn_l]=object2image(subOptSys.efl,dist_obj,subOptSys.Ho,subOptSys.No,subOptSys.n_obj,subOptSys.Hi,subOptSys.Ni,subOptSys.n_im);
            % STEP 3: Place the Entrance Pupil and its diameter
            EnP.V=subOptSys.V(end)+dist_im; %Position of the possible Entrance Pupil
            EnP.Diam=Aper.A.*magn_l;%Diameter of the possible Entrance Pupil
            % STEP 4: Set Output
            Pupil.V=EnP.V;
            Pupil.Diam=EnP.Diam;
        end
        
    case {'exit', 'exit pupil','ExP'}
end
    
    






% in=find(OptSys.V<list.V(j));
%     index=[in];
%     if isempty(in)
%         [subOptSys(j)]=createOptSys([],[],[],OptSys.wl,[],OptSys.n_obj,OptSys.n_im,[],OptSys.unit);
%         dist_obj(j)=0;
%     else
%         % STEP 1: create sub-Optical System including all the refractive surface  before the aperture under evaluation
%         n_im0=OptSys.N(index(end));
%         [subOptSys(j)]=createOptSys(OptSys.R(index),OptSys.V(index),OptSys.A(index),OptSys.wl,OptSys.N(index),OptSys.n_obj,n_im0,OptSys.Diap,OptSys.unit);
%         % STEP 2: imaging the evaluated aperture thorugh the sub-Optical System
%         dist_obj(j)=list.V(j)-subOptSys(j).V(1); %distance between the surface/diaph to be image and the first vertwx of the sub-Optical System
%         [dist_im(j),magn_l(j)]=object2image(subOptSys(j).efl,dist_obj(j),subOptSys(j).Ho,subOptSys(j).No,subOptSys(j).n_obj,subOptSys(j).Hi,subOptSys(j).Ni,subOptSys(j).n_im);
%         % STEP 3: Place the Entrance Pupil and its diameter
%         posEnP.V(j)=subOptSys(j).V(end)+dist_im(j); %Position of the possible Entrance Pupil
%         posEnP.Diam(j)=list.A(j)*magn_l(j);%Diameter of the possible Entrance Pupil
%     end