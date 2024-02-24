function queryString = queryConstruct(s)
    % Initialize the query string with the opening curly brace
    queryString = '{';

    % Get the field names of the struct
    fields = fieldnames(s);

    % Iterate over each field to append to the query string
    for i = 1:length(fields)
        fieldName = fields{i};  % Current field name
        fieldValue = s.(fieldName);  % Current field value
        % Format the field value based on its type
        if ischar(fieldValue) || isstring(fieldValue)
            % For string values, add quotes around the value
            fieldValueFormatted = sprintf('"%s"', fieldValue);
        elseif isnumeric(fieldValue)
            % For numeric values, convert to string without quotes
            fieldValueFormatted = num2str(fieldValue);
        elseif islogical(fieldValue)
            % Convert logical values to lowercase true/false without quotes
            fieldValueFormatted = lower(mat2str(fieldValue));
        else
            error('Unsupported field value type. Only strings, numerics, and logicals are supported.');
        end

        % Append the current field and its value to the query string
        queryString = sprintf('%s"%s": %s', queryString, fieldName, fieldValueFormatted);

        % If not the last field, add a comma separator
        if i < length(fields)
            queryString = sprintf('%s, ', queryString);
        end
    end

    % Close the query string with the closing curly brace
    queryString = sprintf('%s}', queryString);
end
