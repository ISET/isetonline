// Connect ISETonline client to oi2sensor server code
// D. Cardinal, Stanford University, 2022
// Part of the Wandell / Vistalab project to make the world a better place

const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const app = express()
const apiPort = 3001
const { spawn, spawnSync } = require('child_process');

// Command we want to run as a baseline
// Except our dev server is Windows & Deploy is Linux:(
const oiCommand = '/usr/oi2sensor/application/run_oi2sensor.sh';
const mcrRuntime = '/usr/local/MATLAB/MATLAB_Runtime/v911/';

// Directory where we'll put our generated sensor image
const outputFolder = '../local/';

app.use(bodyParser.urlencoded({ extended: true }))
app.use(cors())
app.use(bodyParser.json())

// Trivial test to see if we are running
app.get('/', (req, res) => {
    res.send('Hello World!')
})

// Here is where we want to try to do something!
app.post('/compute', (req, res) => {

    // set the parameters for oi2sensor
    var oiFile = req.body.oiFile;
    var sensorFile = req.body.sensorFile;
    var exposureTime = req.body.exposureTime;

    // code here if needed to map filename params to locations
    // unless we always send full URLs

    console.log('Got Compute Request\n');
    const ls = spawnSync('ls', ['-lh', '.']);
    const oi = spawnSync('sh', [oiCommand, mcrRuntime]);
    console.log('Finished Compute Request\n');

    // For GET? res.send('Found:' + ls.stdout + ' and ' + oi.stdout);
    res.send("yes");

})

app.listen(apiPort, () => console.log(`Server running on port ${apiPort}`))