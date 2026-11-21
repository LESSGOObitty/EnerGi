const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const http = require('http');

const IS_WIN = process.platform === 'win32';
const LEDGER_DIR = fs.existsSync('/data/data/com.termux')
  ? '/data/data/com.termux/files/home/Matrix-Ledger'
  : (IS_WIN ? 'C:\\Matrix-Ledger' : '/opt/Matrix-Ledger');

if (!fs.existsSync(LEDGER_DIR)) fs.mkdirSync(LEDGER_DIR, { recursive: true });
const JURY_LOG = path.join(LEDGER_DIR, 'MATRIX_JURY_LOGS.jsonl');

const RPC_URL   = process.env.ANVIL_RPC || 'http://127.0.0.1:8545';
const OWNER_PAD = '000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266';
const C20       = '0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e';
const C721      = '0x0165878A594ca255338adfa4d48449f69242Eb8F';
const C1155     = '0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0';

const SOLAR_DAY_SECS = 86400;
const ARC_FRACTION   = 7200;

function rpcCall(method, params) {
  return new Promise((resolve, reject) => {
    const u = new URL(RPC_URL);
    const payload = JSON.stringify({ jsonrpc: '2.0', method, params, id: 1 });
    const req = http.request({
      hostname: u.hostname,
      port: u.port || 80,
      path: u.pathname,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) },
      timeout: 1500
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (parsed.error) reject(new Error(parsed.error.message));
          else resolve(parsed.result);
        } catch (e) { reject(e); }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('RPC timeout')); });
    req.write(payload);
    req.end();
  });
}

async function tick() {
  const timestamp = new Date().toISOString();
  const elapsedCycles = (Date.now() % (SOLAR_DAY_SECS * 1000)) / 1000;
  const currentArcStep = Math.floor(elapsedCycles * (ARC_FRACTION / SOLAR_DAY_SECS)) % ARC_FRACTION;

  let blockNum = 'OFFLINE';
  let onChainRoot = '0x0';
  let sovBal = '0';
  let nftCount = '0';
  let latticeBal = '0';

  try {
    const [blkHex, rootHex, raw20, raw721, raw1155] = await Promise.all([
      rpcCall('eth_blockNumber', []),
      rpcCall('eth_call', [{ to: C721, data: '0x49590657' }, 'latest']),
      rpcCall('eth_call', [{ to: C20, data: '0x70a08231' + OWNER_PAD }, 'latest']),
      rpcCall('eth_call', [{ to: C721, data: '0x70a08231' + OWNER_PAD }, 'latest']),
      rpcCall('eth_call', [{ to: C1155, data: '0x00fdd58e' + OWNER_PAD + '0000000000000000000000000000000000000000000000000000000000000001' }, 'latest'])
    ]);
    blockNum = `#${parseInt(blkHex, 16)}`;
    onChainRoot = rootHex;
    sovBal = (BigInt(raw20) / 10n ** 18n).toLocaleString();
    nftCount = String(parseInt(raw721, 16));
    latticeBal = String(parseInt(raw1155, 16));
  } catch (_) {}

  const seal = crypto.createHash('sha256').update(`${timestamp}|${blockNum}|${onChainRoot}`).digest('hex');
  fs.appendFileSync(JURY_LOG, JSON.stringify({ ts: timestamp, arc: currentArcStep, block: blockNum, root: onChainRoot, seal }) + '\n');

  console.clear();
  console.log('\x1b[38;5;196m%s\x1b[0m', '=====================================================================');
  console.log('\x1b[38;5;82m%s\x1b[0m',  '     ROBDOE SOVEREIGN MATRIX COCKPIT  |  LIVE ANVIL TRI-TOKEN SYNC    ');
  console.log('\x1b[38;5;196m%s\x1b[0m', '=====================================================================');
  console.log(` \x1b[33m[PLATFORM]\x1b[0m       : ${process.platform} (${process.arch}) | \x1b[33m[EVM_BLOCK]\x1b[0m : ${blockNum}`);
  console.log(` \x1b[33m[ARC_HARMONIC]\x1b[0m   : ${currentArcStep}/${ARC_FRACTION} Arcs     | \x1b[33m[SEAL]\x1b[0m      : ${seal.substring(0, 16)}...`);
  console.log(` \x1b[33m[ONCHAIN_ROOT]\x1b[0m   : ${onChainRoot}`);
  console.log(` \x1b[36m[TRI_TOKENS]\x1b[0m     : ${sovBal} SOV (ERC20) | ${nftCount} NFTs (ERC721) | ${latticeBal} Units (ERC1155)`);
  console.log('\x1b[38;5;196m%s\x1b[0m', '=====================================================================');
}

tick();
setInterval(tick, 3000);