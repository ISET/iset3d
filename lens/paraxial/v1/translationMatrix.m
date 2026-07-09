function transMat=translationMatrix(dist,n)

%% Set the translation matrix between two point
%% INPUT
%dist: scalar or vector (M-1 elements) cointaining the distance between one or multiple couples of points
%n:  matrix [P x M-1 elements],M-1 refr. index of the media at P different wavelengths 

%% OUTPUT
%transMat: matrix(2 x 2x P x M-1) of the translation transformation , 2x2 single transformation, M refractive surface and P different wavel. 
%% Set the value of the matrix (or pill of matrices in case of multiple opw)

if isempty(dist) %case of thin lens
    transMat=eye(2); %identity matrix
    return
end


if size(dist,2)==size(n,2)
    if size(dist,1) ~= size(n,1)
        dist=repmat(dist,size(n,1),1); % Prepare distance 
    end
    transMat=ones(2,2,size(n,1),size(n,2));
    transMat(2,1,:,:)=zeros(1,1,size(n,1),size(n,2));
    transMat(1,2,:,:)=dist./n;
end


