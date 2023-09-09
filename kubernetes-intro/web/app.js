const http = require('http');
const mime = require('mime');
const path = require('path');
const fs = require('fs');

const htdocs = '/app';

console.log("File server starting...");

var handler = function(request, response) {
  const filepath = path.join(path.sep, htdocs, path.normalize(request.url));
  console.log("Received request " + filepath + " from " + request.connection.remoteAddress);
  fs.readFile(filepath, (err, data) => {
    if (err) {
      response.writeHead(404);
      response.end("No such file or no access\n");
    } else {
      response.setHeader('Content-Type', mime.getType(filepath));
      response.writeHead(200);
      response.end(data);
    }
  });
};

var www = http.createServer(handler);
www.listen(8000);
