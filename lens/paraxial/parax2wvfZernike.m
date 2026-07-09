% Convert zernike coeff from standard of PSF3D to Wavefront Tooolbox

%RELATED FUNCTION IN WAVEFRONT toolbox: [] = wvfOSAIndexToVectorIndex() Convert a list of OSA j values to a WVF toolbox index
%                                       []=wvfOSAIndexToZernikeMN()   Convert from the Zernike 2 index standard indexing  to the OSA single Zernike index (starting at j = 0)
% 
%Related OSA indexing:  http://www.telescope-optics.net/monochromatic_eye_aberrations.htm


function  [wvfZ]=parax2wvfZernike(psf3dZ)

%INPUT
%psf3dZ: Zernike coeffs in standard use in PSF3D

%OUTPUT
% wvfZ: Zernike coeffs in standard use in Wavefront Toolbox 
% 
%NB: CHANGE direction for wavelength in column (for PSF3D) to row (for Wavefront Toolbox) vector



%% GET  indices n and m used to convert to OSA standard

fnames=fieldnames(psf3dZ);
%number of wavelength sample
dummy=getfield(psf3dZ,fnames{1});
nw=size(dummy,1);


for ci=1:length(fnames)
    n_coeff(ci)=str2num(fnames{ci}(2)); %n index
    m_coeff(ci)=str2num(fnames{ci}(3)); %m index
    %OSA INDEXING  {http://www.telescope-optics.net/monochromatic_eye_aberrations.htm}
    j_OSA_coeff(ci)=(n_coeff(ci).*(n_coeff(ci)+2) + m_coeff(ci)) / 2;
end

ind_OSA=1; %initialize a index
num_wvfZ=max(j_OSA_coeff+1);
for ji=1:max([num_wvfZ]) %
    jOSA=(j_OSA_coeff(ind_OSA)+1);
    if ji==jOSA
%         ind_fnames=j_OSA_coeff(ind_OSA)+1;
        Cnm=getfield(psf3dZ,fnames{ind_OSA});
        ind_OSA=ind_OSA+1; %increase index
        wvfZ(ji,:)=Cnm'; %append value
    else 
        wvfZ(ji,:)=zeros(1,nw); %Empty with Zero Values
    end
end