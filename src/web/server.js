const http = require('http');
const https = require('https');

const PORT = process.env.PORT || 8080;
const API_HOST = process.env.API_INTERNAL_HOST || '';
const STORAGE_ACCOUNT = process.env.STORAGE_ACCOUNT_NAME || 'stridgelineprod64hvdp';

function getAppVersion() {
  return process.env.APP_VERSION || 'v0.2.0';
}

function getEnvironment() {
  return process.env.ENVIRONMENT_NAME || 'Production';
}

const FALLBACK_CATALOG = [
  { sku: 'RO-TN-01', name: 'Blue Ridge 2-Person Backpacking Tent', category: 'Shelter', price: 189.00, stock: 14 },
  { sku: 'RO-PK-04', name: 'Shenandoah 55L Trail Pack', category: 'Packs', price: 145.00, stock: 22 },
  { sku: 'RO-JK-09', name: 'Appalachian All-Weather Shell Jacket', category: 'Apparel', price: 129.50, stock: 31 },
  { sku: 'RO-ST-12', name: 'Summit Compact Titanium Camp Stove', category: 'Camp Kitchen', price: 48.00, stock: 40 }
];

function fetchApiCatalog() {
  return new Promise((resolve) => {
    if (!API_HOST) {
      return resolve({ source: 'local-cache', items: FALLBACK_CATALOG, apiVersion: 'standby' });
    }
    const req = https.get(
      {
        hostname: API_HOST,
        path: '/products',
        timeout: 2500,
        headers: { 'X-Client-Tier': 'web-frontend' }
      },
      (res) => {
        let body = '';
        res.on('data', (chunk) => { body += chunk; });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(body);
            resolve({
              source: parsed.source || 'api-tier',
              items: Array.isArray(parsed.products) ? parsed.products : FALLBACK_CATALOG,
              apiVersion: parsed.version || 'unknown'
            });
          } catch {
            resolve({ source: 'local-cache', items: FALLBACK_CATALOG, apiVersion: 'fallback' });
          }
        });
      }
    );
    req.on('error', () => resolve({ source: 'local-cache', items: FALLBACK_CATALOG, apiVersion: 'unreachable' }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ source: 'local-cache', items: FALLBACK_CATALOG, apiVersion: 'timeout' });
    });
  });
}

function renderHtml(catalogData) {
  const appVersion = getAppVersion();
  const environment = getEnvironment();
  const rows = catalogData.items.map((item) => `
    <tr>
      <td><code>${item.sku}</code></td>
      <td>${item.name}</td>
      <td>${item.category}</td>
      <td>$${Number(item.price).toFixed(2)}</td>
      <td>${item.stock} in stock</td>
    </tr>
  `).join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Ridgeline Outfitters | Outdoor Gear Storefront</title>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; margin: 0; background: #f4f6f4; color: #1f2923; }
    header { background: #1e3f2b; color: #ffffff; padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center; }
    .badge { background: #3b6e4c; padding: 0.3rem 0.7rem; border-radius: 999px; font-size: 0.85rem; font-weight: 600; }
    main { max-width: 920px; margin: 2rem auto; background: #ffffff; padding: 1.75rem; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,0.08); }
    table { width: 100%; border-collapse: collapse; margin-top: 1rem; }
    th, td { text-align: left; padding: 0.75rem; border-bottom: 1px solid #e2e8e4; }
    th { background: #eef3ef; }
    footer { max-width: 920px; margin: 1rem auto 2rem; font-size: 0.85rem; color: #4b5c51; display: flex; justify-content: space-between; }
  </style>
</head>
<body>
  <header>
    <div>
      <h1 style="margin:0;font-size:1.5rem;">Ridgeline Outfitters</h1>
      <p style="margin:0.25rem 0 0;opacity:0.9;">Trail-Tested Gear &amp; Backcountry Equipment</p>
    </div>
    <span class="badge">Release ${appVersion} &middot; ${environment}</span>
  </header>
  <main>
    <h2 style="margin-top:0;">Featured Trail Catalog</h2>
    <p>Data Source: <strong>${catalogData.source}</strong> | API Tier Version: <strong>${catalogData.apiVersion}</strong> | Static Assets: <code>${STORAGE_ACCOUNT}.blob.core.windows.net</code></p>
    <table>
      <thead>
        <tr>
          <th>SKU</th>
          <th>Product</th>
          <th>Category</th>
          <th>Price</th>
          <th>Availability</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  </main>
  <footer>
    <span>Ridgeline Outfitters Cloud Storefront (CPTR 445)</span>
    <span>Deployed Version: <strong>${appVersion}</strong></span>
  </footer>
</body>
</html>`;
}

function createServer() {
  const appVersion = getAppVersion();
  const environment = getEnvironment();
  return http.createServer(async (req, res) => {
    const url = (req.url || '/').split('?')[0];

    if (url === '/health') {
      const payload = JSON.stringify({
        status: 'healthy',
        service: 'ridgeline-web',
        version: appVersion,
        environment: environment,
        timestamp: new Date().toISOString()
      });
      console.log(JSON.stringify({ level: 'info', event: 'health_check', version: appVersion }));
      res.writeHead(200, { 'Content-Type': 'application/json', 'X-App-Version': appVersion });
      return res.end(payload);
    }

    if (url === '/version') {
      res.writeHead(200, { 'Content-Type': 'application/json', 'X-App-Version': appVersion });
      return res.end(JSON.stringify({ service: 'ridgeline-web', version: appVersion, environment: environment }));
    }

    const catalogData = await fetchApiCatalog();
    const html = renderHtml(catalogData);
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8', 'X-App-Version': appVersion });
    res.end(html);
  });
}

if (require.main === module) {
  const server = createServer();
  server.listen(PORT, () => {
    console.log(JSON.stringify({
      level: 'info',
      msg: 'Ridgeline Web Tier started',
      port: PORT,
      version: getAppVersion(),
      environment: getEnvironment()
    }));
  });
}

module.exports = { createServer };
