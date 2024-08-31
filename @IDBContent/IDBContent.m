classdef IDBContent < handle
    properties
        type        % Type of content (e.g., 'image', 'document')
        category    % Category of the content (e.g., 'landscape', 'report')
        name        % Name of the content
        sizeInMB    % Size of the content in MB
        mainfile    % Main file associated with the content
        filepath    % File path where the content is stored
        description % Description of the content
        format      % Format of the content (e.g., 'jpg', 'pdf')
        createdat   % Creation date of the content
        updatedat   % Last updated date of the content
        createdby   % Creator of the content
        updatedby   % Person who last updated the content
        author      % Author of the content
        tags        % Tags associated with the content (as a cell array)
        source      % Source of the content (e.g., 'photograph', 'generated')
    end
    
    methods
        % Constructor method to initialize the IDBContent object
        function obj = IDBContent(parameters)
            % Initialize the specific properties for IDBContent
            if nargin > 0
                obj.type = parameters.type;
                obj.category = parameters.category;
                obj.name = parameters.name;
                obj.sizeInMB = parameters.sizeInMB;
                obj.mainfile = parameters.mainfile;
                obj.filepath = parameters.filepath;
                obj.description = parameters.description;
                obj.format = parameters.format;
                obj.createdat = parameters.createdat;
                obj.updatedat = parameters.updatedat;
                obj.createdby = parameters.createdby;
                obj.updatedby = parameters.updatedby;
                obj.author = parameters.author;
                obj.tags = parameters.tags;
                obj.source = parameters.source;
            end
        end
        
        % Method to remove fields with empty values
        function obj = removeEmptyFields(obj)
            % Get a list of all property names
            propNames = properties(obj);
            
            % Iterate over all properties and remove those with empty values
            for i = 1:length(propNames)
                propName = propNames{i};
                if isempty(obj.(propName))
                    obj.(propName) = [];
                end
            end
        end
        
        % Method to display all content information
        function displayFullInfo(obj)
            disp('Content Information:');
            disp(['Type: ', obj.type]);
            disp(['Category: ', obj.category]);
            disp(['Name: ', obj.name]);
            disp(['Size: ', num2str(obj.sizeInMB), ' MB']);
            disp(['Main File: ', obj.mainfile]);
            disp(['File Path: ', obj.filepath]);
            disp(['Format: ', obj.format]);
            disp(['Created At: ', obj.createdat]);
            disp(['Updated At: ', obj.updatedat]);
            disp(['Created By: ', obj.createdby]);
            disp(['Updated By: ', obj.updatedby]);
            disp(['Author: ', obj.author]);
            disp(['Tags: ', strjoin(obj.tags, ', ')]);
            disp(['Source: ', obj.source]);
        end
    end
end