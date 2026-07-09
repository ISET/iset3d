function [d_im,m_linear]=object2image(efl,d_obj,dh_obj,dn_obj,n_obj,dh_im,dn_im,n_im);

%% Find the conjugate point for the given obj in medium n_obj, distance d_obj (from the first vertex of the optical system)
%the given effective focal length (efl) in the image plane (medium n_im)
% taking into account the shift of the principal pont for object side
% (dh_obj) and image side(dh_im)

%obj <--------d_obj-------|V(1)|---dh_obj-->|H_obj|                            |H_im|<-------V(end)------d_im------->image
% NB d_obj & dh_im <0 in figure beacuse measured in the opposite side

%                    n_im                   n_obj             1
%             ________________   -   __________________  =___________
%               (d_im-dh_im)          (d_obj-dh_obj)          efl


% SOLUTION: FOR COJUGATED POINT
%                                          efl *(d_obj+dh_obj)          
%             d_im   =  dh_im   + n_im _________________________
%                                          d_obj-dh_obj+ n_obj*efl

%MAGNIFICATION
%                           y_im     n_obj    (d_im-dh_im)
%LINEAR       m_linear=  _________= ______   _____________
%                            y_obj    n_im    (d_obj-dh_obj)


%% INPUT     P number of sample wavelength
%efl: (Px1) effective focal length 
%d_obj: distance between first vertex of the optical system V(1) and the   object (Is negative in the feature)
%dh_obj: (Px1) distance between Principal Point (obj side) and first vertex V(1)
%n_obj: (Px1) refractive index in the object plane
%dh_im: (Px1) distance between Principal Point (im side) and first vertex V(end)
%n_im: refractive index in the image plane

% OUTPUT
% d_im: (Px1) distance of conjugate image for the different P wavelengths
%m_linear: (Px1) lateral o linear magnification of the image for P different wavelengths





A=1./efl; 
B=n_obj./(d_obj-dh_obj);
C=1./(A+B);

d_im=dh_im+n_im.*C;


%% Compute LINEAR magnification factor
m_l1=n_obj./n_im;
m_l2=(d_im-dn_im)./(d_obj-dn_obj);
m_linear=m_l1.*m_l2;



    