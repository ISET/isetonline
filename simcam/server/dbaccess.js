// Don't know how this works, so starting to assemble
// sample code here

const mongodb = require('mongodb');
const query = require('devextreme-query-mongodb');
const getOptions = require('devextreme-query-mongodb/options').getOptions;

// test db
mongoUri = "mongodb://seedling:49153/iset";
testCollection = "lens";

function handleError(res, reason, message, code) {
    console.error('ERROR: ' + reason);
    res.status(code || 500).json({ error: message });
  }
  
function getQueryOptions(req) {
    return getOptions(req.query, {
      areaKM2: 'int',
      population: 'int'
    });
  }

  mongodb.MongoClient.connect(mongoUri, function(err, database) {
    if (err) {
      console.error(err);
      process.exit(1);
    }
  
    //app.get('/countries', function(req, res) {
    //  getData(database.collection('countries'), req, res);
    //});
  
    console.log('Database connection ready');
  }  


module.exports = getData