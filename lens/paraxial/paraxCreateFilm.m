%% Function: Create an object in the object space 


function [Film]=paraxCreateFilm(z_pos,profile,npixel,pixel_pitch,unit,varargin)

%INPUT
%z_pos: position along the optical axis (z) of the surface
%profile: 'point','flat','spherical,'aspherical' and related  parameters specified in varargin
%npixel: # pixel for row and column [delta along row (dy),delta along
%coloumn (dx)]
%pixel_pitch: distance fro adiacent pixel [dy,dx] in [unit]
%unit: ofr z_pos,pixel_pitch
%varargin: depends on the film type
%           
%OUTPUT
%film: struct with the information about the photosensitive  film


%%NOTE: Spectral Sensitivity of the Film



%% Append Values


Film.unit=unit;
Film.profile=profile;


switch Film.profile
    
    case {'flat','plane'}
        Film.pixel_pitch=pixel_pitch;
        Film.size_pixel=npixel;
        Film.size_unit=npixel.*pixel_pitch;
        %Phantom parameters
        dx=pixel_pitch(2);dy=pixel_pitch(1);
        vx=([1:npixel(2)]-npixel(2)/2).*dx;vy=([1:npixel(1)]-npixel(1)/2).*dy;
        %NOT USEFUL NOW
%         [Film.mapX,Film.mapY]=meshgrid(vx,vy);
%         Film.mapZ=(Film.mapX+Film.mapY)./(Film.mapX+Film.mapY);
        
        %DEBUG
%         figure
%         surf (Film.mapX,Film.mapY,Film.mapZ)
%         colormap jet
%         axis equal
       
    case {'sphere','spherical'} 
        warning('For spherical surface the code has to be validated! Not reliable Data!')
        Film.pixel_pitch=pixel_pitch;
        Film.size_pixel=npixel;
        Film.size_unit=npixel.*pixel_pitch;
        %Phantom parameters
        dx=pixel_pitch(2);dy=pixel_pitch(1);
        vx=([1:npixel(2)]-npixel(2)/2).*dx;vy=([1:npixel(1)]-npixel(1)/2).*dy;
        %NOT USEFUL NOW
%         [Film.mapX,Film.mapY]=meshgrid(vx,vy);
        % About the sphere
        Radius=varargin{1};% radius of curvature of the spherical surface
        Cxyz=varargin{2}; %Center of the sphere (symmetrical around optical axis [z-axis]] [vector of two elements [xc,yc]]
        Cxyz=[Cxyz,-Radius]; %set center along optical axis
        Film.mapZ=(Film.mapX+Film.mapY)./(Film.mapX+Film.mapY);
        for xi=1:npixel(2)
            for yi=1:npixel(1)
                T1=Radius.^2-(vy(yi)-Cxyz(2)).^2-(vx(xi)-Cxyz(1)).^2;
                T2=sqrt(T1);
                Film.mapZ(yi,xi)=Cxyz(3)-T2; %concave
            end
        end
        
        %DEBUG
%         figure
%         surf (Film.mapX,Film.mapY,Film.mapZ)
%         colormap jet
%         axis equal
%         
        
    case {'aspherical'}
        
end