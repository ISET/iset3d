%% s_triangulationsScratch

% Thinking about mesh triangulations for ISET3d
thisR = piRecipeCreate('lettersatdepth');


%% Example where we can get the points from each of the meshes
objects = thisR.get('objects');

% First column is xmin/max, 2nd is ymin/max
mnmx = zeros(2,3);
for jj=1:numel(objects)
    thisSize = thisR.get('asset',objects(jj),'size');
    thisPos  = thisR.get('asset',objects(jj),'world position');
    % names{jj} = thisR.get('asset',objects(jj),'name');
    thisSpan = thisPos + thisSize;
    mnmx(1,:) = min(min(mnmx),thisSpan); 
    mnmx(2,:) = max(max(mnmx),thisSpan);
end

%%
mnmx = zeros(2,3);
pts = zeros(8,3);
ieNewGraphWin;
hold on;
for jj=1:numel(objects)
    thisSize = thisR.get('asset',objects(jj),'size');
    thisPos  = thisR.get('asset',objects(jj),'world position');

    mnmx(1,:) = thisPos + 0.5*thisSize;   
    mnmx(2,:) = thisPos - 0.5*thisSize;
    mnmx = sort(mnmx);

    % Make a bounding box from the min max values
    % This could be a function for each object.  Then we plot the bb for
    % some objects.
    pts(1,:) = [mnmx(1,1),mnmx(1,2),mnmx(1,3)];
    pts(2,:) = [mnmx(1,1),mnmx(2,2),mnmx(1,3)];
    pts(3,:) = [mnmx(2,1),mnmx(2,2),mnmx(1,3)];
    pts(4,:) = [mnmx(2,1),mnmx(1,2),mnmx(1,3)];
    pts(5,:) = [mnmx(1,1),mnmx(1,2),mnmx(2,3)];
    pts(6,:) = [mnmx(1,1),mnmx(2,2),mnmx(2,3)];
    pts(7,:) = [mnmx(2,1),mnmx(2,2),mnmx(2,3)];
    pts(8,:) = [mnmx(2,1),mnmx(1,2),mnmx(2,3)];

    k = boundary(pts);
    trisurf(k,pts(:,1),pts(:,2),pts(:,3));
    hold on;
    plot3(pts(:,1),pts(:,2),pts(:,3),'ko')
end

look = thisR.get('lookat'); 
plot3(look.from(1),look.from(2),look.from(3),'go');
plot3(look.to(1),look.to(2),look.to(3),'rx');
grid on
axis equal

%%
sh = thisR.get('asset',objects(jj),'shape');


thisShape = sh{1};

p3 = thisShape.point3p;

n = numel(p3);
p3 = reshape(p3,n/3,3);
p3 = double(p3);

cList = double(thisShape.integerindices);
n = numel(cList);
cList = reshape(cList,n/3,3) + 1;

TR = triangulation(cList,p3);

ieNewGraphWin;
trimesh(TR);




