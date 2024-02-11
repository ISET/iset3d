function hash = hashStruct(inputS)
    if isfield(inputS,'hash')
        inputS = rmfield(inputS,'hash');
    end
    if isfield(inputS,'createdat')
        inputS = rmfield(inputS,{'createdat','updatedat','size', ...
            'filepath','description','createdby','updatedby'});
    end
    % Convert the struct to a JSON string
    jsonString = jsonencode(inputS);
    
    % Create a Java MessageDigest instance for SHA-256
    md = java.security.MessageDigest.getInstance('SHA-256');
    
    % Update the digest using the UTF-8 byte representation of the JSON string
    md.update(uint8(jsonString));
    
    % Complete the hash computation
    hashBytes = md.digest();
    
    % Convert the hash bytes to a hexadecimal string
    hash = sprintf('%02x', typecast(hashBytes, 'uint8'));
end


