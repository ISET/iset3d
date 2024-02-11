function rBump = retinalBump(x,y,center,sigma)
% Create a bump to add onto the retinal surface

rBump = exp(- ((x-center(1))^2+(y-center(2))^2 ) / (2*sigma^2) );
% mesh(rBump)
end