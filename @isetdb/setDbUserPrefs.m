function setDbUserPrefs()
%SETUSERPREFS Set up the 'db' preference group
%
siteDefaultFile=fullfile(piRootPath,'local/config','isetDbVals.json');
siteDbVals = readstruct(siteDefaultFile);

prefGroupName = "db";
curVals = isetdb(noconnect=true);
props = properties(curVals);
props = props(startsWith(props,"db"));

for ii = 1:numel(props)
    newvals.(props{ii}) = curVals.(props{ii});
end



fprintf("\nCurrent isetdb user preferences:\n");
fprintf("-------------------------------\n");

while true
    %show the current prefs
    listVals(newvals);
    UpdateChoice = input("Do you want to change them? [y/n/q]: ", "s");
    if strcmpi(UpdateChoice, 'y')
        % go through update dialog
        for ii=1:numel(props)
        %    if strcmp(props{ii}, "connection")
        %        continue;
        %    end
            fprintf("\nChoose a %s value:\n", props{ii});
            fprintf("0) %s\t(current value)\n", newvals.(props{ii}));
            choices = siteDbVals.(props{ii});
            for i=1:numel(choices)
                fprintf("%i) %s\n",i, choices(i));
            end
            fprintf("%i) Other\n\n", i+1);
        %loop here
            answer = NaN;
            while ~(answer >= 0 && answer <= i+1)
                answer = input(sprintf("Choose a %s value (0-%i): ", props{ii}, i+1), "s");
                if strcmp(answer,'')
                    answer = 0;
                else
                    answer = double(string(answer));
                end
            end
            
            switch answer
                case 0
                    newvals.(props{ii}) = curVals.(props{ii});
                case i + 1
                    newvals.(props{ii}) = ...
                        input(sprintf("Enter custom %s value: ", props{ii}),"s");
                otherwise
                    newvals.(props{ii}) = siteDbVals.(props{ii})(answer);
            end
        %loop here
            fprintf("New value: %s\n\n", newvals.(props{ii}));
            % we could add checking here
        end
        % we could add more sophisticated checking here or we could do it
        % in a function which sets up the site values
 
    elseif strcmpi(UpdateChoice, 'n')
        break
    elseif strcmpi(UpdateChoice, 'q')
        fprintf("\nLeaving preferenceces unchanged\n");
        return
    else
        continue
    end
    fprintf("\nNew isetdb user preferences:\n");
    fprintf("---------------------------\n\n");
end
saveprefs = input(sprintf("Write out these values? [y/n]: "),"s");
if strcmpi(saveprefs,"y")
    fprintf("\nSaving Preferences\n");
    for ii=1:numel(props)
        fprintf("%s: %s\n",props{ii},newvals.(props{ii}));
        setpref(prefGroupName,props{ii},newvals.(props{ii}));
    end
else
    fprintf("Leaving Preferences unchanged\n");
end
end

function listVals(vals)

    fields = fieldnames(vals);
    for ii = 1:numel(fields)
          fprintf("%s :\t%s\n", fields{ii}, vals.(fields{ii}));
    end
    fprintf("\n");
end