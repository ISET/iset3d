function [cardPoints]=paraxMatrix2CardinalPoints(M,n_ob,n_im,matrix_type)
%Find cardinal points and their distance from the first and the last
%vertices of the optical system described
%
%
%INPUT
%  M: Parax Matrix with reduced parameter (2x2xN) N wavelength samples
%  n_ob: the refractive index in object space (relative object space). Scalar or columne vector N elements
%  n_im: the refractive index in image space (relative object space). Scalar or columne vector N elements
%  matrix_type: string describing which type of matrix has to be computer : %for 'reduced' or 'non-reduced'  parameters
%
%
% NB: 'unit' of the distance is which M is computed
%
%OUTPUT
%  M: (2x2xN): surface paraxial matrix for the N wavelength
%  cardPoints: cardinal points
%    .ni,.fi,.dFi,.dHi,.dNi,.no.fo,.dFo,.dHo,.dNo, d_distance from the vertex and refractive index ni, no
%
% MP Vistasoft 2014

  
cardPoints.ni = n_im; cardPoints.no = n_ob;

switch matrix_type
    case {'reduced','red'}
        ared=squeeze(M(1,1,:));bred=squeeze(M(1,2,:));cred=squeeze(M(2,1,:));dred=squeeze(M(2,2,:));
        %Image space
        cardPoints.fi=-n_im./(cred); %Focal length   fi=-ni/c
        cardPoints.dFi=-n_im.*ared./(cred); %Focal distance from vertex  dFi=-ni*a/c
        cardPoints.dHi=n_im.*(1-ared)./(cred); %Principal point distance from vertex  dHi=ni*(1-a)/c
        cardPoints.dNi=(n_ob-n_im.*ared)./(cred); %Principal point distance from vertex  dNi=(no*-a*ni)/c
        %Object space
        cardPoints.fo=n_ob./(cred); %Focal length   fo=no/c
        cardPoints.dFo=n_ob.*dred./(cred); %Focal distance from vertex  dFo=no*d/c
        cardPoints.dHo=n_ob.*(dred-1)./(cred); %Principal point distance from vertex  dHo=no*(d-1)/c
        cardPoints.dNo=(n_ob.*dred-n_im)./(cred); %Principal point distance from vertex  dNo=(no*d-ni)/c
        
    case {'not-reduced','notred',''}
        a=squeeze(M(1,1,:));b=squeeze(M(1,2,:));c=squeeze(M(2,1,:));d=squeeze(M(2,2,:));
        determ=(a.*d-b.*c);
        %Image space
        cardPoints.fi=-1./(c); %Focal length   fi=-1/c
        cardPoints.dFi=-a./(c); %Focal distance from vertex  dFi=-a/c
        cardPoints.dHi=(1-a)./(c); %Principal point distance from vertex  dHi=(1-a)/c
        cardPoints.dNi=-(a-determ)./(c); %Principal point distance from vertex  dNi=-(a-(ad-bc))/c
        %Object space
        cardPoints.fo=determ./(c); %Focal length   fo=det/c
        cardPoints.dFo=d./(c); %Focal distance from vertex  dFo=d/c
        cardPoints.dHo=-(determ-d)./(c); %Principal point distance from vertex  dHo=-((ad-bc)-d)/c
        cardPoints.dNo=-(1-d)./(c); %Principal point distance from vertex  dNo=-(1-d)/c
        
    otherwise
        warning('M matrix type is not valid. Returning EMPTY cardinal points.')
end

end