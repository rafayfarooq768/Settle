// Security rules tests for firestore.rules, run on the local Firestore
// emulator (free, nothing touches the real project). From the repo root:
//   firebase emulators:exec --only firestore --project demo-settle "npm --prefix firestore-tests test"
//
// Each write below mirrors what the app's repositories do (lib/features/*/data).
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;
const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-settle',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// ---------------------------------------------------------------- helpers

const member = (name, uid = null) => ({
  displayName: name,
  uid,
  claimedAt: null,
  joinedAt: serverTimestamp(),
  active: true,
  paymentMethods: [],
  phone: '',
});

const activity = (type, actorMemberId) => ({
  type,
  actorMemberId,
  targetId: null,
  summary: '',
  before: null,
  after: null,
  createdAt: serverTimestamp(),
});

/** GroupRepository.createGroup. Alice creates "Chai" with code CHAI-7KQ2M. */
async function createGroup(uid = 'alice', code = 'CHAI-7KQ2M') {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, 'groups/g1'), {
    name: 'Chai',
    type: 'Friends',
    createdBy: uid,
    createdAt: serverTimestamp(),
    joinCode: code,
    currency: 'PKR',
    memberUids: [uid],
  });
  batch.set(doc(d, 'groups/g1/members/m-alice'), member('Alice', uid));
  batch.set(doc(d, `joinCodes/${code}`), { groupId: 'g1' });
  batch.set(doc(d, 'groups/g1/activity/a1'), activity('groupCreated', 'm-alice'));
  await batch.commit();
}

/** GroupRepository.join */
function join(uid, code = 'CHAI-7KQ2M', groupId = 'g1') {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, `joinCodes/${code}/joins/${uid}`), {
    groupId,
    joinedAt: serverTimestamp(),
  });
  batch.update(doc(d, `groups/${groupId}`), { memberUids: arrayUnion(uid) });
  return batch.commit();
}

/** join + GroupRepository.joinAsNewMember */
async function joinAsNew(uid, memberId) {
  await join(uid);
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, `groups/g1/members/${memberId}`), member(uid, uid));
  batch.set(doc(d, `groups/g1/activity/join-${uid}`), activity('memberJoined', memberId));
  await batch.commit();
}

function addPlaceholder(uid, actor, memberId, name) {
  const d = db(uid);
  const batch = writeBatch(d);
  batch.set(doc(d, `groups/g1/members/${memberId}`), member(name));
  batch.set(doc(d, `groups/g1/activity/ph-${memberId}`), activity('placeholderAdded', actor));
  return batch.commit();
}

const expense = (uid, overrides = {}) => ({
  title: 'Chai',
  amount: 100000,
  date: Timestamp.now(),
  createdBy: uid,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  deleted: false,
  splitMode: 'equal',
  payers: { 'm-alice': 100000 },
  shares: { 'm-alice': 50000, 'm-bob': 50000 },
  splitInput: {},
  note: '',
  ...overrides,
});

const settlement = (uid, from, to, status = 'pending') => ({
  from,
  to,
  amount: 50000,
  status,
  createdBy: uid,
  createdAt: serverTimestamp(),
  confirmedAt: status === 'confirmed' ? serverTimestamp() : null,
});

// ------------------------------------------------------------------ tests

describe('signed out', () => {
  test('cannot read or write anything', async () => {
    await createGroup();
    await assertFails(getDoc(doc(anon(), 'groups/g1')));
    await assertFails(getDoc(doc(anon(), 'joinCodes/CHAI-7KQ2M')));
    await assertFails(setDoc(doc(anon(), 'users/x'), { displayName: 'x' }));
  });
});

describe('users', () => {
  const profile = () => ({
    displayName: 'Alice',
    email: 'a@example.com',
    createdAt: serverTimestamp(),
    paymentMethods: [],
    phone: '',
  });

  test('owner can create, read and update their profile', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'users/alice'), profile()));
    await assertSucceeds(getDoc(doc(db('alice'), 'users/alice')));
    await assertSucceeds(
      updateDoc(doc(db('alice'), 'users/alice'), { displayName: 'Ali' }),
    );
    await assertSucceeds(
      updateDoc(doc(db('alice'), 'users/alice'), { phone: '+923001234567' }),
    );
    await assertFails(
      updateDoc(doc(db('alice'), 'users/alice'), { phone: 'x'.repeat(21) }),
    );
  });

  test('nobody else can read or write it', async () => {
    await setDoc(doc(db('alice'), 'users/alice'), profile());
    await assertFails(getDoc(doc(db('bob'), 'users/alice')));
    await assertFails(setDoc(doc(db('bob'), 'users/bob2'), profile()));
    await assertFails(
      updateDoc(doc(db('bob'), 'users/alice'), { displayName: 'x' }),
    );
  });
});

