% Apply a matrix transformation  to an input vector
function [output]=paraxMatrixTransformation(M,input,varargin)


%INPUT
%input: 2xN {eccentricity,angle), N wavelengt
%M: can be a matrix or a structure (with fields: .abcd, .abcd_red)



%OUTPUT
%output:2xN {eccentricity,angle), N wavelengt

%NOTE: Default use of non-reduced quantities

%% CASE MATRIX as structure

if isstruct(M)
    rot_symmetry='true';
    %CHECK if 3x3 multiplication is need (if the matrix shows some augmented
    %parameters
    if isfield(M,'abcdef')
        vect=M.abcdef (1:2,3,:); %get augmented parameter
        if not(all(vect==0))
            rot_symmetry='quasi';
        end
    end



    for li=1:size(M.abcd,3)
        switch rot_symmetry        
            case {'true'}
                output(:,li)=M.abcd(:,:,li)*input(:,li);
            case {'quasi'}
                input3=[input(:,li),1];
                output3=M.abcdef(:,:,li)*input3;
                output(:,li)=output3(1:2); %set output
        end

    end
    
elseif not(isempty(M))
    for li=1:size(M,3)
       if  (nargin<3) 
            output(:,li)=M(:,:,li)*input(:,li);
       else
            augParam=varargin{1}; %get parameter for quasi rotattionally symmetry
            % NEW VERSION
            output(:,li)=M(:,:,li)*input(:,li)+augParam;
            %OLD VERSION
        %                 input3=[input(:,li),1];
        %                 output3=M(:,:,li)*input3;
        %                 output(:,li)=output3(1:2); %set output
        end

    end
else
    error('Not valid "matrix" element type !!')
end
    
