function [OptSys]=sortVertices(OptSys)

%% Sort the refractive surfaces (Radius, diameter and vertex) according to the vertices position along z-axis 
% Refractive Index vector is NOT SORTED
%% INPUT
%OptSys
%% OUTPUT
%OptSys

%% COMPUTE
%Sort the vertices
OptSys_V0=OptSys.V;
[OptSys.V, index]=sort(OptSys.V); 
% if index==[1:length(index)]
if OptSys.V==OptSys_V0
    return
else
    OptSys.R=OptSys.R(index);
    OptSys.A=OptSys.A(index);
end



