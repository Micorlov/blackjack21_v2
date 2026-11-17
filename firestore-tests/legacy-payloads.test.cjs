// Replays the Firestore writes and queries of every SHIPPED client generation against a rules file, so a rules change can be
// proven backward compatible before it is deployed. LOCAL EMULATOR ONLY, synthetic users, no production data.
//   RULES_FILE=<path> (default ../firestore.rules). Run once against the previous rules (must pass: the baseline) and once
//   against the new rules (must pass: compatibility).
// Provenance of each payload shape is the repository source at the named commit:
//   FLUTTER vc3  (Play alpha 3, 1.2.0)   8246737 lib/services/social_service.dart, lib/services/error_reporter.dart
//   FLUTTER vc8  (1.6.1, last Flutter)   91fb0df^ lib/services/social_service.dart (identical write shapes for vc4-vc8)
//   UNITY vc10/vc11/vc12 (internal 10, production 12)  3847fbb / 1980dc7 / 5200889 Unity/Assets/Scripts/GameFirebase/*.cs
//   (the three Unity commits have identical GameFirebase source; so does the commit just before the deletion work)
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const { test, before, after, beforeEach } = require('node:test');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, addDoc, getDoc, getDocs, setDoc, query, where, orderBy, limit, serverTimestamp, increment } = require('firebase/firestore');

