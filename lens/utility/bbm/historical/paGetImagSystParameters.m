function [CR_0,MR_0,N,abbeNumber,C,k,augmParam_list,Msurf,Mtrans]=paGetImagSystParameters(object,ImagSyst,angle_type,varargin)
% Historical reference only.
%
% This function was recovered from an old 2021 stash while setting up the
% ISETLens tests. It is retained as a record of the previous Seidel
% aberration implementation, but it is not part of the supported API. The
% current plan is to implement Seidel aberrations afresh, in a smaller,
% tested design parallel to the Zernike/wavefront utilities.
%
% Get the parameters of the imaging system required to estimate the aberration for a given object (point source)
%
%
%  [CR_0,MR_0,N,abbeNumber,C,k,augmParam_list,Msurf,Mtrans] = ...
%       paraxAberrationGetImagSystParameters(object,ImagSyst,angle_type,...
%           special_rays,special_param);
%  
%TODO
%  Various little programming clean ups required in here
%
%INPUT
% object:  structure describing the object which is imaged through the
%          imaging system
% ImagSyst: imaging system through which theobject is imaged
% angle_type: type of angle to get and compute: [paraxial or real (non-paraxial)]
% varargin rays type  {1}{1}: principal ray; {1}{2} secondary ray
%                     {2}{1}: principal ray secondary parameters
%                     (case:marginal -upper,-lower)
%                     {2}{2}: secondary ray secondary parameters
%                     (case:marginal -upper,-lower)
%                      
%
%OUTPUT
%  CR_0:[2xN] chief ray coordinates (in phase space) af first surface. 
%  MR_0: margina ray coordinates (in phase space) at first surface.
%  N: [NxM+2] refractive index from object to image space
%  abbeNumer [1xM+2]: dispesione coeffs for the medium (http://en.wikipedia.org/wiki/Abbe_number)
%  C[1xM]:  curvature
%  k[1xM]; conic parameter for surface
%  augmParam_list: [2xM] parameter of quasi symmetry
%  Msurf:[M][2x2xN] list of transformation at the surface
%  Mtrans:[M-1][2x2xN] list of transformation at the surface
%
%NOTE: N: #sampling wavelength
%      M: #of surface
%
% MP Vistasoft Copyright 2014

%% Initialize parameters

augParam = 'false';

if all(ImagSyst.n_ob==1)
    [a,abbeNumber_ob] = RefractiveIndexDispersion(586.7*1e-6,'mm','air0'); %default air    
elseif isfield(ImagSyst,'Vd_ob')
    abbeNumber_ob=Vd_ob; % abbe Number of the object space medium
else
    % warning('Abbe number of the object space medium  is not AVAILABLE!')
    abbeNumber_ob=[];
end

if all(ImagSyst.n_im==1)
    [a,abbeNumber_im]=RefractiveIndexDispersion(586.7*1e-6,'mm','air0'); %default air    
elseif isfield(ImagSyst,'Vd_im')
    abbeNumber_im=Vd_im; % Abbe Number of the object space medium
else
    % warning('Abbe number of the image space medium  is not AVAILABLE!')
    abbeNumber_im=[];
end


%% CHECK the type of rays is specify

if nargin>3
    rays_typeCR=varargin{1}{1}; %principal ray
    rays_typeMR=varargin{1}{2}; %secondary ray
    
else
    % DEFAULT: chief and marginal rays
    rays_typeCR='chief';
    rays_typeMR='marginal';
end

%% COMPUTE  transfer of CHIEF and MARGINAL Rays to the first surface of the system

if nargin>4
    [RayCR]=paraxGetYUZMeridionalRay(object,ImagSyst.wave,rays_typeCR,angle_type,varargin{2}{1});
    [RayMR]=paraxGetYUZMeridionalRay(object,ImagSyst.wave,rays_typeMR,angle_type,varargin{2}{2});
    
else
    % DEFAULT: chief and marginal rays
    [RayCR]=paraxGetYUZMeridionalRay(object,ImagSyst.wave,rays_typeCR,angle_type);
    [RayMR]=paraxGetYUZMeridionalRay(object,ImagSyst.wave,rays_typeMR,angle_type);
end



%% Arrange starting point

% Initialize the arrays here

% Then loop
for li=1:size(ImagSyst.wave,1)
    %Chief Ray or Principal Ray
    CR_init(1,li)=[RayCR.y(li,1)];
    CR_init(2,li)=[RayCR.u(li,1)];
    %Marginal Ray or Secondary Ray
    MR_init(1,li)=[RayMR.y(li,1)];
    MR_init(2,li)=[RayMR.u(li,1)];
end

%% Move the rays to the FIRST Surface


switch angle_type % Compute the transfer accorting to the angle (approximated or not)
    case {'parax';'paraxial'}
        %Principal ray or Chief ray            
        th_CR=paraxGet(ImagSyst,'firstvertex')-RayCR.z; %distance from first surface to the ray source
        [M_CR]=paraxComputeTranslationMatrix(th_CR,ImagSyst.n_ob,'not-reduced');       
        [CR_0]=paraxMatrixTransformation(M_CR,CR_init);
        %Marginal Ray or Secondary Ray
        th_MR=paraxGet(ImagSyst,'firstvertex')-RayMR.z; %distance from first surface to the ray source
        [M_MR]=paraxComputeTranslationMatrix(th_MR,ImagSyst.n_ob,'not-reduced');
        [MR_0]=paraxMatrixTransformation(M_MR,MR_init);

    case {'real';'non-approx';'non-paraxial'}
        warning('TO BE COMPLETED!! Computed through PARAXIAL Ray Tracing')
         %Principal ray or Chief ray            
        th_CR=paraxGet(ImagSyst,'firstvertex')-RayCR.z; %distance from first surface to the ray source
        [M_CR]=paraxComputeTranslationMatrix(th_CR,ImagSyst.n_ob,'not-reduced');       
        [CR_0]=paraxMatrixTransformation(M_CR,CR_init);
        %Marginal Ray or Secondary Ray
        th_MR=paraxGet(ImagSyst,'firstvertex')-RayMR.z; %distance from first surface to the ray source
        [M_MR]=paraxComputeTranslationMatrix(th_MR,ImagSyst.n_ob,'not-reduced');
        [MR_0]=paraxMatrixTransformation(M_MR,MR_init);
        
    otherwise
        error('Not valid SELECTION of angle [paraxial/non-paraxial]')
end


% Create default vector
N(:,1)=ImagSyst.n_ob;
% abbeNumber(1)=abbeNumber_ob;

for si=1:length(ImagSyst.surfs.order)
    N(:,si+1)=ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.N; %refractive index
%     abbeNumber(si)=ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.abbeNumber; %abbe number
    element_type{si}=[ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.type,'',num2str(ImagSyst.surfs.order(si))];
    
    switch ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.type
        case {'refractive';'mirror'}
            C(si)=1./ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.R; %curvature
            if isempty(ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.k)
                k(si)=0; %perfectly spherical
            else
                k(si)=ImagSyst.surfs.list{ImagSyst.surfs.order(si)}.k;
            end
        case {'flat';'diaphragm'}
            C(si)=realmin; %minimal possible value
            k(si)=0;
        case {'thin';'thick';'GRIN'}
            warning('Effect of thin,thick and GRIN lens SHOULD be include!! Not available at the moment')
    end
    % Create a list of matrix computation
    Msurf{si}=ImagSyst.surfs.matrix.surf{si}; %transformation at the surface
    if si<length(ImagSyst.surfs.order)
        Mtrans{si}=ImagSyst.surfs.matrix.transl{si}; %transformation fro the tranlation between teo surface
    end
    % create a cell for describing quasi-rotational simmetry
    augmParam_list(:,si)=ImagSyst.surfs.augParam.list{ImagSyst.surfs.order(si)};
end

% and image space
N(:,end+1)=ImagSyst.n_im;
% abbeNumber(end+1)=abbeNumber_im;

if not(exist('abbeNumber','var')), abbeNumber=[]; end

end
