// Firestore security-rules tests for account and data deletion. Run against the LOCAL emulator only (see README "Account
// and data deletion"): synthetic users, no live project, nothing deployed.
//   npx firebase-tools emulators:exec --only firestore --project demo-bj21-rules \
//     --config <config pointing rules at ../firestore.rules> "NODE_PATH=<node_modules> node --test firestore-tests/rules.test.cjs"
const assert = require('node:assert');
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, getDoc, setDoc, deleteDoc, updateDoc } = require('firebase/firestore');

const ADMIN_EMAIL = 'micorlov@gmail.com';
let env;

before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({
    projectId: 'demo-bj21-rules',
    firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') },
  });
});
after(async () => { await env.cleanup(); });

// alice created group ABC234; bob joined through her invite; carol is an unrelated player.
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'groups/ABC234'), { createdBy: 'alice' });
    await setDoc(doc(db, 'groups/ABC234/players/alice'), { name: 'Alice', tableKey: '' });
    await setDoc(doc(db, 'groups/ABC234/players/bob'), { name: 'Bob', tableKey: '', invitedBy: 'alice' });
    for (const u of ['alice', 'bob', 'carol']) {
      await setDoc(doc(db, `players/${u}`), { name: u, groupCode: 'ABC234' });
      await setDoc(doc(db, `leaderboard/${u}`), { name: u, chips: 1000, country: 'IL' });
    }
    await setDoc(doc(db, 'installs/i1'), { appVersion: '1.8.2', platform: 'android' });
    await setDoc(doc(db, 'errors/e1'), { message: 'x', stack: 'y' });
    await setDoc(doc(db, 'config/features'), { reviewPromptEnabled: true });
  });
});

const as = (uid, claims) => env.authenticatedContext(uid, claims).firestore();
// withSecurityRulesDisabled returns nothing, so carry the answer out through a variable.
const exists = async (path) => {
  let found;
  await env.withSecurityRulesDisabled(async (ctx) => { found = (await getDoc(doc(ctx.firestore(), path))).exists(); });
  assert.strictEqual(typeof found, 'boolean', 'existence check must return a boolean');
  return found;
};

// ---- allowed: a user removing their own records ----------------------------------------------------

test('a member can delete their own group row', async () => {
  await assertSucceeds(deleteDoc(doc(as('bob'), 'groups/ABC234/players/bob')));
  assert(!(await exists('groups/ABC234/players/bob')));
});

test('a user can delete their own players and leaderboard documents', async () => {
  const db = as('bob');
  await assertSucceeds(deleteDoc(doc(db, 'players/bob')));
  await assertSucceeds(deleteDoc(doc(db, 'leaderboard/bob')));
});

test('the exact deletion sequence works for bob and leaves everyone else untouched', async () => {
  const db = as('bob');
  await assertSucceeds(deleteDoc(doc(db, 'groups/ABC234/players/bob')));
  await assertSucceeds(deleteDoc(doc(db, 'players/bob')));
  await assertSucceeds(deleteDoc(doc(db, 'leaderboard/bob')));
  for (const p of ['groups/ABC234', 'groups/ABC234/players/alice', 'players/alice', 'players/carol', 'leaderboard/alice',
                   'leaderboard/carol', 'installs/i1', 'errors/e1', 'config/features']) assert(await exists(p), p + ' must survive');
  for (const p of ['groups/ABC234/players/bob', 'players/bob', 'leaderboard/bob']) assert(!(await exists(p)), p + ' must be gone');
});

test('deleting a row that does not exist is allowed (the delete is safe to repeat)', async () => {
  await assertSucceeds(deleteDoc(doc(as('dave'), 'groups/ABC234/players/dave')));
  await assertSucceeds(deleteDoc(doc(as('dave'), 'leaderboard/dave')));
});

// ---- refused: cross-user and unauthenticated -------------------------------------------------------

test('a member cannot delete another member\'s group row', async () => {
  await assertFails(deleteDoc(doc(as('bob'), 'groups/ABC234/players/alice')));
  await assertFails(deleteDoc(doc(as('carol'), 'groups/ABC234/players/bob')));
  assert(await exists('groups/ABC234/players/alice'));
  assert(await exists('groups/ABC234/players/bob'));
});

