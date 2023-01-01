// Connect ISETonline client to oi2sensor server code
// D. Cardinal, Stanford University, 2022
// Part of the Wandell / Vistalab project to make the world a better place


const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const app = express()
const fs = require('fs')
const { spawn, spawnSync, execSync } = require('child_process');
require("regenerator-runtime/runtime");

// Import mongodb connection code
const { getData, connectDB, getCollection, itemList } = require('./dbaccess.js')

// As a reference this works from the command line:
//  sh /usr/Stanford_University/oi2sensor/application/run_oi2sensor.sh 
//  /usr/local/MATLAB/MATLAB_Runtime/v911/ 'oiFile' /volume1/web/oi/oi_001.mat 
// 'sensorFile' /usr/Stanford_University/oi2sensor/application/AR0132AT-RGB_test.json  
// 'outputFile' /volume1/web/isetonline/simcam/public/images/sensorImage.png

// pick an un-used port for now
// should probably integrate with our client code on single port
const apiPort = 3001

// Command we want to run as a baseline
// Matlab wizard is pretty limited in file paths
// but if needed I'm sure we can dig into parameters to change
const oiCommand = '/usr/Stanford_University/oi2sensor/application/run_oi2sensor.sh';
const mcrRuntime = '/usr/local/MATLAB/MATLAB_Runtime/v911/';
// Directories where we'll put our generated sensor image
const outputFolder = '/volume1/web/isetonline/simcam/server/public/images/'; // need a place client can reach
var customFolder = './custom/'; // for uploaded objects
const oiFolder = "/volume1/web/oi/";

app.use(bodyParser.urlencoded({ extended: true }))
app.use(cors())
app.use(bodyParser.json())

// Trivial test to see if we are running
const testCollection = "lens";
app.get('/', (req, res) => {
    connectDB();
    // Not Async anymore
    console.log("NEW LISTING HERE!");
    items = getItems('lens');
    console.log(items.json); // Only if async: .then(console.log);
    //res.send("Hello, world  <br>" + itemList);
})

async function getItems(collection) {
    ourItemPromise = await getCollection(collection);
    console.log(ourItemPromise); //return ourItemPromise.then(console.log);
}

app.get('/compute', (req, res) => {
    res.send('COMPUTE Hello World!')
})

// Serve resulting images
app.use(express.static('public'))
app.use(express.static('public/images'))
app.use(express.static('images'))

// Here is where we want to try to do something!
app.post('/compute', (req, res) => {

    console.log('Compute with custom foler\n' + customFolder);

    // set the parameters for oi2sensor
    var oiFile = req.body.oiFile;
    // try to pass in entire sensor object for maximum
    // flexibility, (or sensor file name?)
    var sensor = req.body.sensor;

    // We need to write the sensor object
    // into a file for passing as a param to oi2sensor.
    sPath = customFolder + sensor.name + '.json';
    console.log('Path is: ' + sPath)
    fs.writeFileSync(sPath, JSON.stringify(sensor));

    // having trouble finding the custom folder in Matlab?
    altSPath = "/usr/Stanford_University/oi2sensor/application/" + sensor.name + '.json';
    console.log('Alt Path is: ' + altSPath)
    fs.writeFileSync(altSPath, JSON.stringify(sensor));

    // code here if needed to map filename params to locations
    // unless we always send full URLs

    console.log('oiFile ' + oiFile);
    console.log('sensor ' + sensor);

    // just for testing
    // const ls = spawnSync('ls', ['-lh', '.']);

    // experiment with options
    // we probably need to pass in the output file name
    // so that we know where it is later
    // or have a way to predict what it will be

    // Simplest case would be oiFile, sensorFile, outputFile
    outputFile = outputFolder + 'sensorImage.png'; // Need to set
    yoloFile = outputFolder + 'yoloImage.png'; // Need to set

    // Not sure what our params need to look like to work on command line
    var userOptions = [' ' + mcrRuntime +  ' '
     + '\'oiFile\'' + ' ' +  oiFolder + oiFile + ' '
     + '\'sensorFile\'' + ' ' + altSPath
     + ' ' +  '\'outputFile\'' + ' ' + outputFile +
     + ' ' +  '\'yoloFile\'' + ' ' + yoloFile];
    console.log('User Command: ' + oiCommand);
    console.log('User Options: ' + userOptions);

    launchCmd = oiCommand + ' ' + userOptions;
    console.log('Launch command: ' + launchCmd)
    execSync(launchCmd);
    // const oi = spawnSync(oiCommand, userOptions);

    console.log('Finished Compute Request\n');
    // console.log('With oi: ' + oi);

    // For GET? res.send('Found:' + ls.stdout + ' and ' + oi.stdout);
    res.send("yes");

})


app.listen(apiPort, () => console.log(`ISET Server running on port ${apiPort}`))