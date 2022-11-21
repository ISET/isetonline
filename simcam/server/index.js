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

app.use(bodyParser.urlencoded({ extended: true }))
app.use(cors())
app.use(bodyParser.json())

// Trivial test to see if we are running
app.get('/', (req, res) => {
    res.send('Hello World!')
})

// Here is where we want to try to do something!
// We can start by doing a simple GET to try a spawn
app.get('/compute', (req, res) => {
    console.log('Got Compute Request\n');
    const ls = spawnSync('ls', ['-lh', '.']);
    const oi = spawnSync('sh', [oiCommand, mcrRuntime]);
    console.log('Finished Compute Request\n');

    res.send('Found:' + ls.stdout + ' and ' + oi.stdout);

})

app.listen(apiPort, () => console.log(`Server running on port ${apiPort}`))