test('a user cannot delete another user\'s players or leaderboard document', async () => {
  const db = as('bob');
  await assertFails(deleteDoc(doc(db, 'players/alice')));
  await assertFails(deleteDoc(doc(db, 'leaderboard/alice')));
  assert(await exists('players/alice'));
  assert(await exists('leaderboard/alice'));
});

test('the group creator cannot delete other members\' rows or the group itself', async () => {
  const db = as('alice');
  await assertFails(deleteDoc(doc(db, 'groups/ABC234/players/bob')));
  await assertFails(deleteDoc(doc(db, 'groups/ABC234')));
  assert(await exists('groups/ABC234'));
});

test('nobody can delete the group document (not even a member deleting their own row)', async () => {
  await assertFails(deleteDoc(doc(as('bob'), 'groups/ABC234')));
});

test('an unauthenticated client cannot delete anything', async () => {
  const db = env.unauthenticatedContext().firestore();
  for (const p of ['groups/ABC234/players/bob', 'players/bob', 'leaderboard/bob', 'groups/ABC234']) {
    await assertFails(deleteDoc(doc(db, p)));
  }
});

test('the admin account stays read-only for group rows and cannot delete them', async () => {
  const db = as('admin-uid', { email: ADMIN_EMAIL });
  await assertFails(deleteDoc(doc(db, 'groups/ABC234/players/bob')));
  await assertFails(deleteDoc(doc(db, 'leaderboard/bob')));
});

test('install and error records and feature flags stay undeletable by app users', async () => {
  const db = as('bob');
  await assertFails(deleteDoc(doc(db, 'installs/i1')));
  await assertFails(deleteDoc(doc(db, 'errors/e1')));
  await assertFails(deleteDoc(doc(db, 'config/features')));
});

// ---- unchanged behaviour around the new rule -------------------------------------------------------

test('writes to someone else\'s group row are still refused', async () => {
  const db = as('bob');
  await assertFails(updateDoc(doc(db, 'groups/ABC234/players/alice'), { name: 'hacked' }));
  await assertFails(setDoc(doc(db, 'groups/ABC234/players/erin'), { name: 'forged', tableKey: '' }));
});

test('invitedBy is still write-once: it cannot be retargeted on an existing row', async () => {
  await assertFails(updateDoc(doc(as('bob'), 'groups/ABC234/players/bob'), { invitedBy: 'carol' }));
});

test('a member can still update their own row', async () => {
  await assertSucceeds(updateDoc(doc(as('bob'), 'groups/ABC234/players/bob'), { name: 'Bobby', tableKey: 'bronze' }));
});

test('the trio and headsup room keys are accepted as presence, and an unknown key is not', async () => {
  const row = doc(as('bob'), 'groups/ABC234/players/bob');
  await assertSucceeds(updateDoc(row, { tableKey: 'trio' }));
  await assertSucceeds(updateDoc(row, { tableKey: 'headsup' }));
  await assertSucceeds(updateDoc(row, { tableKey: 'vip' }));
  await assertFails(updateDoc(row, { tableKey: 'poker' }));
});

test('after deleting, a user can rejoin only through the creator\'s own invite (no retargeting)', async () => {
  const db = as('bob');
  await assertSucceeds(deleteDoc(doc(db, 'groups/ABC234/players/bob')));
  await assertFails(setDoc(doc(db, 'groups/ABC234/players/bob'), { name: 'Bob', tableKey: '', invitedBy: 'carol' }));
  await assertSucceeds(setDoc(doc(db, 'groups/ABC234/players/bob'), { name: 'Bob', tableKey: '', invitedBy: 'alice' }));
});

test('reads: a stranger cannot read another player\'s pointer document nor fetch another leaderboard row by id', async () => {
  await assertFails(getDoc(doc(as('bob'), 'players/alice')));
  await assertFails(getDoc(doc(as('bob'), 'leaderboard/alice')));       // hardened: ranked lists only (legacy-payloads test)
  await assertSucceeds(getDoc(doc(as('bob'), 'leaderboard/bob')));
});

