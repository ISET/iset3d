function tMatrix = piTransformCompose(T, R, S)
% Create transform matrix from translation, rotation and scale
% Zhenyi, 2022

m = eye(4);
mT = Translate(m, T);
mS = Scale(m, S);

alpha = R(1,3); % X
beta = R(1,2); % Y
gamma = R(1,1); % Z

% XYZ Euler
R = [cosd(gamma)*cosd(beta), cosd(gamma)*sind(beta)*sind(alpha)-sind(gamma)*cosd(alpha), cosd(gamma)*sind(beta)*cosd(alpha)+sind(gamma)*sind(alpha),0;
    sind(gamma)*cosd(beta), sind(gamma)*sind(beta)*sind(alpha)+cosd(gamma)*cosd(alpha), sind(gamma)*sind(beta)*cosd(alpha)-cosd(gamma)*sind(alpha),0
    -sind(beta), cosd(beta)*sind(alpha), cosd(beta)*cosd(alpha),0;
    0,0,0,1];

tMatrix = mT*R*mS;
end

function m = Translate(m, T)
m(1,4) = T(1); % x
m(2,4) = T(2); % y
m(3,4) = T(3); % z
end

function m = Scale(m, S)
m(1,1) = m(1,1) * S(1); % x
m(2,2) = m(2,2) * S(2); % y
m(3,3) = m(3,3) * S(3); % z
end






