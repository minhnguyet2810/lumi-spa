const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  CONVERSION_RATE,
  TIERS,
  getTierByPoints,
  calculateMembershipDetails,
  awardPointsInTransaction,
} = require('../services/membership_service');

test('Conversion rate is strictly 1000 VNĐ = 1 điểm', () => {
  assert.equal(CONVERSION_RATE, 1000);
  assert.equal(Math.floor(0 / CONVERSION_RATE), 0);
  assert.equal(Math.floor(999 / CONVERSION_RATE), 0);
  assert.equal(Math.floor(1000 / CONVERSION_RATE), 1);
  assert.equal(Math.floor(390000 / CONVERSION_RATE), 390);
  assert.equal(Math.floor(1250000 / CONVERSION_RATE), 1250);
});

test('Tiers classification by points boundary', () => {
  // Member: 0 - 999
  assert.equal(getTierByPoints(0).name, 'Member');
  assert.equal(getTierByPoints(500).name, 'Member');
  assert.equal(getTierByPoints(999).name, 'Member');

  // Silver: 1000 - 4999
  assert.equal(getTierByPoints(1000).name, 'Silver');
  assert.equal(getTierByPoints(1000).discountPercent, 5);
  assert.equal(getTierByPoints(2500).name, 'Silver');
  assert.equal(getTierByPoints(4999).name, 'Silver');

  // Gold: 5000 - 14999
  assert.equal(getTierByPoints(5000).name, 'Gold');
  assert.equal(getTierByPoints(5000).discountPercent, 10);
  assert.equal(getTierByPoints(10000).name, 'Gold');
  assert.equal(getTierByPoints(14999).name, 'Gold');

  // Diamond: >= 15000
  assert.equal(getTierByPoints(15000).name, 'Diamond');
  assert.equal(getTierByPoints(15000).discountPercent, 15);
  assert.equal(getTierByPoints(50000).name, 'Diamond');
});

test('calculateMembershipDetails produces accurate progression and nextTier metrics', () => {
  // New user with 0 points
  const initial = calculateMembershipDetails(0, 0);
  assert.equal(initial.tier, 'Member');
  assert.equal(initial.tierLabel, 'Thành viên');
  assert.equal(initial.nextTier, 'Silver');
  assert.equal(initial.pointsToNextTier, 1000);
  assert.equal(initial.spentToNextTier, 1000000);
  assert.equal(initial.progress, 0);
  assert.equal(initial.conversionRate, 1000);
  assert.equal(initial.allTiers.length, 4);

  // User with 500 points (50% progress to Silver)
  const halfway = calculateMembershipDetails(500, 500000);
  assert.equal(halfway.tier, 'Member');
  assert.equal(halfway.nextTier, 'Silver');
  assert.equal(halfway.pointsToNextTier, 500);
  assert.equal(halfway.spentToNextTier, 500000);
  assert.equal(halfway.progress, 0.5);

  // User with 3000 points (halfway through Silver to Gold: 3000-1000 / 4000 = 0.5)
  const silver = calculateMembershipDetails(3000, 3000000);
  assert.equal(silver.tier, 'Silver');
  assert.equal(silver.discountPercent, 5);
  assert.equal(silver.nextTier, 'Gold');
  assert.equal(silver.pointsToNextTier, 2000);
  assert.equal(silver.progress, 0.5);

  // Diamond user (highest tier reached)
  const diamond = calculateMembershipDetails(20000, 20000000);
  assert.equal(diamond.tier, 'Diamond');
  assert.equal(diamond.discountPercent, 15);
  assert.equal(diamond.nextTier, null);
  assert.equal(diamond.pointsToNextTier, 0);
  assert.equal(diamond.progress, 1.0);
});

test('awardPointsInTransaction awards points and updates tier correctly in Firestore transaction', async () => {
  const store = new Map();
  const dbMock = {
    collection: (name) => ({
      doc: (id) => ({
        path: `${name}/${id}`,
      }),
    }),
  };

  const txMock = {
    get: async (ref) => ({
      exists: store.has(ref.path),
      data: () => store.get(ref.path),
    }),
    create: (ref, data) => store.set(ref.path, data),
    update: (ref, data) => {
      const old = store.get(ref.path) || {};
      store.set(ref.path, { ...old, ...data });
    },
  };

  // Customer spends 2,500,000 VNĐ -> 2,500 points -> Silver tier
  const result = await awardPointsInTransaction(txMock, dbMock, {
    userId: 'user_123',
    amount: 2500000,
    sourceId: 'ord_1',
    sourceType: 'order',
  });

  assert.equal(result.pointsAwarded, 2500);
  assert.equal(result.newPoints, 2500);
  assert.equal(result.newSpent, 2500000);
  assert.equal(result.newTier, 'Silver');
  assert.equal(result.upgraded, true);

  const saved = store.get('memberships/user_123');
  assert.ok(saved);
  assert.equal(saved.points, 2500);
  assert.equal(saved.totalSpent, 2500000);
  assert.equal(saved.tier, 'Silver');

  // Customer spends another 3,000,000 VNĐ -> 3,000 more points -> Total 5,500 -> Gold tier
  const result2 = await awardPointsInTransaction(txMock, dbMock, {
    userId: 'user_123',
    amount: 3000000,
    sourceId: 'ord_2',
    sourceType: 'order',
  });

  assert.equal(result2.pointsAwarded, 3000);
  assert.equal(result2.newPoints, 5500);
  assert.equal(result2.newSpent, 5500000);
  assert.equal(result2.newTier, 'Gold');
  assert.equal(result2.upgraded, true);

  const updatedSaved = store.get('memberships/user_123');
  assert.equal(updatedSaved.points, 5500);
  assert.equal(updatedSaved.totalSpent, 5500000);
  assert.equal(updatedSaved.tier, 'Gold');
});
