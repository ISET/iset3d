function [R,V,Aper,Diaph,N]=datafile2format(name,ind_diap)

% import data file and extract the set the data in a format compatible to
% create OptSys object. 
% NB To create OptSys is required to sort all the elements along the optical
% axis (z-axis) setting the first surface on the object side in the origin
% ("0" position)
%INPUT
%name: string; data file
%diap_in: scalar; it is the index of the element of the whole structure indicating the diaphragm

%OUTPUT
%R: vector of m elements, curvature radius of refractive surfaces  [unit]         sign convention <----R---(cc)
%V: vector of m elements, refractive vertex positions z-axis [unit]                 sign convention --------z------>
%A: vector of m elements, aperture of the refractive surface [unit]
%N: vector of m-1 element of n index after refraction . 

%NB: no wavelength dependent import


%% EXAMPLE format of data-file

%# D-GAUSS F/2 22deg HFOV	
%# US patent 2,673,491 Tronnier"	
%# Moden Lens Design, p.312"	
%# Scaled to 50 mm from 100 mm	
%# focal length (in mm) 
%50	
%#last element used to have aperture 12	
%# radius	 axpos	N	aperture
%29.475	3.76	1.67	25.2
%84.83	0.12	1	25.2
%19.275	4.025	1.67	23
%40.77	3.275	1.699	23
%12.75	5.705	1	18
%0	4.5	0	17.1
%-14.495	1.18	1.603	17
%40.77	6.065	1.658	20
%-20.385	0.19	1	20
%437.065	3.22	1.717	20
%-39.73	0	1	12

%% COMPUTE

%Import data
inData=importfile(name);
data=inData.data;

%GET the indices of the lenses
vect_ind=[1:ind_diap-1,ind_diap+1:size(data,1)];


% GET the radius of curvature of the refractive surfaces
R=data(vect_ind,1)'; %Radius in [unit]      <----R---(cc)

%Total distance between first and last refractive surface
tot_z=sum(data(:,2));

%Set the refractive surfaces along the optical axis, first surface on the
%object side is at 0 position
for i=1:length(data(:,2))
    V1(i)=tot_z-sum(data(end:-1:i,2));%Refractive vertex positions z-axis [unit] --------z------>
end
V=V1(vect_ind); %vertices position
Aper=data(vect_ind,4)'; %aperture of the refractive surfaces


%Get the Diaphragm features
Diaph.pos=data(ind_diap,2); %Diaphragm position [unit]        -----z---->
Diaph.diam=data(ind_diap,4); %Diaphragm diameter [unit]         ^(xoy)^

%Get the refractive index (N) for all the surfaces and monochromatich light
N=data(vect_ind(1:end-1),3)';  % n index after refraction. NB lenght(N)=length(R o V)-1 because after last vertex we use n index of image plane and before the first 

