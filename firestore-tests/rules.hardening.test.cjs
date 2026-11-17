// Adversarial tests for the hardened firestore.rules: admin gate, schema, types, sizes, immutability, authority, default deny,
// and the account-deletion cleanup paths (creator tombstone, referencing-row clearing). LOCAL EMULATOR ONLY, synthetic users.
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { test, before, after, beforeEach } = require('node:test');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, collectionGroup, addDoc, getDoc, getDocs, setDoc, updateDoc, deleteDoc, query, where, orderBy, limit, serverTimestamp, increment } = require('firebase/firestore');

let env;
before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({ projectId: 'demo-bj21-hardening',
    firestore: { host, port: Number(port), rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8') } });
});
after(async () => { await env.cleanup(); });
const exists = async (p) => { let f; await env.withSecurityRulesDisabled(async (c) => { f = (await getDoc(doc(c.firestore(), p))).exists(); }); return f; };
const data = async (p) => { let f; await env.withSecurityRulesDisabled(async (c) => { f = (await getDoc(doc(c.firestore(), p))).data(); }); return f; };
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'groups/ABC234'), { createdBy: 'alice', createdAt: new Date() });
    await setDoc(doc(db, 'groups/ABC234/players/alice'), { name: 'Alice', tableKey: '' });
    await setDoc(doc(db, 'groups/ABC234/players/bob'), { name: 'Bob', tableKey: '', invitedBy: 'alice' });
    await setDoc(doc(db, 'groups/ABC234/players/carol'), { name: 'Carol', tableKey: '', invitedBy: 'alice' });
    await setDoc(doc(db, 'groups/OTHER2'), { createdBy: 'dave', createdAt: new Date() });
    await setDoc(doc(db, 'groups/OTHER2/players/dave'), { name: 'Dave', tableKey: '' });
    await setDoc(doc(db, 'groups/OTHER2/players/erin'), { name: 'Erin', tableKey: '', invitedBy: 'dave' });
    for (const u of ['alice', 'bob', 'carol', 'dave']) {
      await setDoc(doc(db, `players/${u}`), { name: u, groupCode: 'ABC234' });
      await setDoc(doc(db, `leaderboard/${u}`), { name: u, chips: 1000, hourly: 0, daily: 0, country: 'IL', playSeconds: 100, createdAt: new Date() });
    }
    await setDoc(doc(db, 'config/features'), { reviewPromptEnabled: true });
  });
});
const anon = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const google = (uid, extra = {}) => env.authenticatedContext(uid, { email: `${uid}@example.com`, email_verified: true, firebase: { sign_in_provider: 'google.com' }, ...extra }).firestore();
const ADMIN = 'micorlov@gmail.com';
const big = (n) => 'x'.repeat(n);

// ---------------------------------------------------------------- admin gate
test('admin: verified Google token with the admin address is admin', async () => {
  const db = env.authenticatedContext('adm', { email: ADMIN, email_verified: true, firebase: { sign_in_provider: 'google.com' } }).firestore();
  await assertSucceeds(getDocs(collection(db, 'players')));
  await assertSucceeds(getDocs(collectionGroup(db, 'players')));
  await assertSucceeds(getDocs(collection(db, 'groups')));
  await assertSucceeds(getDocs(collection(db, 'errors')));
  await assertSucceeds(setDoc(doc(db, 'config/features'), { reviewPromptEnabled: false }));
});
test('admin: UNVERIFIED email, a non-Google provider, a missing claim or a different address is NOT admin', async () => {
  const cases = [
    { email: ADMIN, email_verified: false, firebase: { sign_in_provider: 'google.com' } },
    { email: ADMIN, email_verified: true, firebase: { sign_in_provider: 'password' } },
    { email: ADMIN, firebase: { sign_in_provider: 'google.com' } },
    { email: 'other@example.com', email_verified: true, firebase: { sign_in_provider: 'google.com' } },
    { email_verified: true, firebase: { sign_in_provider: 'google.com' } },
    { email: ADMIN.toUpperCase(), email_verified: true, firebase: { sign_in_provider: 'google.com' } },
  ];
  for (const c of cases) {
    const db = env.authenticatedContext('x', c).firestore();
    await assertFails(getDocs(collection(db, 'players')));
    await assertFails(getDocs(collection(db, 'errors')));
    await assertFails(setDoc(doc(db, 'config/features'), { a: 1 }));
  }
  await assertFails(getDocs(collection(anon('y'), 'players')));
});
test('admin stays read-only on user data (cannot write or delete players, leaderboard, member rows)', async () => {
  const db = env.authenticatedContext('adm', { email: ADMIN, email_verified: true, firebase: { sign_in_provider: 'google.com' } }).firestore();
  await assertFails(setDoc(doc(db, 'players/bob'), { name: 'x' }));
  await assertFails(setDoc(doc(db, 'leaderboard/bob'), { name: 'x' }));
  await assertFails(deleteDoc(doc(db, 'groups/ABC234/players/bob')));
  await assertFails(updateDoc(doc(db, 'groups/ABC234/players/bob'), { invitedBy: 'deleted' }));
});

