import test from 'node:test';
import assert from 'node:assert/strict';
import { makeServer } from './server.mjs';

const token = 'lingora-test-token-123456789';
const request = {
  scenario: 'Introductions', level: 'Complete beginner', completed: 1, explanation: 'ur',
  messages: [{ role: 'user', content: 'I name is Sara' }],
};
async function withServer(check, options = {}) {
  const server = makeServer({
    env: { ACCESS_TOKENS: token, AI_MODEL: 'test-model', AI_API_KEY: 'test-provider-key', ...options.env },
    logger: { info() {} },
    fetcher: options.fetcher ?? (async () => Response.json({ choices: [{ message: { content: 'Try: My name is Sara.' } }] })),
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    await check((data = request, access = token, path = '/v1/tutor') =>
      fetch(`http://127.0.0.1:${server.address().port}${path}`, {
        method: 'POST', headers: { Authorization: `Bearer ${access}` }, body: JSON.stringify(data),
      }));
  } finally { await new Promise(resolve => server.close(resolve)); }
}

test('authenticated requests forward bilingual education context to provider', async () => {
  await withServer(async send => {
    const response = await send();
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { content: 'Try: My name is Sara.', generated: true });
    assert.equal(response.headers.get('cache-control'), 'no-store');
  }, { fetcher: async (url, init) => {
    assert.match(url, /chat\/completions$/);
    assert.equal(init.headers.Authorization, 'Bearer test-provider-key');
    const payload = JSON.parse(init.body);
    assert.match(payload.messages[0].content, /Explanation language: Urdu/);
    assert.deepEqual(payload.messages[1], request.messages[0]);
    return Response.json({ choices: [{ message: { content: 'Try: My name is Sara.' } }] });
  } });
});

test('requires a valid student token', async () => {
  await withServer(async send => assert.equal((await send(request, 'wrong')).status, 401));
});

test('rejects invalid lesson context and oversized body', async () => {
  await withServer(async send => {
    assert.equal((await send({ ...request, explanation: 'other' })).status, 400);
    assert.equal((await send({ ...request, body: 'a'.repeat(17000) })).status, 413);
  });
});

test('limits requests and returns a retry interval', async () => {
  await withServer(async send => {
    assert.equal((await send()).status, 200);
    const limited = await send();
    assert.equal(limited.status, 429);
    assert.ok(Number(limited.headers.get('retry-after')) > 0);
  }, { env: { MINUTE_LIMIT: '1' } });
});

test('returns a service error when the provider is unconfigured', async () => {
  await withServer(async send => assert.equal((await send()).status, 503), { env: { AI_API_KEY: '' } });
});

test('handles provider network failures and malformed replies', async () => {
  await withServer(async send => assert.equal((await send()).status, 503),
    { fetcher: async () => { throw new Error('network'); } });
  await withServer(async send => assert.equal((await send()).status, 502),
    { fetcher: async () => new Response('invalid reply') });
});

test('filters email addresses in student input and provider output', async () => {
  await withServer(async send => {
    assert.equal((await send({ ...request, messages: [{ role: 'user', content: 'email@example.com' }] })).status, 422);
    assert.equal((await send()).status, 422);
  }, { fetcher: async () => Response.json({ choices: [{ message: { content: 'email@example.com' } }] }) });
});
