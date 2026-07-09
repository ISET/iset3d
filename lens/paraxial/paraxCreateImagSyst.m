%% Function: Create an Imaging System:Optical Elements and Sensor (or Photosensitive Film)

function [ImagSyst]=paraxCreateImagSyst(OptSyst,Film,Zpos_film,augParam_Film,optAxis,varargin)

% %INPUT
% %OptSyst: Structures of the optical system
% %Film: Structures of the optical system
% %Zpos_film: position in [unit] where Film vertex is placed
% %augParam: [Dy_dec;%Du_tilt: tilting angle of the surface refered to the optical axis [radiant]]
% %optAxis: Structure describig the optical axis (TO BE INCLUDED)
% %varargin: 
% 
% %OUTPUT
% %OmgSyst: struct of the imagSyst
% 
% %c.v. =column vector for wavelenght dependence
% 
% 
% %NB  An Imaging System should have at least 1 Film, when create please
% %specify 1 film

%% CHECKs

%Wavelength is a column vector
if OptSyst.unit~=Film.unit
    warning ('Optical and Film are built based on different unit, RESULTs not reliable')           
end
ImagSyst.wave=OptSyst.wave;

%Unit
ImagSyst.unit=OptSyst.unit;

% Type
ImagSyst.type='Imaging System';

%Chech augParam for Film 
if ~exist('augParam_Film','var')    
    augParam_Film=[0;0];
end
%Chech Optical axis 
if ~exist('optAxis','var')    
    optAxis=[];
end
ImagSyst.optAxis=optAxis;



%% Append parameter about Optical System

ImagSyst.n_ob=OptSyst.n_ob;
ImagSyst.n_im=OptSyst.n_im;
ImagSyst.surfs=OptSyst.surfs;
ImagSyst.matrix=OptSyst.matrix;
% ImagSyst.cardPoints=OptSyst.cardPoints;
% ImagSyst.Pupils=OptSyst.Pupils;
ImagSyst.Pupils=paraxGet(OptSyst,'pupils');
% ImagSyst.Petzval=OptSyst.Petzval;

%% Append parameter about the sensor

[ImagSyst]=paraxAddFilm2ImagSyst(ImagSyst,Film,Zpos_film,augParam_Film);

