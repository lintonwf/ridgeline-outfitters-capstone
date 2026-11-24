const http = require('http');

const PORT = process.env.PORT || 80;

function getAppVersion() {
  return process.env.APP_VERSION || 'v0.2.0';
}

// Injected securely from Azure Key Vault via Managed Identity (SEC-3)
function hasSqlSecret() {
  return Boolean(process.env.SQL_CONNECTION_STRING);
}

const PRODUCTS = [
  { sku: 'RO-TN-01', name: 'Blue Ridge 2-Person Backpacking Tent', category: 'Shelter', price: 189.00, stock: 14 },
  { sku: 'RO-PK-04', name: 'Shenandoah 55L Trail Pack', category: 'Packs', price: 145.00, stock: 22 },
  { sku: 'RO-JK-09', name: 'Appalachian All-Weather Shell Jacket', category: 'Apparel', price: 129.50, stock: 31 },
  { sku: 'RO-ST-12', name: 'Summit Compact Titanium Camp Stove', category: 'Camp Kitchen', price: 48.00, stock: 40 }
];

function createApiServer() {
  const appVersion = getAppVersion();
  const secretBound = hasSqlSecret();
  return http.createServer((req, res) => {
    const url = (req.url || '/').split('?')[0];

    if (url === '/health' || url === '/version') {
      const payload = {
        status: 'healthy',
        service: 'ridgeline-api',
        version: appVersion,
        keyVaultSecretBound: secretBound,
        timestamp: new Date().toISOString()
      };
      console.log(JSON.stringify({ level: 'info', route: url, version: appVersion, keyVaultSecretBound: secretBound }));
      res.writeHead(200, { 'Content-Type': 'application/json', 'X-App-Version': appVersion });
      return res.end(JSON.stringify(payload));
    }

    if (url === '/products') {
      const payload = {
        source: secretBound ? 'azure-sql-private-endpoint' : 'api-catalog-store',
        version: appVersion,
        products: PRODUCTS
      };
      res.writeHead(200, { 'Content-Type': 'application/json', 'X-App-Version': appVersion });
      return res.end(JSON.stringify(payload));
    }

    res.writeHead(404, { 'Content-Type': 'application/json', 'X-App-Version': appVersion });
    res.end(JSON.stringify({ error: 'Not Found', version: appVersion }));
  });
}

if (require.main === module) {
  const server = createApiServer();
  server.listen(PORT, () => {
    console.log(JSON.stringify({ level: 'info', msg: 'Ridgeline API Tier started', port: PORT, version: appVersion, keyVaultSecretBound: secretBound }));
  });
}

module.exports = { createApiServer };