describe('groups', () => {
  test('creator can create a group and read it; others cannot', async () => {
    await assertSucceeds(createGroup());
    await assertSucceeds(getDoc(doc(db('alice'), 'groups/g1')));
    await assertFails(getDoc(doc(db('bob'), 'groups/g1')));
    await assertFails(getDocs(collection(db('bob'), 'groups/g1/members')));
  });

  test('cannot create a group with someone else in it', async () => {
    const d = db('alice');
    const batch = writeBatch(d);
    batch.set(doc(d, 'groups/g1'), {
      name: 'Chai',
      type: '',
      createdBy: 'alice',
      createdAt: serverTimestamp(),
      joinCode: 'CHAI-7KQ2M',
      currency: 'PKR',
      memberUids: ['alice', 'bob'],
    });
    batch.set(doc(d, 'joinCodes/CHAI-7KQ2M'), { groupId: 'g1' });
    await assertFails(batch.commit());
  });

  test('cannot claim a join code for another group', async () => {
    await createGroup();
    await assertFails(
      setDoc(doc(db('bob'), 'joinCodes/FAKE-22222'), { groupId: 'g1' }),
    );
  });

  test('Home query: list only my groups', async () => {
    await createGroup();
    const { query, where } = await import('firebase/firestore');
    await assertSucceeds(
      getDocs(
        query(
          collection(db('alice'), 'groups'),
          where('memberUids', 'array-contains', 'alice'),
        ),
      ),
    );
    await assertFails(getDocs(collection(db('bob'), 'groups')));
  });

  test('members can rename; cannot change createdBy', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await assertSucceeds(
      updateDoc(doc(db('bob'), 'groups/g1'), { name: 'Chai club', type: 'Trip' }),
    );
    await assertFails(updateDoc(doc(db('bob'), 'groups/g1'), { createdBy: 'bob' }));
  });
});

