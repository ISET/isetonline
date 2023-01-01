// Starting to assemble test/sample code here
//
// David Cardinal, Stanford University, 2023
// 

// Just add '-legacy' to my mongodb import
const MongoClient = require("mongodb").MongoClient;
// const MongoClient = require("mongodb-legacy").MongoClient;
const mongodb = require('mongodb')
// const mongodb = require('mongodb-legacy')
const query = require("devextreme-query-mongodb");
// const client = new MongoClient()
// const db = client.db();
// const collection = db.collection('pets');

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

var client;

async function connectDB() {
    client = new MongoClient(mongoUri)

try {
    client.connect();
    await listDatabases(client);
} catch (e) {
    console.error(e);
}
    //app.get('/countries', function(req, res) {
    //  getData(database.collection('countries'), req, res);
    //});

}

async function listDatabases(client){
    databasesList = await client.db().admin().listDatabases();
 
    console.log("Databases:");
    databasesList.databases.forEach(db => console.log(` - ${db.name}`));
};


module.exports = { getData, connectDB }