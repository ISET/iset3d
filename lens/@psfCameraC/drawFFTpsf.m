function hdl = drawFFTpsf(obj, wave0, plotType, limit)
% Draw the PSF for the selected wavelength
%
%   psfCamera.drawFFTpsf(wave0, [plotType='surf'],[limit=[]])
%
% INPUT
%   wave0:       specify the wavelength to plot [in 'nm']
%   plotType:    {surf,contour,contour3,contourf}
%   limit:       the image sampling grid (in unit)
%
% OUTPUT
%   hdl:   Figure handle, contains data in userdata field
%
%Examples
%   psfC = psfCameraC('lens',lensC,'film',filmC,'pointsource',pointSource);
%   psfC.drawFFTpsf(500)
%   psfC.drawFFTpsf(500,'surf')
%   psfC.drawFFTpsf(500,'surf',[])
%
% MP Vistasoft Team, Copyright 2014

%% GET wavelength vector

% nW=size(wave(:),1); %number of sample
% unit='mm';

wave = obj.get('wave');
inW0 = find(wave==wave0);  % Index
if isempty(inW0), error('No wavelength match: %.1f',wave)
else              inW0 = inW0(1);
end

if ~exist('plotType','var') || isempty(plotType), plotType = 'surf'; end
if ~exist('limit','var'), limit = []; end

%% GET THE INPUT: PSF
PSF=obj.get('fft psf modulus');

%% GET and CHECK INPUT coordinate

% if Nw = number of wavelength and Ns=number of grid sampling
% Possibility 1: x & y : [Nw x Ns]  -> create mesh for the selected wavelength
% Possibility 2: x & y : [Ns x Ns x Nw]  -> just selected wavelength

coord = obj.get('fftpsfcoordinate');
x_im  = coord.x; 
y_im  = coord.y;

if not(ndims(x_im)==ndims(y_im))
    error (' INPUT dimensions for x- and y- coordinate DO NOT MATCH !!')
elseif ndims(x_im)==2 %y_im dimension is the same of x_im
    % input coordinate dimension  x_im=[N,Mx]; y_im=[N,My]
    x_im=x_im(inW0,:);y_im=y_im(inW0,:);
    if isempty (limit)
        indx=1:length(x_im);
        indy=1:length(y_im);
    elseif length(limit)==1
        indx=(abs(x_im)<=limit);
        indy=indx;
    else
        indx=(abs(x_im)<=limit(1));
        indy=(abs(y_im)<=limit(2));
    end
    
    %% CREATE MESH FOR PLOT
    [X,Y]=meshgrid(x_im(indx),y_im(indy));
    
elseif ndims(x_im)==3 %y_im dimension is the same of x_im
    % input coordinate dimension  x_im=[My,Mx,N]; y_im=[My,Mx,N]
    x_im=x_im(:,:,inW0);y_im=y_im(:,:,inW0);
    %Check homogenity in input coordinate dimension
    if not(ndims(x_im)==ndims(y_im))
        error(['input coord dimension DO NOT MATCH, x_im: ',num2str(ndims(x_im)),' y_im: ',num2str(ndims(y_im))])
    end
    
    if isempty (limit)
        indx=1:size(x_im,2);
        indy=1:size(y_im,1);
    elseif length(limit)==1
        [indy0,indx]=find(abs(x_im)<=limit);
        [indy,indx0]=find(abs(x_im)<=limit);
    else
        [indy0,indx]=find(abs(x_im)<=limit(1));
        [indy,indx0]=find(abs(x_im)<=limit(2));
    end
    indy=squeeze(indy); indx=squeeze(indx);
    %% CREATE MESH FOR PLOT
    X=x_im(indy,indx);Y=y_im(indy,indx);
    
else
    error ('the dimension of the input coordinate exceed the limit (2 or 3) !')
end

%% GET THE PSF
PSF = PSF(indy,indx,inW0);

%% PLOT
% TITLE
% FontSize1=12;

hdl = ieFigure;
switch plotType
    case {'surf'}
        surf(X,Y,PSF); shading('interp');
    case {'contour'}, contour (X,Y,PSF)
    case {'contour3'},contour3 (X,Y,PSF)
    case {'contourf'},contourf (X,Y,PSF)
end
udata.X = X; udata.Y = Y; udata.PSF = PSF;
set(hdl,'userdata',udata);

% set(gca,'LineWidth',LineWidth,'LineStyle','--')
title(['PSF at ',num2str(wave0),'nm'])
xlabel('x [mm]')
ylabel('y [mm]')
zlabel('Normalized intensity')

colormap('jet'); colorbar

end


