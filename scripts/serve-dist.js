// Minimal stand-in for Vercel's static serving, for local Lighthouse runs:
// brotli/gzip compression, dir/ -> dir/index.html, missing paths -> /404.html with status 404,
// long cache headers on /wp-content/ (as static/vercel.json sets).
// Usage: node scripts/serve-dist.js [root=dist] [port=8099]
const http = require('http'), fs = require('fs'), path = require('path'), zlib = require('zlib');
const root = path.resolve(process.argv[2] || 'dist'), port = Number(process.argv[3] || 8099);
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json',
  '.xml': 'application/xml', '.xsl': 'text/xsl', '.txt': 'text/plain', '.svg': 'image/svg+xml', '.webp': 'image/webp',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.woff2': 'font/woff2', '.ico': 'image/x-icon', '.pdf': 'application/pdf' };
const compressible = /^(text\/|application\/(json|xml)|image\/svg)/;

http.createServer((req, res) => {
  let rel = decodeURIComponent(req.url.split('?')[0]);
  let file = path.join(root, rel);
  if (!file.startsWith(root)) { res.writeHead(403); return res.end(); }
  if (rel.endsWith('/')) file = path.join(file, 'index.html');
  let status = 200;
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) { file = path.join(root, '404.html'); status = 404; }
  const type = types[path.extname(file)] || 'application/octet-stream';
  const headers = { 'Content-Type': type };
  if (rel.startsWith('/wp-content/')) headers['Cache-Control'] = 'public, max-age=604800';
  let body = fs.readFileSync(file);
  const accept = req.headers['accept-encoding'] || '';
  if (compressible.test(type)) {
    if (accept.includes('br')) { body = zlib.brotliCompressSync(body); headers['Content-Encoding'] = 'br'; }
    else if (accept.includes('gzip')) { body = zlib.gzipSync(body); headers['Content-Encoding'] = 'gzip'; }
  }
  headers['Content-Length'] = body.length;
  res.writeHead(status, headers);
  res.end(body);
}).listen(port, '127.0.0.1', () => console.log(`serving ${root} on http://127.0.0.1:${port}`));
