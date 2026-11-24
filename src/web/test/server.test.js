const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('http');
const { createServer } = require('../server');

test('GET /health returns 200 and active APP_VERSION', async () => {
  process.env.APP_VERSION = 'v0.2.0-test';
  const server = createServer();
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();

  const res = await new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}/health`, (r) => {
      let data = '';
      r.on('data', (c) => { data += c; });
      r.on('end', () => resolve({ status: r.statusCode, headers: r.headers, body: JSON.parse(data) }));
    }).on('error', reject);
  });

  server.close();
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'healthy');
  assert.equal(res.body.version, 'v0.2.0-test');
  assert.equal(res.headers['x-app-version'], 'v0.2.0-test');
});

test('GET / renders Ridgeline Outfitters storefront HTML with version tag', async () => {
  process.env.APP_VERSION = 'v0.2.0-test';
  const server = createServer();
  await new Promise((resolve) => server.listen(0, resolve));
  const { port } = server.address();

  const html = await new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}/`, (r) => {
      let data = '';
      r.on('data', (c) => { data += c; });
      r.on('end', () => resolve(data));
    }).on('error', reject);
  });

  server.close();
  assert.match(html, /Ridgeline Outfitters/);
  assert.match(html, /v0\.2\.0-test/);
});
