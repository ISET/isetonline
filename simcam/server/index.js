const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const app = express()
const apiPort = 3001

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
    res.send('Hello World!')
})

app.listen(apiPort, () => console.log(`Server running on port ${apiPort}`))