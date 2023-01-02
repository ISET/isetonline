// Starting to assemble test/sample code here
//
// David Cardinal, Stanford University, 2023
// 

const MongoClient = require("mongodb").MongoClient;
const { resolve } = require("core-js/fn/promise");
const mongodb = require('mongodb');

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
var ourDB;

// make sync, as we can't do much until open!
function connectDB() {
    client = new MongoClient(mongoUri)

try {
    client.connect();
    ourDB = client.db('iset');
    listDatabases(client);
    listCollections(ourDB);

} catch (e) {
    console.error(e);
}
    //app.get('/countries', function(req, res) {
    //  getData(database.collection('countries'), req, res);
    //});

}

async function listDatabases(client){
    var databasesList = await client.db().admin().listDatabases();
 
    console.log("Databases:");
    databasesList.databases.forEach(db => console.log(` - ${db.name}`));
};

async function listCollections(aDB){
    var collectionList = await aDB.listCollections();
 
    console.log("Collections:");
    collectionList.forEach(coll => console.log(` - ${coll.name}`));
};

// try making this non-async so we can do a regular return
// Can be async again if we start to worry about multi-user & GUI perf
var itemList = [];
async function listCollection(collectionName){
    await ourDB.collection(collectionName).find({}).toArray(function(err, result) {
        if (err) throw err;

        console.log(result);
        
        // try to create item list
        // for (let ii = 0;  ii < result.length; ii++){
        //    itemList[ii] = result[ii];
        // }
        // client.close();
        return result;
        
    });

}

function getCollection(collectionName) {
    return listCollection(collectionName).then(result => console.log(result)).catch(err => console.log(err));
}

// itemList shouldn't need to be here once we figure out promises
module.exports = { getData, connectDB, listCollection, itemList }