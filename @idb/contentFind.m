function documents = contentFind(obj,collection, struct)

queryString = queryConstruct(struct);
try
    if isempty(struct)
        documents = find(obj.connection, collection);
    else
        documents = find(obj.connection, collection, Query = queryString);
    end
catch
    documents = [];
end
end

