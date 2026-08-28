// Bun spread across cores. Not the default -- you opt in with reusePort and
// run one process per core. Included so the tuned comparison is available.
Bun.serve({
  port: 3014,
  hostname: '127.0.0.1',
  reusePort: true,
  fetch() { return new Response('hello'); },
});
