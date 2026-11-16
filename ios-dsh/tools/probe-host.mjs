// Checks whether a DSH host will accept this phone's connection, before you
// fight the app: prints the HTTP status of `/?token=…`, the redirect the
// server answers with (if any), and whether it set a session cookie.
//
//   node tools/probe-host.mjs http://192.168.1.8:3080 --token <token>
//
// Exit code 0 when the host answers with a cookie or a 2xx/3xx page.
import process from 'node:process';

const args = process.argv.slice(2);
const address = args.find((a) => !a.startsWith('--'));
const tokenIndex = args.indexOf('--token');
const token = tokenIndex >= 0 ? args[tokenIndex + 1] : '';

if (!address) {
  console.error('usage: node tools/probe-host.mjs http://HOST:PORT --token TOKEN');
  process.exit(2);
}

let base;
try {
  base = new URL(address.includes('://') ? address : `http://${address}`);
} catch {
  console.error(`not a URL: ${address}`);
  process.exit(2);
}

const url = new URL(base);
if (token) url.searchParams.set('token', token);

console.log(`GET ${url.origin}${url.pathname}${url.search ? '?token=…' : ''}`);

let response;
try {
  response = await fetch(url, { redirect: 'manual', headers: { 'user-agent': 'dsh-probe/1.0' } });
} catch (error) {
  console.error(`✗ 连不上：${error.message}`);
  console.error('  宿主在跑吗？手机和电脑同一个网络吗？防火墙放行端口了吗？');
  process.exit(1);
}

console.log(`  status  ${response.status} ${response.statusText}`);
const location = response.headers.get('location');
if (location) console.log(`  location ${location}`);
const cookies = response.headers.getSetCookie?.() ?? [];
for (const cookie of cookies) {
  const name = cookie.split('=')[0];
  console.log(`  cookie  ${name}=… (${cookie.includes('HttpOnly') ? 'HttpOnly ' : ''}${cookie.includes('Secure') ? 'Secure' : 'not Secure'})`);
}

if (response.status === 401) {
  console.error('✗ 401：token 不对或已经过期。用 `dsh web` 重新打印出来的那个地址。');
  process.exit(1);
}
if (response.status === 403) {
  console.error('✗ 403：Host 不在信任列表里。--host 要用电脑自己的局域网地址，或加 --trusted-host。');
  process.exit(1);
}
if (!response.ok && response.status !== 303 && response.status !== 302) {
  console.error(`✗ ${response.status}：宿主回答了，但不是预期的入口页。`);
  process.exit(1);
}

console.log('✓ 宿主的入口页有响应；带 cookie 的话，App 里应该能直接进。');
