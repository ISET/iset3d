function refMat=refractiveMatrix(opw)

%% Set the refractive matrix of a surface
%% INPUT
%opw:  matrix of [P x M], M refr. surface and P differen wavelengths, Optical power 


%% OUTPUT
%refMat: matrix(2 x 2x P x M) of the refractive transformation, 2x2 single
%transformation, M refractive surface and P different wavel.

%% Set the value of the matrix (or pill of matrices in case of multiple opw)

refMat=ones(2,2,size(opw,1),size(opw,2));
refMat(1,2,:,:)=zeros(1,1,size(opw,1),size(opw,2));
refMat(2,1,:,:)=-opw; 