const RULES = process.env.RULES_FILE || path.join(__dirname, '..', 'firestore.rules');
let env;
before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
  env = await initializeTestEnvironment({ projectId: 'demo-bj21-legacy', firestore: { host, port: Number(port), rules: fs.readFileSync(RULES, 'utf8') } });
});
after(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const anon = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const google = (uid) => env.authenticatedContext(uid, { email: `${uid}@example.com`, email_verified: true, firebase: { sign_in_provider: 'google.com' } }).firestore();
const M = { merge: true };
const CODE = 'ABC234';

// ---- the Flutter client (social_service.dart) -----------------------------------------------------------------
const flutter = {
  async createGroup(db, u) {                                   // get (exists?) then set
    await assertSucceeds(getDoc(doc(db, `groups/${CODE}`)));
    await assertSucceeds(setDoc(doc(db, `groups/${CODE}`), { createdBy: u, createdAt: serverTimestamp() }));
  },
  async writeMembership(db, u, name, v, invitedBy) {           // players merge + group row merge
    await assertSucceeds(setDoc(doc(db, `players/${u}`), { groupCode: CODE, name }, M));
    const row = v === 3 ? { name, updatedAt: serverTimestamp() }
      : { name, updatedAt: serverTimestamp(), tableKey: '', ...(invitedBy ? { invitedBy } : {}) };
    await assertSucceeds(setDoc(doc(db, `groups/${CODE}/players/${u}`), row, M));
  },
  async reportScore(db, u, v, withGroup) {                     // leaderboard merge (+ group row)
    const base = { name: 'Bob', chips: 1250, hourly: -75, daily: 310, hourKey: '2026-08-15T14', dayKey: '2026-08-15', updatedAt: serverTimestamp() };
    const full = v === 3 ? base : { ...base, appVersion: '1.6.1', platform: 'android', country: 'IL' };
    await assertSucceeds(setDoc(doc(db, `leaderboard/${u}`), { ...full, ...(v === 3 ? {} : { playSeconds: increment(42) }) }, M));
    if (withGroup) await assertSucceeds(setDoc(doc(db, `groups/${CODE}/players/${u}`), { ...full, tableKey: 'bronze' }, M));
  },
  async addPlayTime(db, u) { await assertSucceeds(setDoc(doc(db, `leaderboard/${u}`), { playSeconds: increment(30) }, M)); },
  async ensureCreatedAt(db, u) {
    await assertSucceeds(getDoc(doc(db, `leaderboard/${u}`)));
    await assertSucceeds(setDoc(doc(db, `leaderboard/${u}`), { createdAt: serverTimestamp() }, M));
  },
  async worldTop(db) {                                          // the ranked list query
    await assertSucceeds(getDocs(query(collection(db, 'leaderboard'), where('hourKey', '==', '2026-08-15T14'), orderBy('hourly', 'desc'), limit(10))));
    await assertSucceeds(getDocs(query(collection(db, 'leaderboard'), where('dayKey', '==', '2026-08-15'), orderBy('daily', 'desc'), limit(10))));
  },
  async watchMembers(db) { await assertSucceeds(getDocs(collection(db, `groups/${CODE}/players`))); },
  async errorsAndInstalls(db) {                                  // error_reporter.dart (stack may be null)
    await assertSucceeds(addDoc(collection(db, 'installs'), { appVersion: '1.6.1', platform: 'android', at: serverTimestamp() }));
    await assertSucceeds(addDoc(collection(db, 'errors'), { message: 'x'.repeat(500), stack: null, appVersion: '1.6.1', platform: 'android', at: serverTimestamp() }));
    await assertSucceeds(addDoc(collection(db, 'errors'), { message: 'boom', stack: 's'.repeat(2000), appVersion: '1.6.1', platform: 'android', at: serverTimestamp() }));
  },
  async flags(db) { await assertSucceeds(getDoc(doc(db, 'config/features'))); },
  async myGroup(db, u) { await assertSucceeds(getDoc(doc(db, `players/${u}`))); },
};

async function flutterSession(v) {
  const owner = anon('flutter-owner'), joiner = google('flutter-joiner');
  await flutter.flags(owner);
  await flutter.createGroup(owner, 'flutter-owner');
  await flutter.writeMembership(owner, 'flutter-owner', 'Owner', v);
  await flutter.reportScore(owner, 'flutter-owner', v, true);
  await flutter.addPlayTime(owner, 'flutter-owner');
  await flutter.ensureCreatedAt(owner, 'flutter-owner');
  await flutter.watchMembers(owner);
  await flutter.worldTop(owner);
  await flutter.myGroup(owner, 'flutter-owner');
  await flutter.errorsAndInstalls(owner);
  await flutter.writeMembership(joiner, 'flutter-joiner', 'Joiner', v, v === 3 ? undefined : 'flutter-owner');
  await flutter.reportScore(joiner, 'flutter-joiner', v, true);
}
test('FLUTTER vc3 (alpha 3, 1.2.0) full session: group, membership, scores, play time, world list, diagnostics', () => flutterSession(3));
test('FLUTTER vc4-vc8 (1.3.0-1.6.1) full session incl. tableKey and invitedBy', () => flutterSession(8));

// ---- the Unity client (FirebaseSocialService.cs, FirebaseRegistration.cs) -------------------------------------------
async function unitySession() {
  const owner = anon('unity-owner'), joiner = google('unity-joiner');
  await assertSucceeds(getDoc(doc(owner, 'config/features')));
  // EnsureSignedIn -> ReportScore (no group yet) -> EnsureCreatedAtStamped -> FetchMyGroupCode
  const row = (name) => ({ name, chips: 1000, hourly: 0, daily: 0, hourKey: '2026-11-08T20', dayKey: '2026-11-08', updatedAt: serverTimestamp(), appVersion: '1.8.2', platform: 'android', country: 'US' });
  await assertSucceeds(setDoc(doc(owner, 'leaderboard/unity-owner'), { ...row('Guest ABCD'), playSeconds: increment(45) }, M));
  await assertSucceeds(getDoc(doc(owner, 'leaderboard/unity-owner')));
  await assertSucceeds(setDoc(doc(owner, 'leaderboard/unity-owner'), { createdAt: serverTimestamp() }, M));
  await assertSucceeds(getDoc(doc(owner, 'players/unity-owner')));
  await assertSucceeds(addDoc(collection(owner, 'installs'), { appVersion: '1.8.2', platform: 'android', at: serverTimestamp() }));
  // CreateGroup: get, set group, WriteMembership (players merge, then member row)
  await assertSucceeds(getDoc(doc(owner, `groups/${CODE}`)));
  await assertSucceeds(setDoc(doc(owner, `groups/${CODE}`), { createdBy: 'unity-owner', createdAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(owner, 'players/unity-owner'), { groupCode: CODE, name: 'Guest ABCD' }, M));
  await assertSucceeds(setDoc(doc(owner, `groups/${CODE}/players/unity-owner`), { name: 'Guest ABCD', updatedAt: serverTimestamp(), tableKey: '' }, M));
  await assertSucceeds(getDocs(collection(owner, `groups/${CODE}/players`)));          // WatchMembers (Listen)
  // heartbeat: ReportScore with group, AddPlayTime
  await assertSucceeds(setDoc(doc(owner, 'leaderboard/unity-owner'), { ...row('Guest ABCD'), playSeconds: increment(60) }, M));
  await assertSucceeds(setDoc(doc(owner, `groups/${CODE}/players/unity-owner`), { ...row('Guest ABCD'), tableKey: 'vip' }, M));
  await assertSucceeds(setDoc(doc(owner, 'leaderboard/unity-owner'), { playSeconds: increment(25) }, M));
  // JoinGroup by a Google user with a referral pointer, then a repeat join (no invitedBy), then score reports
  await assertSucceeds(getDoc(doc(joiner, `groups/${CODE}`)));
  await assertSucceeds(getDoc(doc(joiner, `groups/${CODE}/players/unity-joiner`)));
  await assertSucceeds(setDoc(doc(joiner, 'players/unity-joiner'), { groupCode: CODE, name: 'Maya Test' }, M));
  await assertSucceeds(setDoc(doc(joiner, `groups/${CODE}/players/unity-joiner`), { name: 'Maya Test', updatedAt: serverTimestamp(), tableKey: '', invitedBy: 'unity-owner' }, M));
  await assertSucceeds(setDoc(doc(joiner, `groups/${CODE}/players/unity-joiner`), { name: 'Maya Test', updatedAt: serverTimestamp(), tableKey: '' }, M));
  await assertSucceeds(setDoc(doc(joiner, `groups/${CODE}/players/unity-joiner`), { ...row('Maya Test'), tableKey: '' }, M));
  // FirebaseRegistration: fatal error record
  await assertSucceeds(addDoc(collection(owner, 'errors'), { message: 'NullReferenceException'.repeat(20).slice(0, 500), stack: 'at X\n'.repeat(300).slice(0, 2000), appVersion: '1.8.2', platform: 'android', at: serverTimestamp() }));
}
test('UNITY vc10/vc11/vc12 (internal 10, production 12) and pre-deletion HEAD full session', unitySession);

test('UNITY: sign-out / sign-in re-adoption reads (players pointer, own group row) still work', async () => {
  const u = google('unity-joiner');
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `groups/${CODE}`), { createdBy: 'someone', createdAt: new Date() });
    await setDoc(doc(ctx.firestore(), 'players/unity-joiner'), { groupCode: CODE, name: 'Maya' });
  });
  await assertSucceeds(getDoc(doc(u, 'players/unity-joiner')));
  await assertSucceeds(getDoc(doc(u, `groups/${CODE}`)));
});

test('Legacy documents with an UNEXPECTED extra key (from any older build) can still be updated by their owner', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `groups/${CODE}`), { createdBy: 'old', createdAt: new Date() });
    await setDoc(doc(db, 'leaderboard/old'), { name: 'Old', chips: 5, legacyOnlyField: 'kept', weird: { a: 1 } });
    await setDoc(doc(db, `groups/${CODE}/players/old`), { name: 'Old', legacyOnlyField: 'kept' });
  });
  const db = anon('old');
  await assertSucceeds(setDoc(doc(db, 'leaderboard/old'), { chips: 6, hourly: 1, updatedAt: serverTimestamp() }, M));
  await assertSucceeds(setDoc(doc(db, `groups/${CODE}/players/old`), { name: 'Old2', updatedAt: serverTimestamp() }, M));
});