describe('joining with a code', () => {
  test('look up a code by its id, but never list codes', async () => {
    await createGroup();
    await assertSucceeds(getDoc(doc(db('bob'), 'joinCodes/CHAI-7KQ2M')));
    await assertFails(getDocs(collection(db('bob'), 'joinCodes')));
  });

  test('with the right code: join, then see members and pick "I\'m not listed"', async () => {
    await createGroup();
    await assertSucceeds(join('bob'));
    await assertSucceeds(getDocs(collection(db('bob'), 'groups/g1/members')));
    const d = db('bob');
    const batch = writeBatch(d);
    batch.set(doc(d, 'groups/g1/members/m-bob'), member('Bob', 'bob'));
    batch.set(doc(d, 'groups/g1/activity/j'), activity('memberJoined', 'm-bob'));
    await assertSucceeds(batch.commit());
  });

  test('without proving the code, cannot add yourself', async () => {
    await createGroup();
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1'), { memberUids: arrayUnion('bob') }),
    );
  });

  test('a wrong code fails', async () => {
    await createGroup();
    await assertFails(join('bob', 'CHAI-WRONG'));
  });

  test("another group's code fails", async () => {
    await createGroup();
    const d = db('carol');
    const batch = writeBatch(d);
    batch.set(doc(d, 'groups/g2'), {
      name: 'Trip',
      type: '',
      createdBy: 'carol',
      createdAt: serverTimestamp(),
      joinCode: 'TRIP-33333',
      currency: 'PKR',
      memberUids: ['carol'],
    });
    batch.set(doc(d, 'joinCodes/TRIP-33333'), { groupId: 'g2' });
    await batch.commit();
    await assertFails(join('bob', 'TRIP-33333', 'g1'));
  });

  test('cannot add someone else while joining', async () => {
    await createGroup();
    const d = db('bob');
    const batch = writeBatch(d);
    batch.set(doc(d, 'joinCodes/CHAI-7KQ2M/joins/bob'), {
      groupId: 'g1',
      joinedAt: serverTimestamp(),
    });
    batch.update(doc(d, 'groups/g1'), { memberUids: arrayUnion('bob', 'mallory') });
    await assertFails(batch.commit());
  });

  test('regenerating the code: old code stops working, new one works', async () => {
    await createGroup();
    const d = db('alice');
    const batch = writeBatch(d);
    batch.update(doc(d, 'groups/g1'), { joinCode: 'CHAI-NEW22' });
    batch.set(doc(d, 'joinCodes/CHAI-NEW22'), { groupId: 'g1' });
    batch.delete(doc(d, 'joinCodes/CHAI-7KQ2M'));
    batch.set(doc(d, 'groups/g1/activity/r'), activity('joinCodeRegenerated', 'm-alice'));
    await assertSucceeds(batch.commit());

    await assertFails(join('bob', 'CHAI-7KQ2M'));
    await assertSucceeds(join('bob', 'CHAI-NEW22'));
  });

  test('only the creator can regenerate, and must delete the old code', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    const d = db('bob');
    const batch = writeBatch(d);
    batch.update(doc(d, 'groups/g1'), { joinCode: 'CHAI-BOB22' });
    batch.set(doc(d, 'joinCodes/CHAI-BOB22'), { groupId: 'g1' });
    batch.delete(doc(d, 'joinCodes/CHAI-7KQ2M'));
    await assertFails(batch.commit());

    const a = db('alice');
    const keepOld = writeBatch(a);
    keepOld.update(doc(a, 'groups/g1'), { joinCode: 'CHAI-NEW22' });
    keepOld.set(doc(a, 'joinCodes/CHAI-NEW22'), { groupId: 'g1' });
    await assertFails(keepOld.commit());
  });
});

describe('placeholders', () => {
  test('members add placeholders; a joiner claims one ("Which one are you?")', async () => {
    await createGroup();
    await assertSucceeds(addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara'));
    await join('sara');
    const d = db('sara');
    const batch = writeBatch(d);
    batch.update(doc(d, 'groups/g1/members/m-sara'), {
      uid: 'sara',
      claimedAt: serverTimestamp(),
      paymentMethods: [],
    });
    batch.set(doc(d, 'groups/g1/activity/c'), activity('placeholderClaimed', 'm-sara'));
    await assertSucceeds(batch.commit());
  });

  test('a claimed member cannot be claimed again or taken over', async () => {
    await createGroup();
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await join('sara');
    await updateDoc(doc(db('sara'), 'groups/g1/members/m-sara'), {
      uid: 'sara',
      claimedAt: serverTimestamp(),
      paymentMethods: [],
    });
    await join('bob');
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-sara'), {
        uid: 'bob',
        claimedAt: serverTimestamp(),
        paymentMethods: [],
      }),
    );
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-sara'), { displayName: 'x' }),
    );
  });

  test('cannot claim a placeholder for someone else', async () => {
    await createGroup();
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await assertFails(
      updateDoc(doc(db('alice'), 'groups/g1/members/m-sara'), {
        uid: 'sara',
        claimedAt: serverTimestamp(),
        paymentMethods: [],
      }),
    );
  });

  test('any member can remove (hide) an unclaimed placeholder', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await assertSucceeds(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-sara'), { active: false }),
    );
  });

  test('cannot remove a real member, or bring a placeholder back as yours', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-alice'), { active: false }),
    );
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-sara'), {
        active: false,
        uid: 'bob',
      }),
    );
  });

  test('non-members cannot add placeholders; members are never deleted', async () => {
    await createGroup();
    await assertFails(addPlaceholder('bob', 'm-alice', 'm-x', 'X'));
    await joinAsNew('bob', 'm-bob'); // deletes are only for a sole member
    await assertFails(deleteDoc(doc(db('alice'), 'groups/g1/members/m-alice')));
  });
});

