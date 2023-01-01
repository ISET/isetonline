// Starting to assemble test/sample code here

const mongodb = require('mongodb');
const query = require('devextreme-query-mongodb');
const getOptions = require('devextreme-query-mongodb/options').getOptions;

// test db
const mongoUri = "mongodb://seedling:49153/iset";
const testCollection = "lens";

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

async function getData(coll, req, res) {
    try {
        const options = getQueryOptions(req);
        if (options.errors.length > 0)
            console.error('Errors in query string: ', JSON.stringify(options.errors));

        const results = await query(
            coll,
            options.loadOptions,
            options.processingOptions
        );
        res.status(200).jsonp(results);
    } catch (err) {
        handleError(res, err, 'Failed to retrieve data');
    }
}

function connectDB(){
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


module.exports = {getData, connectDB}