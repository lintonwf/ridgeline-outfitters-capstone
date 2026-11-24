const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createApiServer } = require('../server');

test('GET /products returns catalog and version metadata', async () => {
  process.env.APP_VERSION = 'v0.2.0-test';
  const server = createApiServer();
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();

  const res = await new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}/products`, (r) => {
      let data = '';
      r.on('data', (c) => { data += c; });
      r.on('end', () => resolve({ status: r.statusCode, body: JSON.parse(data) }));
    }).on('error', reject);
  });

  server.close();
  assert.equal(res.status, 200);
  assert.equal(res.body.version, 'v0.2.0-test');
  assert.ok(Array.isArray(res.body.products) && res.body.products.length >= 4);
});
