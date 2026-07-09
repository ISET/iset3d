

function [M]=paraxComputeTranslationMatrix(th,n,matrix_type,varagin)
% Compute the paraxial matrix for the given translation
%
%   function [M]=paraxComputeTranslationMatrix(th,n,matrix_type,varagin)
%
%INPUT
%th: thickness of the translation 
%n: column vector of N sampled wavelength, the refractive index in the translation 
%matrix_type: string describing which type of matrix has to be computer : %for 'reduced' or 'non-reduced'  parameters
%varargin : 


%OUTPUT
%M: (2x2xN): surface paraxial matrix for the N wavelength
%
% MP Vistasoft 2014

%% COMPUTE M Matrix for the given surface structure with reduced parameters

Mred=ones(2,2,size(n,1));
Mred(2,1,:)=0;
Mred(1,2,:)=th./n;


switch matrix_type
    case {'reduced','red'}
        M=Mred;
    case {'not-reduced','notred',''}
%         M=paraxMatrixRed2NotRed_red(Mred,n,n);
        M=ones(2,2,size(n,1));
        M(2,1,:)=0;
        M(1,2,:)=th;
    otherwise
        warning('Not fount a valid M matrix type!! Returned EMPTY !!')
        M=[];
end