// ---------------------------------------------------------------- default deny and unauthenticated
test('default deny: unknown collections and collection-group queries; unauthenticated gets nothing', async () => {
  const db = anon('bob'), nobody = env.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(db, 'secrets/x'), { a: 1 }));
  await assertFails(getDoc(doc(db, 'secrets/x')));
  await assertFails(getDocs(collectionGroup(db, 'players')));
  for (const p of ['players/bob', 'leaderboard/bob', 'groups/ABC234', 'groups/ABC234/players/bob', 'config/features']) await assertFails(getDoc(doc(nobody, p)));
  await assertFails(getDocs(query(collection(nobody, 'leaderboard'), limit(10))));
  await assertFails(addDoc(collection(nobody, 'installs'), { appVersion: '1', platform: 'android', at: serverTimestamp() }));
});

// ---------------------------------------------------------------- leaderboard reads, schema, types, sizes
test('leaderboard: ranked lists with a limit work; unbounded or oversized lists and other users\' documents by id do not', async () => {
  const db = anon('bob');
  await assertSucceeds(getDocs(query(collection(db, 'leaderboard'), where('dayKey', '==', '2026-11-08'), orderBy('daily', 'desc'), limit(10))));
  await assertSucceeds(getDocs(query(collection(db, 'leaderboard'), limit(100))));
  await assertFails(getDocs(collection(db, 'leaderboard')));
  await assertFails(getDocs(query(collection(db, 'leaderboard'), limit(101))));
  await assertFails(getDoc(doc(db, 'leaderboard/alice')));
  await assertSucceeds(getDoc(doc(db, 'leaderboard/bob')));
});
test('leaderboard: schema pollution, wrong types, out-of-range numbers and oversize strings are rejected on create and update', async () => {
  const db = anon('newbie');
  const bad = [
    { isAdmin: true }, { role: 'admin' }, { name: 5 }, { name: big(129) }, { chips: '1000' }, { chips: -1 }, { chips: 1.5 }, { chips: 1e12 },
    { hourly: 'x' }, { daily: 1e12 }, { hourKey: big(21) }, { country: big(9) }, { platform: big(17) }, { appVersion: big(33) },
    { updatedAt: 'now' }, { createdAt: 'forged' }, { playSeconds: -5 }, { playSeconds: 604801 }, { playSeconds: '9' }, { tableKey: 'vip' },
  ];
  for (const b of bad) await assertFails(setDoc(doc(db, 'leaderboard/newbie'), { name: 'N', chips: 10, ...b }));
  await assertSucceeds(setDoc(doc(db, 'leaderboard/newbie'), { name: 'N', chips: 10, hourly: -5, daily: 5, hourKey: '2026-11-08T20', dayKey: '2026-11-08', updatedAt: serverTimestamp(), appVersion: '1.8.3', platform: 'android', country: 'US', playSeconds: 45 }));
  const own = anon('bob');
  for (const b of bad.filter((x) => !('createdAt' in x) && !('playSeconds' in x))) await assertFails(updateDoc(doc(own, 'leaderboard/bob'), b));
});
test('leaderboard: createdAt is stamped once; playSeconds only grows and by at most a week per write', async () => {
  const db = anon('bob');
  await assertFails(updateDoc(doc(db, 'leaderboard/bob'), { createdAt: serverTimestamp() }));          // already has one
  await assertFails(updateDoc(doc(db, 'leaderboard/bob'), { playSeconds: 50 }));                       // 100 -> 50
  await assertFails(updateDoc(doc(db, 'leaderboard/bob'), { playSeconds: 100 + 604801 }));
  await assertSucceeds(updateDoc(doc(db, 'leaderboard/bob'), { playSeconds: 150 }));
  await assertSucceeds(setDoc(doc(db, 'leaderboard/bob'), { playSeconds: increment(30) }, { merge: true }));
  await assertSucceeds(setDoc(doc(anon('fresh'), 'leaderboard/fresh'), { createdAt: serverTimestamp() }));
});
test('leaderboard/players: cross-user writes and deletes refused', async () => {
  const db = anon('bob');
  await assertFails(updateDoc(doc(db, 'leaderboard/alice'), { chips: 0 }));
  await assertFails(deleteDoc(doc(db, 'leaderboard/alice')));
  await assertFails(setDoc(doc(db, 'players/alice'), { name: 'x' }, { merge: true }));
  await assertFails(deleteDoc(doc(db, 'players/alice')));
});
test('players: only groupCode and name, well-formed, bounded', async () => {
  const db = anon('bob');
  await assertSucceeds(setDoc(doc(db, 'players/bob'), { groupCode: 'XYZ789', name: 'Bob' }, { merge: true }));
  for (const b of [{ role: 'admin' }, { groupCode: big(13) }, { groupCode: 'bad code!' }, { groupCode: 7 }, { name: big(129) }, { name: 7 }])
    await assertFails(setDoc(doc(db, 'players/bob'), b, { merge: true }));
});

