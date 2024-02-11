function rgb = piColorPick(color,varargin)
% Choose a pre-defined color or randomly pick one of the list
%
% Syntax
%  rgb = piColorPick(color,varargin)
%
% Description
%   For the moment, there is randomization of the returned color.  We
%   get something in the range.  We are going to create a key/value
%   pair that sets the randomization range or that turns off
%   randomization of the returned color.
%
% Inputs
%    color:  'red','blue','white','black','silver','yellow','random'
%
% Key/value pairs
%     N/A yet
%
% Outputs
%   rgb - red green blue triplet
%
% Zhenyi
%
% See also
%   piMaterialAssign
%
%{
for ii = 1:100
color = piColorPick('random');
x = [0 1 1 0];
y = [ii-1 ii-1 ii ii];
patch(x,y,color);
end
%}

%% Parse

% colorlist = {'white','black','red','blue','silver','yellow'};

%%

if piContains(color,'random')
    % Choose a random color, I guess.
    index = rand;
    
    if index <= 0.21, color = 'white';end
    if index > 0.21 && index <= 0.4, color = 'black';end
    if index > 0.4 && index <= 0.5, color = 'red';end
    if index > 0.5  && index <= 0.58, color = 'blue';end
    if index > 0.58 && index <= 0.62, color = 'green';end
    if index > 0.62 && index <= 0.77, color = 'grey';end
    if index > 0.77 && index <= 0.83, color = 'brown';end
    if index > 0.83 && index <= 0.98, color = 'silver';end
    if index > 0.98 && index <= 1, color = 'others';end
    rgb = colorswitch(color);
else
    rgb = colorswitch(color);    
end

end
% We find some good color which are used for carpaint.
% (https://encycolorpedia.com)

function rgb = colorswitch(color)

switch color
    case 'white'

        colorList = 'efede8 f5f5ff fdfef6 fcfcfc f1f3f1';        
    case 'black'
        colorList = '010101 010203 100c08 141414';
    case 'red'
        % https://encycolorpedia.com/cd4137 
        colorList = ['b32824 bb302a c43931 cd4137 ' ...
            'd6493d df5144 e8594b cc3333 e03124 ' ...
            'a6322a d03e35 cd3f33'];
    case 'blue'
        colorList = ['003bda 0040e1 0046e8 0e4bef ' ...
            '2450f6 3356fd 3f5cff 1077d1 1a3bd8'];

    case 'green'
        colorList = ['229658 30a161 3dab6b 49b675 ' ...
            '55c17f 60cc89 6bd793'];

    case 'others'
        colorList = ['cbbd00 ffff3d ' ...
            '00ffef 00ffff fbcce7 ' ...
            'c54e06 c1432c ce5171 ffa600 c05fa2'];

    case 'silver'
        colorList = ['67737c 707c84 78848d 818d96 ' ...
            '8a969f 939fa8 9ba8b1 818d96 818e95 ' ...
            '7e8890 80939d'];
    case {'gray','grey'}
        colorList = ['d5d5d5 d3d3d2 d4d5d4 d1d1d1 d0d2d1 ' ...
            'd9dad8 d4d9d7 757575 7e7e7e 878787 909090 ' ...
            '999999 a2a2a2 acacac 8e9294'];
    case 'brown'
        colorList = ['462d14 593a27 59260b 3d250c 40280f ' ...
            '432a12 462d14 493017 4c3219 4f351c ' ...
            'ae9870 dbbe88 a37063'];
end

thisColor = getRandomColor(colorList);

rgb = hex2rgb(thisColor);


% rgb = [r/255 g/255 b/255];
% Add some randomness
rgb(1) = rgb(1)+rand(1)/255;
rgb(2) = rgb(2)+rand(1)/255;
rgb(3) = rgb(3)+rand(1)/255;
% clamp the output rgb
rgb(1) = max(min(rgb(1),0.9999),0.0001);
rgb(2) = max(min(rgb(2),0.9999),0.0001);
rgb(3) = max(min(rgb(3),0.9999),0.0001);

end

%%
function thisColor = getRandomColor(colorList)
        colorCode = split(colorList, ' ');
        index = randi(numel(colorCode));
        thisColor = colorCode{index};
end






