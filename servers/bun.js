// Bun: Bun.serve, no framework, fixed body.
Bun.serve({ port: 3012, hostname: '127.0.0.1', fetch() { return new Response('hello'); } });
