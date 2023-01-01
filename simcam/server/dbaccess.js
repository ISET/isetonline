// Starting to assemble test/sample code here
//
// David Cardinal, Stanford University, 2023
// 

// Just add '-legacy' to my mongodb import
const MongoClient = require("mongodb-legacy").MongoClient;
const query = require("devextreme-query-mongodb");
// const client = new MongoClient()
// const db = client.db();
// const collection = db.collection('pets');

const mongodb = require('mongodb-legacy')
// const MongoClient = require("mongodb").MongoClient;
const getOptions = require('devextreme-query-mongodb/options').getOptions;

// test db
const mongoUri = "mongodb://seedling:49153/iset";


function handleError(res, reason, message, code) {
    console.error('ERROR: ' + reason);
    res.status(code || 500).json({ error: message });
}

function getQueryOptions(req) {
    return getOptions(req.query, {
        name: 'string',
        description: 'string'
    });
}

async function getData(testCollection, req, res) {
    try {
        const options = getQueryOptions(req);
        if (options.errors.length > 0) {
            console.error('Errors in query string: ', JSON.stringify(options.errors));
        }
        MongoClient.connect(mongoUri,  async (err, db) => {
            const results = await query(
                db.collection("lens"),
                options.loadOptions,
                options.processingOptions
            );
            res.status(200).jsonp(results);

        });
    
    } catch (err) {
        handleError(res, err, 'Failed to retrieve data');
    }
}

// EXAMPLE CODE PASTED HERE TO CHECK SYNTAX
async function queryData() {
    MongoClient.connect("mongodb://localhost:27017/testdatabase", (err, db) => {
      const results = await query(db.collection("values"), {
        // This is the loadOptions object - pass in any valid parameters
        take: 10,
        filter: [ "intval", ">", 47 ],
        sort: [ { selector: "intval", desc: true }]
      });
  
      // Now "results" contains an array of ten or fewer documents from the
      // "values" collection that have intval > 47, sorted descendingly by intval.
    });
  }
  
function connectDB() {
    mongodb.MongoClient.connect(mongoUri, function (err, database) {
        if (err) {
            console.error(err);
            process.exit(1);
        } else {
            console.log('Database connection ready');
        }
    })

    //app.get('/countries', function(req, res) {
    //  getData(database.collection('countries'), req, res);
    //});

}


module.exports = { getData, connectDB }