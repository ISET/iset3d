

function  [t_out, varargout]= paraxConjImagingMatrix(Syst,type_conj,t_in,varargin)

%%Find Gaussian Point for a  Optical system decribed in conjugate condition
%
%       function  [t_out, varargout]= paraxConjImagingMatrix(Syst,type_conj,t_in,varargin)
%
%INPUT
%Syst: structure (Optical System or Sub System)
%type_conj: define if we are looking for the image distance (given the
%object distance) or for the object distance (given the image distance)
%t_in: distance used as input , case t_obj : distance from object to first
%vertex of the system or t_im: distance from last vertex of the system and
%the image.
%varargin:  {1} field eccentricity(needs when object located ad infinity
%
%OUTPUT
%t_out: distance as output of the conjugate functions
%varargout{1}: .m_lat: lateral magnification (case direct obj->imag); inverse lateral magnification (case inverse imag->obj)
%varargout{2}: .m_ang: angular magnification  (case direct obj->imag); inverse lateral magnification (case inverse imag->obj)
%
% MP Vistasoft 2014


switch type_conj
    
    case {'object','obj','ob','obj2im','ob2im','object2image'}
        %through REDUCED matrix
        Mred=Syst.matrix.abcd_red;ared=squeeze(Mred(1,1,:));bred=squeeze(Mred(1,2,:));cred=squeeze(Mred(2,1,:));dred=squeeze(Mred(2,2,:));
        n_im=Syst.n_im;n_ob=Syst.n_ob;
        t_ob=t_in;
        if abs(t_ob)<Inf
            Num=(ared.*t_ob./n_ob+bred);
            Den=(cred.*t_ob./n_ob+dred);        
            t_im=-n_im.*(Num)./(Den);
            if nargout>1
                varargout{1}=ared+cred.*(t_im./n_im); %lateral magnification
                varargout{2}=n_ob./n_im.*(dred + t_ob./n_ob.*cred); %angular magnification
            end
        else
            t_im=Syst.cardPoints.dFi; %set at focal point
            t_im=paraxGet(Syst,'image focal point'); %set at focal point
            if nargout>1
                if nargin>3
                    u_ecc=varargin{1};
                    varargout{2}=n_ob./n_im; %angular magnification
                    height=varargout{2}.*Syst.cardPoints.fi.*tan(u_ecc); %for proof see "Lens Design Fundamental 2nd Ed., pag 64
                    varargout{1}=height; % image size
                    
                else
                    error('Object at Infinity! Mantatory to specify angular field')
                end
                
            end
        end
        
        % SET OUTPUT
        t_out=t_im;
        
        
        %through NOT-REDUCED matrix
%         M=Syst.matrix.abcd;a=squeeze(M(1,1,:));b=squeeze(M(1,2,:));c=squeeze(M(2,1,:));d=squeeze(M(2,2,:));
%         n_im=Syst.n_im;n_ob=Syst.n_ob;
%         t_ob=t_in;
%         Num=(a.*t_ob+b);
%         Den=(c.*t_ob+d);
%         t_im=-(Num)./(Den);
        
        % SET OUTPUT
%         t_out=t_im;
%         if nargout>1
%             varargout{1}=a+c.*(t_out); %lateral magnification
%             varargout{2}=(d + t_ob.*cred); %angular magnification
%         end
        
    case {'image','im','ima','im2obj','im2ob','image2object'}
        %through REDUCED matrix
        Mred=Syst.matrix.abcd_red;ared=squeeze(Mred(1,1,:));bred=squeeze(Mred(1,2,:));cred=squeeze(Mred(2,1,:));dred=squeeze(Mred(2,2,:));
        n_im=Syst.n_im;n_ob=Syst.n_ob;
        t_im=t_in;
        if abs(t_im)<Inf
            Num=(bred+dred.*t_im./n_im);
            Den=(ared+cred.*t_im./n_im);
            t_ob=-n_ob.*(Num)./(Den);
            if nargout>1
                varargout{1}=1./(ared+cred.*(t_im./n_im)); %inverse lateral magnification
                varargout{2}=1./(n_ob./n_im.*(dred + t_ob./n_ob.*cred)); % inverse angular magnification
            end
        else
            t_ob=Syst.cardPoints.dFo; %set at focal point
            if nargout>1
                if nargin>3
                    u_ecc=varargin{1};
                    varargout{2}=n_im./n_ob; %angular magnification
                    height=varargout{2}.*Syst.cardPoints.fo.*tan(u_ecc); %for proof see "Lens Design Fundamental 2nd Ed., pag 64
                    varargout{1}=height; % image size
                else
                    error('Object at Infinity! Mantatory to specify angular field')
                end
                
            end
        end
        
         % SET OUTPUT
        t_out=t_ob;
        
        
%         through NOT-REDUCED matrix
%         M=Syst.matrix.abcd;a=squeeze(M(1,1,:));b=squeeze(M(1,2,:));c=squeeze(M(2,1,:));d=squeeze(M(2,2,:));
%         n_im=Syst.n_im;n_ob=Syst.n_ob;
%         Num=(b+d.*t_im);
%         Den=(a+c.*t_im./n);
%         t_out=-*(Num)./(Den);

         % SET OUTPUT
%         t_out=t_ob;
%         if nargout>1
%             varargout{1}=1./(a+c.*(t_im)); %inverse lateral magnification
%             varargout{2}=1./(d + t_ob.*c); % inverse angular magnification
%         end
        
end


