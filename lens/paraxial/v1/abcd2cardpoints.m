function [Fo,Fi,Ho,Hi,No,Ni]=abcd2cardpoints(abcd,n_obj,n_im)

%% Computer the optical power of a refractive surface
%% INPUT
%abcd: (2x2xP) matrix describing the transformation of an optical system
%for P different wavelength
%n_obj:  vector (P element) refractive index of the object plane for P
%different wavelength
%n_im: vector (P element) refractive index of the image plane for P
%different wavelength

% NB: n_obj & n_im have to be the same used to compute abcd matrix


%% OUTPUT: 6 cardinal point (for each position along z axis and shift (dz) from the first or last vertex)
%Focal points
% Fo:  (1xP)shift of the focal point  for object side from the first vertex, for  P sampled wavelength
% Fi:  (1xP) shift of the focal point  for image side from the last vertex,  for P sampled wavelength
%Principal points
% Ho: (1xP) shift of the principal point  for object side from the first vertex,  for P sampled wavelength
% Hi:  (1xP) shift of the principal point  for image side from the last vertex, for P sampled wavelength
%Nodal points
% No: (1xP) shift of the nodal point  for object side from the first vertex,  for P sampled wavelength
% Ni: (1xP) shift of the principal point  for image side from the last vertex, for P sampled wavelength

%% MATRIX COEFFs
a=reshape(abcd(1,1,:),size(n_obj,1),size(n_obj,2));
b=reshape(abcd(1,2,:),size(n_obj,1),size(n_obj,2));
c=reshape(abcd(2,1,:),size(n_obj,1),size(n_obj,2));
d=reshape(abcd(2,2,:),size(n_obj,1),size(n_obj,2));


%% COMPUTE THE FOCAL POINTs
Fo=(n_obj.*d./c); %dz_fo=no*d/c

Fi=(-n_im.*a./c); %dz_fi=-n1*a/c


%% COMPUTE THE PRINCIPAL POINTs
Ho=(n_obj.*(d-1)./c); %dz_ho=no*(d-1)/c

Hi=(n_im.*(1-a)./c); %dz_hi=-n1*(1-a)/c


%% COMPUTE THE NODAL POINTs

No=((n_obj.*d-n_im)./c); %dz_no=(no*d-ni)/c        

Ni=((n_obj-n_im.*a)./c); %dz_ni=(no-n1*a)/c

