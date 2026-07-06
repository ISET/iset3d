function d_obj=image2object(efl,d_im,dh_im,n_im,dh_obj,n_obj);

%% Find the conjugate point for the given im in medium n_im, distance d_im (from the last vertex of the optical system)
%the given effective focal length (efl) in the obj plane (medium n_obj)
% taking into account the shift of the principal pont for object side
% (dh_obj) and image side(dh_im)

%obj <--------d_obj-------|V(1)|---dh_obj-->|H_obj|                            |H_im|<-------V(end)------d_im------->image
% NB d_obj & dh_im <0 in figure beacuse measured in the opposite side

%                    n_im                   n_obj             1
%             ________________   -   __________________  =___________
%               (d_im-dh_im)          (d_obj-dh_obj)          efl


% SOLUTION:
%                                          efl *(d_obj+dh_obj)          
%             d_im   =  dh_im   + n_im _________________________
%                                          d_obj-dh_obj+ n_obj*efl

%% INPUT     P number of sample wavelength
%efl: (1xP) effective focal length 
%d_im: distance between last vertex of the optical system V(end) and the   image (Is negative in the feature)
%dh_im: (1xP) distance between Principal Point (im side) and first vertex V(end)
%n_im: refractive index in the image plane
%dh_obj: (1xP) distance between Principal Point (obj side) and first vertex V(1)
%n_obj: (1xP) refractive index in the object plane


% OUTPUT
% d_obj: (1xP) distance of conjugate point from the first vertex V(1) for the different P wavelength





A=1./efl; 
B=n_im./(d_im-dh_im);
C=1./(B-A);

d_obj=dh_obj+n_obj.*C;
