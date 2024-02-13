function hash = hashStruct(inputS)
    % Check if 'hash' field exists and remove it to avoid hashing the hash
    if isfield(inputS, 'hash')
        inputS = rmfield(inputS, 'hash');
    end

    % Check if 'createdat' field exists; if so, remove specific fields
    % This step ensures that metadata fields do not affect the hash
    if isfield(inputS, 'createdat')
        fieldsToRemove = {'createdat', 'updatedat', 'sizeInMB', ...
                          'filepath', 'description', 'createdby', 'updatedby'};
        inputS = rmfield(inputS, fieldsToRemove);
    end

    % Convert the modified struct to a JSON string for consistent hashing
    jsonString = jsonencode(inputS);

    % Initialize a SHA-256 MessageDigest instance to compute the hash
    md = java.security.MessageDigest.getInstance('SHA-256');

    % Update the MessageDigest with the JSON string's byte representation
    md.update(uint8(jsonString)); % JSON string is converted to UTF-8 bytes

    % Complete the hash computation and get the result as byte array
    hashBytes = md.digest();

    % Convert the byte array to a hexadecimal string to represent the hash
    hash = sprintf('%02x', typecast(hashBytes, 'uint8'));
end


