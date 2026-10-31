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
  const testId = `test_capacity_${Date.now()}`;
  const refs = [1, 2, 3].map(n =>
    db.collection('bookings').doc(`${testId}_${n}`)
  );

  const startAt = new Date('2026-11-22T02:00:00Z');

  try {
    const results = await Promise.allSettled(
      refs.map((bookingRef, index) =>
        reserveBookingResources(db, {
          bookingRef,
          bookingData: {
            userId: `${testId}_user${index + 1}`,
            serviceId: 'spa001',
            serviceName: 'Capacity Test',
            price: 0,
            durationMinutes: 75,
          },
          startAt,
          durationMinutes: 75,
          categoryId: 'facial',
        })
      )
    );

    const successful = results
      .filter(result => result.status === 'fulfilled')
      .map(result => result.value);

    const failed = results
      .filter(result => result.status === 'rejected')
      .map(result => result.reason);

    console.log('Successful bookings:', successful.length);
    console.log('Rejected bookings:', failed.length);

    assert.equal(successful.length, 2);
    assert.equal(failed.length, 1);
    assert.equal(failed[0].code, 'SLOT_TAKEN');

    const staffIds = successful.map(item => item.staffId);
    const roomIds = successful.map(item => item.roomId);

    assert.equal(new Set(staffIds).size, 2);
    assert.equal(new Set(roomIds).size, 2);

    for (const booking of successful) {
      assert.equal(booking.status, 'pending');
      assert.equal(booking.resourceSlotIds.length, 10);
    }

    console.log('PASS: Chỉ 2/3 booking được chấp nhận.');
    console.log('PASS: Booking thứ ba bị từ chối khi hết tài nguyên.');
    console.log('PASS: Không trùng nhân viên hoặc phòng.');
  } finally {
    // Chỉ xóa dữ liệu thuộc bài test hiện tại.
    for (const ref of refs) {
      const booking = await ref.get();

      if (!booking.exists ||
          !String(booking.data().userId).startsWith(testId)) {
        continue;
      }

      const slotIds = booking.data().resourceSlotIds || [];
      const slotRefs = slotIds.map(id =>
        db.collection('resource_slots').doc(id)
      );

      await db.runTransaction(async tx => {
        const bookingSnap = await tx.get(ref);
        const slots = await tx.getAll(...slotRefs);

        slots.forEach((slot, index) => {
          if (slot.exists && slot.data().bookingId === ref.id) {
            tx.delete(slotRefs[index]);
          }
        });

        if (bookingSnap.exists &&
            String(bookingSnap.data().userId).startsWith(testId)) {
          tx.delete(ref);
        }
      });
    }

    console.log('CLEANUP: Đã xử lý dữ liệu test.');
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
