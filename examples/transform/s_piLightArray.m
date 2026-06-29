%% s_piLightArray
%
%  Illustrate how to create an array of light positions.
%
%  The method relies on piRotateFrom to create sample points that are
%  in a plane perpendicular to 'fromto' and through 'from'.
%
% See also
%   piRotateFrom
%   oraleye:  cubeLights, oeLights
%

%%
thisR = piRecipeDefault('scene name','chessset');

%%
direction = thisR.get('fromto');
n = 20;
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'show',true); %#ok<*ASGLU>
drawnow;

%%
% The plane is no longer perpendicular to the direction.  Why?
thisR.set('from',[0 0.2 0.2]);
direction = thisR.get('fromto');
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'show',true);
drawnow;

%%
thisR.set('from',[0 0.2 0.2]);
direction = thisR.get('fromto');
n = 20; translate = [0.2 0];
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'translate',translate,'show',true);
drawnow;

%%
thisR.set('from',[0 0.2 0.2]);
direction = thisR.get('fromto');
n = 4;
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'method','grid','show',true);
drawnow;

%%
thisR.set('from',[0 0.2 0.2]);
translate = [0.2 0];
direction = thisR.get('fromto');
n = 4;
[pts, radius] = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'method','grid','translate',translate,'show',true);
drawnow;

%%
direction = thisR.get('up');
n = 35;
pts = piRotateFrom(thisR, direction,'n samples',n, 'show',true);
drawnow;

%%
direction = [0 0 1];
n = 4;
pts = piRotateFrom(thisR, direction,'n samples',n, 'radius',1,'show',true);
drawnow;

%%
n = 5;
direction = thisR.get('up');
pts = piRotateFrom(thisR, direction,'n samples',n, 'degrees',10,'method','grid','show',true);
drawnow;

%%
thisR.set('from',[0,.3,0]);
n = 10;
pts = piRotateFrom(thisR, direction,'n samples',n);
drawnow;

%% Make a single light in the plane at the from, and then shifted

n = 1;
direction = thisR.get('fromto');
pts = piRotateFrom(thisR, direction,'n samples',n,'radius',0,'show',true);
drawnow;

%%
n = 1;
direction = thisR.get('fromto');
pts = piRotateFrom(thisR, direction,'n samples',n,'radius',0,'translate',[0.5,0],'show',true);
drawnow;

%% END