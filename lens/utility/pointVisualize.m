function plt = pointVisualize(obj, pName, varargin)
%% 
varargin = ieParamFormat(varargin);
p = inputParser;
p.addRequired('obj', @(x)(isa(x,'lensC')));
p.addRequired('pname', @ischar);
p.addParameter('psize', 10, @isnumeric);
p.addParameter('color', 'b', @ischar);

p.parse(obj, pName, varargin{:});

%%
pName = p.Results.pname;
pSize = p.Results.psize;
color = p.Results.color;

imP = obj.get('bbm', pName);
plt = plot(imP(1), 0, 'Marker', 'o', 'Color', color, 'MarkerSize', pSize,...
                        'LineStyle', 'none');
end
