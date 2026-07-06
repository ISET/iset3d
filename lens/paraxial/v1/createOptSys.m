function [OptSys]=createOptSys(R,V,A,wl,N,n_obj,n_im,Diap,unit)

%% INPUT

%R: vector of m elements, curvature radius of refractive surfaces  [unit]         sign convention <----R---(cc)
%V: vector of m elements, refractive vertex positions z-axis [unit]                 sign convention --------z------>
%A: vector of m elements, aperture of the refractive surface [unit]
%wl: vector of p elements (P x 1), sampling the radiance spectrum of the incident light
%N: matrix of ( p x m-1) element of n index after refraction at the p different wavelength. NB lenght(N)=length(R o V)-1, before first surface n_obj, before last surface n_im
%n_obj:  column vector (p x 1) , refractive index of object space at different wavelengths
%n_im:  column vector (p x 1) , refractive index of image space at different wavelengths
%Diap: structure about the diaphragm  .pos: z-position [unit]; .diam: %diameter [unit]
%unit: unit for all the distance 'mm' or 'm'


%% APPEND VALUEs TO THE OptSys structure

OptSys.R=R;OptSys.V=V;OptSys.A=A;
OptSys.n_obj=n_obj; OptSys.n_im=n_im;
OptSys.Diap=Diap; OptSys.unit=unit;
OptSys.wl=wl; OptSys.N=N;

% EMPTY field
OptSys.opw=[];OptSys.dist=[];
OptSys.refMat=[];OptSys.transMat=[];
OptSys.efl=[];OptSys.abcd=[];



%% CHECK VERTICEs POSITION
% The refractive surfaces have to be sorted for  increasing z-position
OptSys=sortVertices(OptSys);

%CHECK for thin lens
if length(OptSys.V)==1
    OptSys.th=0;
    %COMPUTE (abcd) MATRIX of the OPTICAL SYSTEM for 
    OptSys=abcdMatrixThinLens(OptSys);
else
    %Compute the distance between each couple of vertices (m-1 elements)
    OptSys.th=OptSys.V(2:end)-OptSys.V(1:end-1);
    %COMPUTE (abcd) MATRIX of the OPTICAL SYSTEM
    OptSys=abcdMatrix(OptSys);
end





%% FIND Stop Aperture and ENTRANCE and EXIT PUPIL