describe('phone numbers', () => {
  test('you set your own phone; nobody sets yours', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await assertSucceeds(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-bob'), {
        phone: '+923001234567',
      }),
    );
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1/members/m-alice'), {
        phone: '+923001234567',
      }),
    );
  });

  test('placeholders never get a phone', async () => {
    await createGroup();
    const d = db('alice');
    await assertFails(
      setDoc(doc(d, 'groups/g1/members/m-x'), {
        ...member('X'),
        phone: '+923001234567',
      }),
    );
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await assertFails(
      updateDoc(doc(d, 'groups/g1/members/m-sara'), { phone: '+923001234567' }),
    );
  });

  test('claiming a placeholder brings your phone along', async () => {
    await createGroup();
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await join('sara');
    await assertSucceeds(
      updateDoc(doc(db('sara'), 'groups/g1/members/m-sara'), {
        uid: 'sara',
        claimedAt: serverTimestamp(),
        paymentMethods: [],
        phone: '+923001234567',
      }),
    );
  });
});

describe('expenses', () => {
  test('members add, edit and soft-delete', async () => {
    await createGroup();
    const ref = doc(db('alice'), 'groups/g1/expenses/e1');
    await assertSucceeds(setDoc(ref, expense('alice')));
    await assertSucceeds(
      updateDoc(ref, { title: 'Chai & fries', updatedAt: serverTimestamp() }),
    );
    await assertSucceeds(
      updateDoc(ref, { deleted: true, updatedAt: serverTimestamp() }),
    );
  });

  test('never hard-deleted while the group is shared', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    const ref = doc(db('alice'), 'groups/g1/expenses/e1');
    await setDoc(ref, expense('alice'));
    await assertFails(deleteDoc(ref));
  });

  test('non-members cannot read or add', async () => {
    await createGroup();
    await assertFails(setDoc(doc(db('bob'), 'groups/g1/expenses/e1'), expense('bob')));
    await assertFails(getDocs(collection(db('bob'), 'groups/g1/expenses')));
  });

  test('bad data is rejected', async () => {
    await createGroup();
    const ref = doc(db('alice'), 'groups/g1/expenses/e1');
    await assertFails(setDoc(ref, expense('bob'))); // pretending to be bob
    await assertFails(setDoc(ref, expense('alice', { amount: 1000.5 }))); // not paisa
    await assertFails(setDoc(ref, expense('alice', { amount: -100 })));
    await assertFails(setDoc(ref, expense('alice', { title: '' })));
    await assertFails(setDoc(ref, expense('alice', { deleted: true })));
    await assertFails(setDoc(ref, expense('alice', { splitMode: 'committee' })));
    await assertFails(setDoc(ref, expense('alice', { shares: {} })));
    await assertFails(setDoc(ref, expense('alice', { extra: 1 })));
  });

  test('edits cannot rewrite who created it', async () => {
    await createGroup();
    const ref = doc(db('alice'), 'groups/g1/expenses/e1');
    await setDoc(ref, expense('alice'));
    await assertFails(
      updateDoc(ref, { createdBy: 'bob', updatedAt: serverTimestamp() }),
    );
  });
});

describe('settlements', () => {
  beforeEach(async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
  });

  test('"I paid" by the payer, confirmed by the person paid', async () => {
    const ref = doc(db('bob'), 'groups/g1/settlements/s1');
    await assertSucceeds(setDoc(ref, settlement('bob', 'm-bob', 'm-alice')));
    await assertFails(
      updateDoc(ref, { status: 'confirmed', confirmedAt: serverTimestamp() }),
    ); // bob can't confirm his own payment
    await assertSucceeds(
      updateDoc(doc(db('alice'), 'groups/g1/settlements/s1'), {
        status: 'confirmed',
        confirmedAt: serverTimestamp(),
      }),
    );
  });

  test('cannot say someone else paid', async () => {
    await assertFails(
      setDoc(
        doc(db('bob'), 'groups/g1/settlements/s1'),
        settlement('bob', 'm-alice', 'm-bob'),
      ),
    );
  });

  test('only the person paid can record a confirmed payment', async () => {
    await assertSucceeds(
      setDoc(
        doc(db('alice'), 'groups/g1/settlements/s1'),
        settlement('alice', 'm-bob', 'm-alice', 'confirmed'),
      ),
    );
    await assertFails(
      setDoc(
        doc(db('bob'), 'groups/g1/settlements/s2'),
        settlement('bob', 'm-bob', 'm-alice', 'confirmed'),
      ),
    );
  });

  test('payments to a placeholder can be recorded directly', async () => {
    await assertSucceeds(
      setDoc(
        doc(db('bob'), 'groups/g1/settlements/s1'),
        settlement('bob', 'm-bob', 'm-sara', 'confirmed'),
      ),
    );
  });

  test('cannot settle with yourself or a made-up member', async () => {
    const d = db('bob');
    await assertFails(
      setDoc(doc(d, 'groups/g1/settlements/s1'), settlement('bob', 'm-bob', 'm-bob')),
    );
    await assertFails(
      setDoc(doc(d, 'groups/g1/settlements/s2'), settlement('bob', 'm-bob', 'm-ghost')),
    );
  });

  test('creator or person paid can remove; others cannot', async () => {
    await setDoc(
      doc(db('bob'), 'groups/g1/settlements/s1'),
      settlement('bob', 'm-bob', 'm-alice'),
    );
    await joinAsNew('carol', 'm-carol');
    await assertFails(deleteDoc(doc(db('carol'), 'groups/g1/settlements/s1')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'groups/g1/settlements/s1')));
  });
});

