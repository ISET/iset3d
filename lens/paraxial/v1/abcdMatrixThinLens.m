function OptSys=abcdMatrixThinLens(OptSys);

%% Compute the abcd Matrix (Optical system matrix through teh all spectrum ) of for a Thin Lens  and if related
%features. Compute also the optical power of each refr. surface

%% INPUT
%OptSys
%% OUTPUT
%OptSys

if size(OptSys.N,2)==size(OptSys.R,2)
  %Compute the refractive power for each surface
 opw=(OptSys.N-OptSys.n_obj)./OptSys.R;
 %Compute the refractive matrix transf for the surface
  refMat=refractiveMatrix(opw);
else
    opw=[];refMat=[];transMat=[];
end


%% Compute the (abcd) Matrix for that optical system

%METHOD : FOR Cicle
for p=1:length(OptSys.wl)
    abcd(:,:,p)=eye(2,2);
    for i=length(OptSys.R):-1:1
        if i~=1
            abcd(:,:,p)=abcd(:,:,p)*refMat(:,:,p,i)*transMat(:,:,p,i-1);
        else
            abcd(:,:,p)=abcd(:,:,p)*refMat(:,:,p,i);
        end 
    end
end
%Transformation matrix
OptSys.abcd=abcd;

%Cardinal point ( for each save position and shift from first or last
%vertex)
[OptSys.Fo,OptSys.Fi,OptSys.Ho,OptSys.Hi,OptSys.No,OptSys.Ni]=abcd2cardpoints(OptSys.abcd,OptSys.n_obj,OptSys.n_im);
% Related features
OptSys.efl=reshape(-1./abcd(2,1,:),size(OptSys.Fi,1),size(OptSys.Fi,2)); %effective focal lenght
OptSys.bfl=OptSys.Fi;%back focal length  bfl=dz_fi
OptSys.ffl=OptSys.Fo;%front focal length ffl=dz_fo








% %% CHECK Not Empty N (refractive index vector) 
% if isempty(OptSys.V)
%     abcd=[];
%     %Transformation matrix
%     OptSys.abcd=abcd;
% 
%     %Cardinal point ( for each save position and shift from first or last
%     %vertex)
%     OptSys.Fo=[];OptSys.Fi=[];OptSys.Ho=[];OptSys.Hi=[];OptSys.No=[];OptSys.Ni=[];
%     %and  Related features
%     OptSys.efl=[]; %effective focal lenght
%     OptSys.bfl=OptSys.Fi;%back focal length  bfl=dz_fi
%     OptSys.ffl=OptSys.Fo;%front focal length ffl=dz_fo
% else
%     %% PRE-TRANSFORM CALCULATIONs
%     %Set a vector of all the refractive index
%     %check homogenity at boundary condition 
% 
%     if (OptSys.n_obj==OptSys.N(:,1))
%         vett_obj=[];
%     else
%         vett_obj=OptSys.n_obj;
%     end
% 
%     if OptSys.n_im==OptSys.N(:,end)
%         vett_im=[];
%     else
%         vett_im=OptSys.n_im;
%     end
%     vett_N=[vett_obj,OptSys.N,vett_im];
%     % vett_N=[OptSys.n_obj,OptSys.N,OptSys.n_im];
%     %Compute the refractive power for each surface
%     opw=optPower(vett_N(:,1:end-1),vett_N(:,2:end),OptSys.R);
%     %Compute the refractive matrix transf for each surface
%     refMat=refractiveMatrix(opw);
%     %Compute the  translation matrix transf for the surface distance
%     transMat=translationMatrix(OptSys.th,vett_N(2:end-1));
% 
%     %Append findings
%     OptSys.opw=opw;OptSys.refMat=refMat; OptSys.transMat=transMat;
% 
% 
%     %% Compute the (abcd) Matrix for that optical system
% 
%     %METHOD : FOR Cicle
%     for p=1:length(OptSys.wl)
%         abcd(:,:,p)=eye(2,2);
%         for i=length(OptSys.R):-1:1
%             if i~=1
%                 abcd(:,:,p)=abcd(:,:,p)*refMat(:,:,p,i)*transMat(:,:,p,i-1);
%             else
%                 abcd(:,:,p)=abcd(:,:,p)*refMat(:,:,p,i);
%             end 
%         end
%     end
%     %Transformation matrix
%     OptSys.abcd=abcd;
% 
%     %Cardinal point ( for each save position and shift from first or last
%     %vertex)
%     [OptSys.Fo,OptSys.Fi,OptSys.Ho,OptSys.Hi,OptSys.No,OptSys.Ni]=abcd2cardpoints(OptSys.abcd,OptSys.n_obj,OptSys.n_im);
%     % Related features
%     OptSys.efl=reshape(-1./abcd(2,1,:),size(OptSys.Fi,1),size(OptSys.Fi,2)); %effective focal lenght
%     OptSys.bfl=OptSys.Fi;%back focal length  bfl=dz_fi
%     OptSys.ffl=OptSys.Fo;%front focal length ffl=dz_fo
% end












