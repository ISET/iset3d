

function  [Pupils,varargout]=paraxFindPupils(OptSyst,pupil_type,varargin)

% Find the Pupils (entrance or exit) for an optical system
%
%       function  [Pupils,varargout]=paraxFindPupils(OptSyst,pupil_type,varargin)
%INPUT
%OptSyst: Optical system structure
%
%OUTPUT
%Pupils: pupils location for each wavelength .z_pos(NxK)
%
%NOTE:  N Sampled wavelegth; K system apertures
%
% MP Vistasoft 2014

switch pupil_type
    case {'entrance','Entrance','EntrPupil','EnP'}
        z_im=zeros(size(OptSyst.wave,1),length (OptSyst.surfs.list));
        m_lat=zeros(size(OptSyst.wave,1),length (OptSyst.surfs.list));
%         y_im=zeros(size(OptSyst.wave,1),length (OptSyst.surfs.list));
        for k=1:length (OptSyst.surfs.list)
            %find refractive indices for subsystem
           
            %Object Space 
            z_ob(k)=OptSyst.surfs.list{OptSyst.surfs.order(k)}.z_pos;
            y_ob(k)=OptSyst.surfs.list{OptSyst.surfs.order(k)}.diam/2; %height of aperture/lens rim from the optical axis
            %Define object for the subsysten
            if (k-1)>0
                %Define SubSystem refered to such object
                sub_index=OptSyst.surfs.order(1:k-1);
                if sub_index(1)==OptSyst.surfs.order(1)
                    n_ob=OptSyst.n_ob;
                else
                    space_type='object';l=1;
                    ind_obj=find(OptSyst.surfs.order==sub_index(1));
                    [n_ob]=paraxFindN4SubSyst(OptSyst,ind_obj,l,space_type);
                end
                %Image Space
                if sub_index(end)==OptSyst.surfs.order(end)
                    n_im=OptSyst.n_im;
                else
                    space_type='image';l=1;
                    ind_im=find(OptSyst.surfs.order==sub_index(end));
                    [n_im]=paraxFindN4SubSyst(OptSyst,ind_im,l,space_type);
                end
                %Create subsystem
                [subOptSyst{k}]=paraxCreateSubSyst(OptSyst,sub_index,n_ob,n_im);
                %Image Space
                t_ob=z_ob(k)-OptSyst.surfs.list{OptSyst.surfs.order(k-1)}.z_pos;
                type_conj='im2ob';
                [t_im(:,k), m_lat(:,k),m_ang(:,k)]= paraxConjImagingMatrix(subOptSyst{k},type_conj,t_ob);
                z_im(:,k)=OptSyst.surfs.list{OptSyst.surfs.order(1)}.z_pos-t_im(:,k);   

                              
            else
                %Image Space
                z_im(:,k)=z_ob(k);m_lat(:,k)=1;
                
            end  
            %Adjust Entrance pupils rims position to the augmented
            %parameter of the projected aperture (if present)
            for n=1:size(OptSyst.wave,1)
                if OptSyst.surfs.augParam.exist
                    t1=[y_ob(k)].*m_lat(n,k)+OptSyst.surfs.augParam.list{OptSyst.surfs.order(k)}(1,1);
                    t2=[-y_ob(k)].*m_lat(n,k)+OptSyst.surfs.augParam.list{OptSyst.surfs.order(k)}(1,1);
                    y_im(n,:)=[t1,t2];
                    
                else
                    y_im(n,:)=[[y_ob(k)].*m_lat(n,k),[-y_ob(k)].*m_lat(n,k)];
                end
            end
            %Set output
            EnPs{k}.z_pos=z_im(:,k);
            EnPs{k}.m_lat=m_lat(:,k);
            EnPs{k}.diam=y_im;
            

        end
        %Output 
        Pupils=EnPs;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    case {'exit','Exit','ExitPupil','ExP'}
        z_im=zeros(size(OptSyst.wave,1),length (OptSyst.surfs.list));
        m_lat=zeros(size(OptSyst.wave,1),length (OptSyst.surfs.list));        
        for k=1:length (OptSyst.surfs.list)
            %find refractive indices for subsystem
           
            %Object Space 
            z_ob(k)=OptSyst.surfs.list{OptSyst.surfs.order(k)}.z_pos;
            y_ob(k)=OptSyst.surfs.list{OptSyst.surfs.order(k)}.diam/2; %height of aperture/lens rim from the optical axis
           
            %Define object for the subsysten
            if (k)<length (OptSyst.surfs.list)
                %Define SubSystem refered to such object
                sub_index=OptSyst.surfs.order(k+1:length(OptSyst.surfs.list));
                if sub_index(1)==OptSyst.surfs.order(1)
                    n_ob=OptSyst.n_ob;
                else
                    space_type='object';l=1;
                    ind_obj=find(OptSyst.surfs.order==sub_index(1));
                    [n_ob]=paraxFindN4SubSyst(OptSyst,ind_obj,l,space_type);
                end
                %Image Space
                if sub_index(end)==OptSyst.surfs.order(end)
                    n_im=OptSyst.n_im;
                else
                    space_type='image';l=1;
                    ind_im=find(OptSyst.surfs.order==sub_index(end));
                    [n_im]=paraxFindN4SubSyst(OptSyst,ind_im,l,space_type);
                end
                %Create subsystem
                [subOptSyst{k}]=paraxCreateSubSyst(OptSyst,sub_index,n_ob,n_im);
                %Image Space
                t_ob=OptSyst.surfs.list{OptSyst.surfs.order(k+1)}.z_pos-z_ob(k);
                type_conj='ob2im';
                [t_im(:,k), m_lat(:,k),m_ang(:,k)]= paraxConjImagingMatrix(subOptSyst{k},type_conj,t_ob);
                z_im(:,k)=OptSyst.surfs.list{OptSyst.surfs.order(end)}.z_pos+t_im(:,k);
                
            else
                %Image Space
                z_im(:,k)=z_ob(k);m_lat(:,k)=1;
                
            end   
            %Adjust Exit pupils rims position to the augmented
            %parameter of the projected aperture (if present)
            for n=1:size(OptSyst.wave,1)
                if OptSyst.surfs.augParam.exist
                    t1=[y_ob(k)].*m_lat(n,k)+OptSyst.surfs.augParam.list{OptSyst.surfs.order(k)}(1,1);
                    t2=[-y_ob(k)].*m_lat(n,k)+OptSyst.surfs.augParam.list{OptSyst.surfs.order(k)}(1,1);
                    y_im(n,:)=[t1,t2];
                    
                else
                    y_im(n,:)=[[y_ob(k)].*m_lat(n,k),[-y_ob(k)].*m_lat(n,k)];
                end
            end
            %Possible Exit Pupils
            ExPs{k}.z_pos=z_im(:,k);
            ExPs{k}.m_lat=m_lat(:,k);
            ExPs{k}.diam=y_im;            
        end
        %OutPut
        Pupils=ExPs;
    case {'both'}
        
        [EnPs]=paraxFindPupils(OptSyst,'entrance',varargin);
        [ExPs]=paraxFindPupils(OptSyst,'exit',varargin);
        %Output
        Pupils=EnPs;
        varargout{1}=ExPs;
end

