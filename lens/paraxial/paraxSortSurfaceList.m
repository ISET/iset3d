

function  [index_list]=paraxSortSurfaceList(list)

% Sort the surface list along the optical axis
%
%       function  [index_list]=paraxSortSurfaceList(list)
%
%INPUT
%list: list of surface createb by paraxCreateSurface
%
%OUTPUT
%index_list: vector of the surface indices sorted along the optical axis
%
% % MP Vistasoft 2014
if length(list)==1
    z_pos(1)=list.z_pos;
else
    for j=1:length(list)
        z_pos(j)=list{j}.z_pos;
    end
end




%Sort
[z_pos_sorted,index_list]=sort(z_pos);