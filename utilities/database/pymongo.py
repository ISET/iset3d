import subprocess
import sys
import os

def install(package):
    subprocess.check_call([sys.executable, "-m", "pip", "install", package,"--user"])

try:
    from pymongo import MongoClient
except ImportError:
    install('pymongo')
    from pymongo import MongoClient
    
class pyMongoDBManager:
    def __init__(self, server):
        """
        Initialize the pyMongoDBManager with a server URI.
        """
        self.client = MongoClient(server)
    
    def insert_document(self, db_name, collection_name, document):
        """
        Insert a document into a specified collection.
        """
        db = self.client[db_name]
        collection = db[collection_name]
        insert_result = collection.insert_one(document)
        return str(insert_result.inserted_id)

    def list_unique_values(self, db_name, collection_name, field_name):
        """
        List all unique values for a given field in a collection.
        """
        db = self.client[db_name]
        collection = db[collection_name]
        unique_values = collection.distinct(field_name)
        return unique_values


