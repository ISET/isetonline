const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const app = express()
const apiPort = 3001
const { spawn, spawnSync } = require('child_process');

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
    console.log('Finished Compute Request\n');

    res.send('Found:' + ls);

})

app.listen(apiPort, () => console.log(`Server running on port ${apiPort}`))