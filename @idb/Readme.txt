DB

mongoDB

-> Data Storage for persistent ISET data
-> db itself contains metadata and 'small' objects (lenses, 
   sensors without data, etc.)
-> It also contains file paths, typically on a file server

-> To use with ISETAuto you'll need to either have the local
   Vistalab datastore (/acorn/data) mounted, or use iaDataRoot()
   with an argument to provide your own file data location.





