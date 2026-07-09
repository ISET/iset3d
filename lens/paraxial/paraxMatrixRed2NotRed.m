% Convert Reduced Matrix to Not Reduced Matrix

function  [M]=paraxMatrixRed2NotRed(M_red,n_ob,n_im);

%INPUT
%M_red: 2x2xN or 3x3xN for augmented matrix
%n_ob: column vector (N element) refractive index of the object space
%n_im: column vector (N element) refractive index of the image space

%N sampled wavelength- reduced parameters

%OUTPUT
%M: (2x2xN): N sampled wavelength

%% CHECK sampling of the matrix
Mred_size=size(M_red,3);nob_size=size(n_ob,1);nim_size=size(n_im,1);

if not((Mred_size==nob_size)&&(Mred_size==nim_size))
    if nob_size==1
        n_ob=repmat(n_ob,Mred_size,1);
    else
        warning('Missmatching on the sampling between matrix and refr. index of object space !!')    
    end
    if nim_size==1
        n_im=repmat(n_im,Mred_size,1);
    else
        warning('Missmatching on the sampling between matrix and refr. index of image space !!')    
    end
end

%% Compute matrix coeffs 
%% Differentiate between 2x2xN matrix or 3x3xN augmented matrix
%      |a  b|                |a  b  e|
%   M= |c  d|            M=  |c  d  f|
%                            |0  0  1|
switch size(M_red,1)
    case 3
        a_red=M_red(1,1,:);b_red=M_red(1,2,:);c_red=M_red(2,1,:);d_red=M_red(2,2,:);
        e_red=M_red(1,3,:);f_red=M_red(2,3,:);
        %adapt matrix dimensions
        a_red=squeeze(a_red);b_red=squeeze(b_red);c_red=squeeze(c_red);d_red=squeeze(d_red);
        e_red=squeeze(e_red);f_red=squeeze(f_red);

        %Not reduced Matrix
        a=a_red; b=b_red.*n_ob;
        c=c_red./n_im; d=d_red.*(n_ob)./(n_im);
        e=e_red; f=f_red./n_im;

        for i=1:Mred_size
            M(1,1,:)=a;M(1,2,:)=b;
            M(2,1,:)=c;M(2,2,:)=d;
            M(1,3,:)=e; M(2,3,:)=f;
            M(3,1:2,:)=0;M(3,3,:)=1;
        end 
        
    case 2       
        a_red=M_red(1,1,:);b_red=M_red(1,2,:);c_red=M_red(2,1,:);d_red=M_red(2,2,:);
        a_red=squeeze(a_red);b_red=squeeze(b_red);c_red=squeeze(c_red);d_red=squeeze(d_red);

        %Not reduced Matrix
        a=a_red; 
        b=b_red.*n_ob;
        c=c_red./n_im;
        d=d_red.*(n_ob)./(n_im);

        for i=1:Mred_size
            M(1,1,:)=a;M(1,2,:)=b;
            M(2,1,:)=c;M(2,2,:)=d;
        end 
    otherwise
        warning('The input matrix does not match with the requirement: 2x2(centered system) or 3x3(not-centered system)!')
end




