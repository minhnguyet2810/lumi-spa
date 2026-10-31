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
  const testId = `test_concurrent_${Date.now()}`;
  const refs = [1, 2].map(n =>
    db.collection('bookings').doc(`${testId}_${n}`)
  );
  const startAt = new Date('2026-11-21T02:00:00Z');
  const created = [];

  try {
    const results = await Promise.allSettled(refs.map((bookingRef, i) =>
      reserveBookingResources(db, {
        bookingRef,
        bookingData: {
          userId: `${testId}_user${i + 1}`,
          serviceId: 'spa001',
          serviceName: 'Concurrency Test',
          price: 0,
          durationMinutes: 75,
        },
        startAt,
        durationMinutes: 75,
        categoryId: 'facial',
      })
    ));

    for (let i = 0; i < results.length; i++) {
      if (results[i].status === 'fulfilled') {
        created.push(results[i].value);
      } else {
        console.error(`Booking ${i + 1} failed:`, results[i].reason);
      }
    }

    assert.equal(created.length, 2, 'Cả hai booking phải thành công.');

    const [a, b] = created;
    assert.notEqual(a.staffId, b.staffId, 'Không được trùng nhân viên.');
    assert.notEqual(a.roomId, b.roomId, 'Không được trùng phòng.');

    for (const result of created) {
      assert.equal(result.status, 'pending');
      assert.equal(result.resourceSlotIds.length, 10);
    }

    console.log('PASS: Hai booking đồng thời thành công.');
    console.log('Booking 1:', a.staffId, a.roomId);
    console.log('Booking 2:', b.staffId, b.roomId);
    console.log('PASS: Không trùng nhân viên hoặc phòng.');
  } finally {
    // Tìm và xóa đúng các booking do bài test tạo ra,
    // kể cả khi Promise.allSettled trả về lỗi.
    for (const ref of refs) {
      const booking = await ref.get();
      if (!booking.exists ||
          !String(booking.data().userId).startsWith(testId)) {
        continue;
      }

      const slotIds = booking.data().resourceSlotIds || [];
      await db.runTransaction(async tx => {
        const bookingSnap = await tx.get(ref);
        const slotRefs = slotIds.map(id =>
          db.collection('resource_slots').doc(id)
        );
        const slots = await tx.getAll(...slotRefs);

        slots.forEach((slot, i) => {
          if (slot.exists && slot.data().bookingId === ref.id) {
            tx.delete(slotRefs[i]);
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