// ---------------------------------------------------------------- groups and member rows
test('groups: create needs a well-formed code, only createdBy+createdAt, own uid; nobody overwrites or deletes', async () => {
  const db = anon('bob');
  await assertFails(setDoc(doc(db, 'groups/ab'), { createdBy: 'bob', createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'groups/BAD CODE'), { createdBy: 'bob', createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'groups/NEW111'), { createdBy: 'alice', createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'groups/NEW111'), { createdBy: 'bob', createdAt: serverTimestamp(), extra: 1 }));
  await assertFails(setDoc(doc(db, 'groups/NEW111'), { createdBy: 'bob', createdAt: 'x' }));
  await assertSucceeds(setDoc(doc(db, 'groups/NEW111'), { createdBy: 'bob', createdAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'groups/ABC234'), { createdBy: 'bob', createdAt: serverTimestamp() }));
  await assertFails(deleteDoc(doc(anon('alice'), 'groups/ABC234')));
});
test('member rows: only in an existing group, only allowed keys, typed and bounded', async () => {
  const db = anon('erin2');
  await assertFails(setDoc(doc(db, 'groups/NOGROUP/players/erin2'), { name: 'E', tableKey: '' }));
  const ok = { name: 'E', updatedAt: serverTimestamp(), tableKey: '' };
  for (const b of [{ role: 'admin' }, { chips: '1' }, { name: big(129) }, { playSeconds: 5 }, { createdAt: serverTimestamp() }, { tableKey: 'gold' }, { invitedBy: 'carol' }, { invitedBy: 'erin2' }, { invitedBy: 7 }])
    await assertFails(setDoc(doc(db, 'groups/ABC234/players/erin2'), { ...ok, ...b }));
  await assertSucceeds(setDoc(doc(db, 'groups/ABC234/players/erin2'), { ...ok, invitedBy: 'alice', chips: 10, hourly: -3, country: 'DE' }));
});
test('member rows: invitedBy cannot be added later or retargeted by the owner; creator cannot edit or delete others\' rows', async () => {
  await assertFails(updateDoc(doc(anon('bob'), 'groups/ABC234/players/bob'), { invitedBy: 'carol' }));
  await assertFails(updateDoc(doc(anon('alice'), 'groups/ABC234/players/bob'), { name: 'renamed' }));
  await assertFails(deleteDoc(doc(anon('alice'), 'groups/ABC234/players/bob')));
  await assertFails(updateDoc(doc(anon('erin'), 'groups/OTHER2/players/erin'), { invitedBy: 'erin' }));
});

