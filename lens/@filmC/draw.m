function draw(film)
% Draw a line at the film position on the current figure
%
% Syntax:
%    filmC.draw
%
% Description
%   Draws the film plane as a green dashed line.  Makes sure that the xaxis
%   is long enough to show the film plane.
%
% Inputs
%   obj:  filmC object
%
% Optional key/value
%   N/A
%
% Return
%   N/A
%
% See also
%   rayC.recordOnFilm

if isa(film,'filmSphericalC')
    disp('Draw semi-circle')
else
    x = film.position(3);
    y = film.size(2);
    
    % Make the film at least 2mm high
    y = max(y,1);
    line([x x],[-0.5 0.5]*y,'Color','g','linestyle','--','Linewidth',2);
    
    % Make sure the x-axis extends to the film plane
    xlim = get(gca,'xlim');
    xlim(2) = x + 1;
    set(gca,'xlim',xlim);
end

end
