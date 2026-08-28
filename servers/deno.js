// Deno: Deno.serve, no framework, fixed body. Single event loop by default,
// same as Node and Bun.
Deno.serve({ port: 3015, hostname: '127.0.0.1' }, () => new Response('hello'));
