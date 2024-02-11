function getParam(obj)
%getParam - Deprecated.
%
disp(obj)

warning('getParam is Deprecated.  To see the parameters, inspect the dockerWrapper.')

end

%{
if isempty(paramName)
    % Print a summary of all the params
    retVal = getpref('docker');
    fields = fieldnames(retVal);
    fprintf('Docker field values\n________________\n\n');
    for ii=1:numel(fields)
        switch(class(retVal.fields{ii}))
            case 'logical'
                fprintf('%s\t\t%d\n',fields{ii},retVal.fields{ii});
            case 'char'
                fprintf('%s\t\t%s\n',fields{ii},retVal.fields{ii});
            otherwise
                fprintf('%s\t\t%f\n',fields{ii},retVal.fields{ii});
        end
    end

else
    retVal = getpref('docker',paramName, '');
end

end

%}
