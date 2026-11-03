// Contract checks for the scoped glob override used by Google's rimraf dependency.
// Only files in a newly created OS temp directory are removed.
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { createRequire } = require('node:module');
const adminRequire = createRequire(require.resolve('firebase-admin'));
const firestoreRequire = createRequire(adminRequire.resolve('@google-cloud/firestore'));
const apiRequire = createRequire(firestoreRequire.resolve('@google-cloud/firestore-api'));
const gaxRequire = createRequire(apiRequire.resolve('google-gax'));
const rimrafRequire = createRequire(gaxRequire.resolve('rimraf'));
const { rimraf, rimrafSync } = gaxRequire('rimraf');
const { glob, globSync } = rimrafRequire('glob');

test('Google Firestore/gax and overridden gRPC load with supported API', () => {
  assert.equal(typeof apiRequire('google-gax').GrpcClient, 'function');
  assert.equal(typeof gaxRequire('@grpc/grpc-js').Client, 'function');
  assert.equal(typeof require('firebase/firestore').getFirestore, 'function');
});
test('glob and rimraf keep async/sync pattern deletion and untouched files', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'lumi-deps-test-'));
  try {
    fs.mkdirSync(path.join(root, 'nested'));
    fs.writeFileSync(path.join(root, 'one.tmp'), 'test');
    fs.writeFileSync(path.join(root, 'nested', 'two.tmp'), 'test');
    fs.writeFileSync(path.join(root, 'keep.txt'), 'keep');
    assert.equal((await glob('**/*.tmp', { cwd: root })).length, 2);
    assert.equal(globSync('**/*.tmp', { cwd: root }).length, 2);
    await rimraf('**/*.tmp', { glob: { cwd: root, absolute: true } });
    assert.equal(fs.existsSync(path.join(root, 'one.tmp')), false);
    assert.equal(fs.existsSync(path.join(root, 'nested', 'two.tmp')), false);
    assert.equal(fs.readFileSync(path.join(root, 'keep.txt'), 'utf8'), 'keep');
    fs.writeFileSync(path.join(root, 'sync.tmp'), 'test');
    rimrafSync('*.tmp', { glob: { cwd: root, absolute: true } });
    assert.equal(fs.existsSync(path.join(root, 'sync.tmp')), false);
    await rimraf(path.join(root, 'nested'));
    assert.equal(fs.existsSync(path.join(root, 'nested')), false);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