// ---------------------------------------------------------------- account deletion cleanup (creator side)
test('cleanup: the inviter clears ONLY their own uid from others\' invitedBy, with exactly the value "deleted"', async () => {
  const alice = anon('alice');
  await assertSucceeds(updateDoc(doc(alice, 'groups/ABC234/players/bob'), { invitedBy: 'deleted' }));
  await assertSucceeds(updateDoc(doc(alice, 'groups/ABC234/players/carol'), { invitedBy: 'deleted' }));
  assert.strictEqual((await data('groups/ABC234/players/bob')).invitedBy, 'deleted');
  assert.strictEqual((await data('groups/ABC234/players/bob')).name, 'Bob', 'no other field touched');
});
test('cleanup adversarial: wrong person, wrong value, extra field, someone else\'s inviter, unrelated rows all refused', async () => {
  const mallory = anon('mallory');
  await assertFails(updateDoc(doc(mallory, 'groups/ABC234/players/bob'), { invitedBy: 'deleted' }));          // not the referenced user
  const alice = anon('alice');
  await assertFails(updateDoc(doc(alice, 'groups/ABC234/players/bob'), { invitedBy: 'mallory' }));            // arbitrary value
  await assertFails(updateDoc(doc(alice, 'groups/ABC234/players/bob'), { invitedBy: null }));
  await assertFails(updateDoc(doc(alice, 'groups/ABC234/players/bob'), { invitedBy: 'deleted', name: 'pwn' }));   // extra field
  await assertFails(updateDoc(doc(alice, 'groups/OTHER2/players/erin'), { invitedBy: 'deleted' }));           // row names dave, not alice
  await assertFails(updateDoc(doc(alice, 'groups/ABC234/players/alice'), { invitedBy: 'deleted' }));          // no pointer there
  await assertFails(deleteDoc(doc(alice, 'groups/ABC234/players/bob')));
  assert.strictEqual((await data('groups/ABC234/players/bob')).invitedBy, 'alice');
});
test('cleanup: after clearing, the invitee can still update their own row and the cleared value is stable', async () => {
  await assertSucceeds(updateDoc(doc(anon('alice'), 'groups/ABC234/players/bob'), { invitedBy: 'deleted' }));
  const bob = anon('bob');
  await assertSucceeds(setDoc(doc(bob, 'groups/ABC234/players/bob'), { name: 'Bobby', updatedAt: serverTimestamp(), tableKey: 'bronze' }, { merge: true }));
  await assertFails(updateDoc(doc(bob, 'groups/ABC234/players/bob'), { invitedBy: 'alice' }));               // cannot restore
  await assertFails(updateDoc(doc(anon('alice'), 'groups/ABC234/players/bob'), { invitedBy: 'deleted' }));   // alice no longer referenced
});
test('cleanup: the creator tombstones their own group (createdBy -> "deleted") and nothing else, and it cannot be reverted or taken', async () => {
  const alice = anon('alice');
  await assertFails(updateDoc(doc(anon('bob'), 'groups/ABC234'), { createdBy: 'deleted' }));
  await assertFails(updateDoc(doc(alice, 'groups/ABC234'), { createdBy: 'bob' }));
  await assertFails(updateDoc(doc(alice, 'groups/ABC234'), { createdBy: 'deleted', createdAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(alice, 'groups/ABC234'), { createdBy: 'deleted', extra: 1 }));
  await assertSucceeds(updateDoc(doc(alice, 'groups/ABC234'), { createdBy: 'deleted' }));
  await assertFails(updateDoc(doc(alice, 'groups/ABC234'), { createdBy: 'alice' }));                         // cannot revert
  await assertFails(updateDoc(doc(anon('bob'), 'groups/ABC234'), { createdBy: 'bob' }));                      // cannot take over
  assert.strictEqual((await data('groups/ABC234')).createdBy, 'deleted');
});
test('cleanup queries: a creator can list THEIR groups and the rows that name them; strangers cannot enumerate', async () => {
  const alice = anon('alice');
  const g = await assertSucceeds(getDocs(query(collection(alice, 'groups'), where('createdBy', '==', 'alice'))));
  assert.strictEqual(g.size, 1);
  const r = await assertSucceeds(getDocs(query(collection(alice, 'groups/ABC234/players'), where('invitedBy', '==', 'alice'))));
  assert.strictEqual(r.size, 2);
  await assertFails(getDocs(collection(alice, 'groups')));
  await assertFails(getDocs(query(collection(alice, 'groups'), where('createdBy', '==', 'dave'))));
});
test('cleanup: an invitedBy of "deleted" does not block later joiners (old clients write the creator value they read)', async () => {
  await assertSucceeds(updateDoc(doc(anon('alice'), 'groups/ABC234'), { createdBy: 'deleted' }));
  await assertSucceeds(setDoc(doc(anon('frank'), 'groups/ABC234/players/frank'), { name: 'F', tableKey: '', invitedBy: 'deleted' }));
  await assertFails(setDoc(doc(anon('gina'), 'groups/ABC234/players/gina'), { name: 'G', tableKey: '', invitedBy: 'alice' }));
});
test('full deletion for a group creator leaves every other user\'s documents byte-identical apart from the cleared pointers', async () => {
  const before = { dave: await data('players/dave'), lbDave: await data('leaderboard/dave'), erin: await data('groups/OTHER2/players/erin'), g2: await data('groups/OTHER2') };
  const alice = anon('alice');
  for (const r of ['bob', 'carol']) await assertSucceeds(updateDoc(doc(alice, `groups/ABC234/players/${r}`), { invitedBy: 'deleted' }));
  await assertSucceeds(updateDoc(doc(alice, 'groups/ABC234'), { createdBy: 'deleted' }));
  await assertSucceeds(deleteDoc(doc(alice, 'groups/ABC234/players/alice')));
  await assertSucceeds(deleteDoc(doc(alice, 'players/alice')));
  await assertSucceeds(deleteDoc(doc(alice, 'leaderboard/alice')));
  for (const p of ['groups/ABC234/players/alice', 'players/alice', 'leaderboard/alice']) assert(!(await exists(p)), p);
  assert.deepStrictEqual(await data('players/dave'), before.dave);
  assert.deepStrictEqual(await data('leaderboard/dave'), before.lbDave);
  assert.deepStrictEqual(await data('groups/OTHER2/players/erin'), before.erin);
  assert.deepStrictEqual(await data('groups/OTHER2'), before.g2);
  assert.strictEqual((await data('groups/ABC234/players/carol')).name, 'Carol');
  const text = JSON.stringify([await data('groups/ABC234'), await data('groups/ABC234/players/bob'), await data('groups/ABC234/players/carol')]);
  assert(!text.includes('alice'), 'no reference to the deleted uid is left in the group or in the rows that named it');
});

// ---------------------------------------------------------------- diagnostics
test('errors/installs: legacy shapes pass; extra keys (uid), oversize, wrong types, overwrite and delete are refused', async () => {
  const db = anon('bob');
  await assertSucceeds(addDoc(collection(db, 'installs'), { appVersion: '1.8.3', platform: 'android', at: serverTimestamp() }));
  await assertSucceeds(addDoc(collection(db, 'errors'), { message: 'm', stack: null, appVersion: '1.8.3', platform: 'android', at: serverTimestamp() }));
  await assertSucceeds(addDoc(collection(db, 'errors'), { message: big(500), stack: big(2000), appVersion: '1.8.3', platform: 'android', at: serverTimestamp() }));
  for (const b of [{ uid: 'bob' }, { message: big(1001) }, { stack: big(4001) }, { message: 5 }, { at: 'now' }, { appVersion: big(33) }, { extra: 1 }])
    await assertFails(addDoc(collection(db, 'errors'), { message: 'm', appVersion: '1', platform: 'a', at: serverTimestamp(), ...b }));
  await assertFails(addDoc(collection(db, 'installs'), { appVersion: '1', platform: 'a', at: serverTimestamp(), uid: 'bob' }));
  await assertFails(setDoc(doc(db, `errors/${big(41)}`), { message: 'm', at: serverTimestamp() }));
  await assertFails(addDoc(collection(env.unauthenticatedContext().firestore(), 'errors'), { message: 'm', at: serverTimestamp() }));
});
