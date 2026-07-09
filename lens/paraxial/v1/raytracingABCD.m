function [y_im,teta_im]=raytracingABCD(ABCD,y_obj,teta_obj,n_obj,n_im)

%% RUN RAY TRACING ACCONDING TO ABCD MATRIX (object and image distances are used to calculate ABCD matrix)
%% INPUT
%ABCD: (2x2xP) Imaging Matrix at P different wavelengths
%y_obj: (scalar) off-axis distance to the optical axis of the point source
%teta_obj: (scalar) [rad] tilte angle for the ray leaving the point source
%n_obj: (Px1) refr. index of obj space at P different wavelength
%n_im: (Px1) refr. index of image space at P different wavelength
%% OUTPUT
%y_im: (Px1) off_axis distance reaching the image plane for P different wavelength
%teta_im: (Px1) [rad] tilte angle for the ray reaching the corresponding height
%% Set the value of the matrix (or pill of matrices in case of multiple opw)

if (size(ABCD,3)==size(n_obj,1))&& (size(n_obj,1)==size(n_im,1))
    for p=1:size(ABCD,3)
        INPUT=[y_obj;n_obj(p).*teta_obj];
        OUTPUT=ABCD(:,:,p)*INPUT; 
        y_im(p)=OUTPUT(1);
        teta_im(p)=OUTPUT(2)/n_im(p);
    end    
else
    y_im=[];teta_im=[];    
end


% Set the output in column for wavelength-dependence
y_im=y_im';
teta_im=teta_im';