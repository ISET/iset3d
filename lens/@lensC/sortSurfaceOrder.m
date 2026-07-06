function sortSurfaceOrder(obj)
% Sort the lens surface array so that most negative is first
%
% The last surface should be at the 0 position.  Might check that
%
%
% AL/BW Vistasoft Copyright 2014

s        = obj.get('surface array');
nSurface = obj.get('n surfaces');

% These are the current z positions
p = zeros(nSurface,1);
for ii=1:nSurface, p(ii) = s(ii).get('zpos'); end

% Sort them, most negative will be first
[~,ix] = sort(p);

obj.set('surface array',s(ix))

return
