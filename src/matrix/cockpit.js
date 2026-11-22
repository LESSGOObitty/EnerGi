const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const http = require('http');

const LEDGER_DIR = process.platform === 'win32' ? 'C:\\Matrix-Ledger' : '/opt/Matrix-Ledger';
if (!fs.existsSync(LEDGER_DIR)) fs.mkdirSync(LEDGER_DIR, { recursive: true });
const JURY_LOG = path.join(LEDGER_DIR, 'MATRIX_JURY_LOGS.jsonl');

const RPC_URL   = process.env.ANVIL_RPC || 'http://127.0.0.1:8545';
const OWNER_PAD = '000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266';
const C20       = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e';
const C721      = '0x0165878A594ca255338adfa4d48449f69242Eb8F';
const CRDN      = '0xdbC43Ba45381e02825b14322cDdd15eC4B3164E6';
const C1155     = '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0';
const CARC      = '0xCD8a1C3ba11CF5ECfa6267617243239504a98d90';
const CEQ       = '0x172076E0166D1F9Cc711C77Adf8488051744980C';

function rpcCall(method, params) {
  return new Promise((resolve, reject) => {
    const u = new URL(RPC_URL);
    const payload = JSON.stringify({ jsonrpc: '2.0', method, params, id: 1 });
    const req = http.request({
      hostname: u.hostname, port: u.port || 80, path: u.pathname, method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) },
      timeout: 1500
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try {
          const p = JSON.parse(data);
          p.error ? reject(new Error(p.error.message)) : resolve(p.result);
        } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
    req.write(payload);
    req.end();
  });
}

(async () => {
  const ts = new Date().toISOString();
  let blk = 'OFFLINE', root = '0x0', eqSeal = '0x0', sov = '0', nfts = '0', rdn = '0', u108 = '0', arcs = '0', pulses = '0';
  try {
    const [blkHex, rootHex, eqHex, r20, r721, rRdn, r1155, rArc, rPulse] = await Promise.all([
      rpcCall('eth_blockNumber', []),
      rpcCall('eth_call', [{ to: C721, data: '0x49590657' }, 'latest']),
      rpcCall('eth_call', [{ to: CEQ,  data: '0x2b29c264' }, 'latest']),
      rpcCall('eth_call', [{ to: C20,  data: '0x70a08231' + OWNER_PAD }, 'latest']),
      rpcCall('eth_call', [{ to: C721, data: '0x70a08231' + OWNER_PAD }, 'latest']),
      rpcCall('eth_call', [{ to: CRDN, data: '0x18160ddd' }, 'latest']),
      rpcCall('eth_call', [{ to: C1155, data: '0x00fdd58e' + OWNER_PAD + '000000000000000000000000000000000000000000000000000000000000006c' }, 'latest']),
      rpcCall('eth_call', [{ to: CARC, data: '0x883b8c9d' }, 'latest']),
      rpcCall('eth_call', [{ to: CEQ,  data: '0x597e1fb5' }, 'latest'])
    ]);
    blk    = `#${parseInt(blkHex, 16)}`;
    root   = rootHex;
    eqSeal = eqHex;
    sov    = (BigInt(r20) / 10n ** 18n).toLocaleString();
    nfts   = String(parseInt(r721, 16));
    rdn    = String(parseInt(rRdn, 16));
    u108   = String(parseInt(r1155, 16));
    arcs   = String(parseInt(rArc, 16));
    pulses = String(parseInt(rPulse, 16));
  } catch (_) {}

  const seal = crypto.createHash('sha256').update(`${ts}|${blk}|${eqSeal}`).digest('hex');
  fs.appendFileSync(JURY_LOG, JSON.stringify({ ts, blk, root, eqSeal, seal }) + '\n');

  console.log('\x1b[38;5;196m%s\x1b[0m', '==========================================================================');
  console.log('\x1b[38;5;82m%s\x1b[0m',  '   ROBDOE SOVEREIGN ECOSYSTEM COCKPIT  |  z = z^2 + c  |  WUSHU & TAI CHI  ');
  console.log('\x1b[38;5;196m%s\x1b[0m', '==========================================================================');
  console.log(` [EVM_BLOCK]   : ${blk} | [ARCHIVES] : ${arcs} Sealed | [HARMONIC_PULSES] : ${pulses}`);
  console.log(` [ACTIVE_ROOT] : ${root}`);
  console.log(` [Z2+C_SEAL]   : ${eqSeal}`);
  console.log(` [TOKENS]      : ${sov} SOV | ${nfts} Domain NFTs | ${rdn} RDN | ${u108} ATL-1155`);
  console.log('\x1b[38;5;196m%s\x1b[0m', '==========================================================================');
})();