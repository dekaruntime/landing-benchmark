// Node with cluster: N workers, the usual way to use all cores.
import cluster from 'node:cluster';
import { createServer } from 'node:http';
import { availableParallelism } from 'node:os';
const BODY = 'hello';
if (cluster.isPrimary) {
  const n = Number(process.env.WORKERS || availableParallelism());
  for (let i = 0; i < n; i++) cluster.fork();
} else {
  createServer((req, res) => {
    res.writeHead(200, { 'content-type': 'text/plain', 'content-length': BODY.length });
    res.end(BODY);
  }).listen(3013, '127.0.0.1');
}
