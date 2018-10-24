// PM2 index
(function () {
    'use strict';
    var id = 0
    var http = require('http')

    const sleepServer = http.createServer(function (request, response) {
        response.writeHead(200, {
            'Content-type': 'text/plain'
        });
        id++
        require('./sleep.js')
        response.end('Hello World!' + id);
        console.log('Served a hello!' + id);
    });
    sleepServer.listen(process.env.PORT)
})()

