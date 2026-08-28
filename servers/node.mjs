// Node: plain http, no framework, fixed body.
import { createServer } from 'node:http';
const BODY = 'hello';
createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'text/plain', 'content-length': BODY.length });
  res.end(BODY);
}).listen(3011, '127.0.0.1');
