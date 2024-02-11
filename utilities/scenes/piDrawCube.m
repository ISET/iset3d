function piDrawCube(xc, yc, zc, l, w, h)
% xc; yc; zc; coordinated of the center
% l: length;  length along x axis
% w: width    length along y axis
% h: height   length along z axis
%%
alpha=0.7;           % transparency (max=1=opaque)

X = [0 0 0 0 0 1; 1 0 1 1 1 1; 1 0 1 1 1 1; 0 0 0 0 0 1];
Y = [0 0 0 0 1 0; 0 1 0 0 1 1; 0 1 1 1 1 1; 0 0 1 1 1 0];
Z = [0 0 1 0 0 0; 0 0 1 0 0 0; 1 1 1 0 1 1; 1 1 1 0 1 1];

X = l*(X-0.5) + xc;
Y = w*(Y-0.5) + yc;
Z = h*(Z-0.5) + zc; 
color = rand(1,3);
fill3(X,Y,Z,color,'FaceAlpha',alpha);    % draw cube
axis equal