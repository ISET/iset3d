function msg = validationMessage(report)
% validationMessage Format an ISETDocker validation report for display.

parts = strings(0,1);

if isfield(report, 'errors') && ~isempty(report.errors)
    parts(end+1,1) = "ISETDocker validation errors:";
    parts = [parts; "  " + report.errors(:)];
end

if isfield(report, 'warnings') && ~isempty(report.warnings)
    parts(end+1,1) = "ISETDocker validation warnings:";
    parts = [parts; "  " + report.warnings(:)];
end

if isfield(report, 'repairCommands') && ~isempty(report.repairCommands)
    parts(end+1,1) = "Suggested fix:";
    parts = [parts; "  " + report.repairCommands(:)];
end

if isempty(parts)
    parts = "ISETDocker validation passed.";
end

msg = char(strjoin(parts, newline));

end