describe('activity log', () => {
  test('append-only, and you can only log as yourself', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await assertFails(
      setDoc(doc(db('bob'), 'groups/g1/activity/x'), activity('expenseAdded', 'm-alice')),
    );
    await assertFails(
      updateDoc(doc(db('alice'), 'groups/g1/activity/a1'), { summary: 'edited' }),
    );
    await assertFails(deleteDoc(doc(db('alice'), 'groups/g1/activity/a1')));
  });
});

describe('deleting a group', () => {
  async function deleteAll(uid) {
    const d = db(uid);
    const batch = writeBatch(d);
    for (const sub of ['expenses', 'settlements', 'activity', 'members']) {
      const snap = await getDocs(collection(d, `groups/g1/${sub}`));
      snap.docs.forEach((x) => batch.delete(x.ref));
    }
    await batch.commit();
    const last = writeBatch(d);
    last.delete(doc(d, 'joinCodes/CHAI-7KQ2M'));
    last.delete(doc(d, 'groups/g1'));
    await last.commit();
  }

  test('the last real member can delete it with everything in it', async () => {
    await createGroup();
    await addPlaceholder('alice', 'm-alice', 'm-sara', 'Sara');
    await setDoc(doc(db('alice'), 'groups/g1/expenses/e1'), expense('alice'));
    await assertSucceeds(deleteAll('alice'));
    await assertSucceeds(getDoc(doc(db('alice'), 'joinCodes/CHAI-7KQ2M')));
    const gone = await getDoc(doc(db('alice'), 'joinCodes/CHAI-7KQ2M'));
    if (gone.exists()) throw new Error('join code should be gone');
  });

  test('not while someone else is still in it', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await setDoc(doc(db('alice'), 'groups/g1/expenses/e1'), expense('alice'));
    await assertFails(deleteDoc(doc(db('alice'), 'groups/g1/expenses/e1')));
    await assertFails(deleteDoc(doc(db('alice'), 'groups/g1')));
    await assertFails(deleteDoc(doc(db('bob'), 'groups/g1/activity/a1')));
  });

  test("a non-member can't delete it", async () => {
    await createGroup();
    await assertFails(deleteDoc(doc(db('mallory'), 'groups/g1')));
    await assertFails(deleteDoc(doc(db('mallory'), 'joinCodes/CHAI-7KQ2M')));
  });
});

describe('leaving', () => {
  test('a member leaves themselves and loses access', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    const d = db('bob');
    const batch = writeBatch(d);
    batch.update(doc(d, 'groups/g1/members/m-bob'), { active: false });
    batch.set(doc(d, 'groups/g1/activity/l'), activity('memberLeft', 'm-bob'));
    batch.update(doc(d, 'groups/g1'), { memberUids: arrayRemove('bob') });
    await assertSucceeds(batch.commit());
    await assertFails(getDoc(doc(db('bob'), 'groups/g1')));
  });

  test('cannot remove someone else', async () => {
    await createGroup();
    await joinAsNew('bob', 'm-bob');
    await assertFails(
      updateDoc(doc(db('bob'), 'groups/g1'), { memberUids: arrayRemove('alice') }),
    );
  });
});
