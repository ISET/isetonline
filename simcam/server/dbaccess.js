// Don't know how this works, so starting to assemble
// sample code here

const MongoClient = require("mongodb").MongoClient;
const query = require("devextreme-query-mongodb");

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