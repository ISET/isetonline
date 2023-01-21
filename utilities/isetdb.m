function dbObject = isetdb()
%ISETDB Open default ISET database

try 
    dbObject = idb.ISETdb();
catch
    warning(" Unable to open db, make sure you have prefs 'db', 'server' and 'db' 'port' set.");
    dbObject = [];
end

