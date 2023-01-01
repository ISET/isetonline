// Starting to assemble test/sample code here
//
// David Cardinal, Stanford University, 2023
// 

const MongoClient = require("mongodb").MongoClient;
const mongodb = require('mongodb')

// Currently not using devExtreme
// const query = require("devextreme-query-mongodb");
// const getOptions = require('devextreme-query-mongodb/options').getOptions;

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
    // await listCollection('lens');

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

var itemList = [];
async function listCollection(collectionName){
    ourDB = await client.db('iset');
    await ourDB.collection(collectionName).find({}).toArray(function(err, result) {
        if (err) throw err;

        console.log(result);

        // try to create item list
        for (let ii = 0;  ii < result.length; ii++){
            itemList[ii] = result[ii];
        }
        client.close();
        return result;
        
    });

}

// itemList shouldn't need to be here once we figure out promises
module.exports = { getData, connectDB, listCollection, itemList }