function ABCD=abcd2ABCD(abcd,d_obj,n_obj,d_im,n_im);

%% Compute the ABCD Matrix (Imaging  matrix of an Optical System) and its related features for an object. Valide P different source for the image plane

%% INPUT
%abcd: matrix (2x2xP) Optical System Matrix at P different wavelength
%d_obj: scalar or vector (1xQ)  distance/s of the object to the first optical system vertex 
%n_obj: vector (P  refractive index/es for the object plane/s
%d_im: scalar or vector (1xQ) distance/s of the image to the last optical system vertex 
%n_im: scalar  refractive index/es for the image plane/s

%Q is the number of objects
%P is the number of sampled wavelengths
%% OUTPUT
%ABCD: matrix (2x2 xP x Q )Imaging Matrix

if (length(d_obj)& length(d_im))==1
     %% PRE-TRANSFORM CALCULATIONs
    Dist=[-d_obj,d_im]; % vector of distances 
    N=[n_obj,n_im]; %vector of refractive index 
    transMat=translationMatrix(Dist,N);
    for p=1:size(abcd,3)      
        %% COMPUTE IMAGING MATRIX 
            ABCD(:,:,p)=transMat(:,:,p,2)*abcd(:,:,p)*transMat(:,:,p,1); 
     end
else
    ABCD=[]; % Not possible compute multiple object
end


% if length(d_obj)==1
%     ABCD=reshape(ABCD,size(ABCD,1),size(ABCD,2),size(ABCD,3));
% end
