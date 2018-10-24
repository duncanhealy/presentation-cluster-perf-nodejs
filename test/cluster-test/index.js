
(function () {
    'use strict';
    var id = 0
    var cluster = require('cluster'),
        http = require('http'),
        os = require('os'),
        
        /*
         * ClusterServer object
         * 
         * We start multi-threaded server instances by passing the server object
         * to ClusterServer.start(server, port).
         *
         * Servers are automatically started with a number of threads equivalent
         * to the number of CPUs reported by the os module.
         */
        ClusterServer = {
            name: 'ClusterServer',
            
            cpus: os.cpus().length,
            
            autoRestart: true, // Restart threads on death?
            
            start: function (server, port) {
                var me = this,
                    i;
                
                if (cluster.isMaster) { // fork worker threads
                    for (i = 0; i < me.cpus; i += 1) {
                        console.log(me.name + ': starting worker thread #' + i);
                        cluster.fork();
                    }
                    
                    cluster.on('death', function (worker) {
                        // Log deaths!
                        console.log(me.name + ': worker ' + worker.pid + ' died.');
                        // If autoRestart is true, spin up another to replace it
                        if (me.autoRestart) {
                            console.log(me.name + ': Restarting worker thread...');
                            cluster.fork();
                        }
                    });
                } else {
                    // Worker threads run the server
                    server.listen(port);
                }
            }
        },
        
        /*
         * Simple example HelloWorld HTTP server
         *
         * Repsonds to any request with a plain txt "Hello World!" message.
         *
         * You can replace this with much more complex processing, naturally.
         */
        helloWorldServer = http.createServer(function (request, response) {
            response.writeHead(200, {
                'Content-type': 'text/plain'
            });
            id++
            require('./sleep.js')
            response.end(ClusterServer.name + 'Hello World!' + id);
            console.log(ClusterServer.name + 'Served a hello!' +id);
        });
    
    ClusterServer.name = 'helloWorldServer'; // rename ClusterServer instance
    ClusterServer.start(helloWorldServer, process.env.PORT); // Start it up!
  }());