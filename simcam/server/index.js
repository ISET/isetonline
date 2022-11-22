// Connect ISETonline client to oi2sensor server code
// D. Cardinal, Stanford University, 2022
// Part of the Wandell / Vistalab project to make the world a better place

const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const app = express()
const fs = require('fs')
const { spawn, spawnSync } = require('child_process');

// pick an un-used port for now
// should probably integrate with our client code on single port
const apiPort = 3001

// Command we want to run as a baseline
// Matlab wizard is pretty limited in file paths
// but if needed I'm sure we can dig into parameters to change
const oiCommand = '/usr/oi2sensor/application/run_oi2sensor.sh';
const mcrRuntime = '/usr/local/MATLAB/MATLAB_Runtime/v911/';

// Directory where we'll put our generated sensor image
var outputFolder = '../local/';
var customFolder = '/custom/'; // for uploaded objects

app.use(bodyParser.urlencoded({ extended: true }))
app.use(cors())
app.use(bodyParser.json())

// Trivial test to see if we are running
app.get('/', (req, res) => {
    res.send('Hello World!')
})
app.get('/compute', (req, res) => {
    res.send('COMPUTE Hello World!')
})

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
    outputFile = ''; // Need to set

    // Not sure what our params need to look like to work on command line
    var userOptions = [mcrRuntime, oiFile, sPath, outputFile];
    console.log('User Options: ' + userOptions);
    const oi = spawnSync('sh', [oiCommand, userOptions]);
    console.log('Finished Compute Request\n');

    // For GET? res.send('Found:' + ls.stdout + ' and ' + oi.stdout);
    res.send("yes");

})

app.listen(apiPort, () => console.log(`ISET Server running on port ${apiPort}`))