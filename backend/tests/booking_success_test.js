// Safety: integration tests must use a local Firestore Emulator.
{
  const host = process.env.FIRESTORE_EMULATOR_HOST || '';
  if (!/^(localhost|127\.0\.0\.1|\[::1\]):[0-9]+$/.test(host)) {
    throw new Error(
      'STOP: Test chỉ được chạy với FIRESTORE_EMULATOR_HOST trỏ tới localhost:port.'
    );
  }
}

const assert = require('node:assert/strict');
const db = require('../firebase');
const { reserveBookingResources } = require('../booking_transactions');

async function main() {
  const bookingRef = db.collection('bookings').doc(
    `test_booking_${Date.now()}`
  );

  let result;

  try {
    result = await reserveBookingResources(db, {
      bookingRef,
      bookingData: {
        userId: 'test-user',
        serviceId: 'spa001',
        serviceName: 'Test Booking',
        price: 0,
        durationMinutes: 75,
      },
      startAt: new Date('2026-11-20T02:00:00Z'),
      durationMinutes: 75,
      categoryId: 'facial',
    });

    assert.equal(result.status, 'pending');
    assert.equal(result.resourceSlotIds.length, 10);

    const booking = await bookingRef.get();
    assert.equal(booking.exists, true);
    assert.equal(booking.data().status, 'pending');

    console.log('PASS: Booking pending được tạo.');
    console.log('Staff:', result.staffId);
    console.log('Room:', result.roomId);
    console.log('Resource locks:', result.resourceSlotIds.length);
  } finally {
    // Chỉ dọn dẹp dữ liệu do bài test này tạo ra.
    if (result) {
      await db.runTransaction(async tx => {
        const refs = result.resourceSlotIds.map(id =>
          db.collection('resource_slots').doc(id)
        );
        const snapshots = await tx.getAll(...refs);
        const booking = await tx.get(bookingRef);

        snapshots.forEach((snapshot, index) => {
          if (snapshot.exists &&
              snapshot.data().bookingId === bookingRef.id) {
            tx.delete(refs[index]);
          }
        });

        if (booking.exists &&
            booking.data().userId === 'test-user') {
          tx.delete(bookingRef);
        }
      });

      console.log('CLEANUP: Đã xóa dữ liệu test.');
    }
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
