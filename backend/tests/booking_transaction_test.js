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
  const bookingRef = db.collection('bookings').doc('test_no_resources');

  try {
    await reserveBookingResources(db, {
      bookingRef,
      bookingData: {
        userId: 'test-user',
        serviceId: 'test-service',
      },
      startAt: new Date('2026-11-01T02:00:00Z'),
      durationMinutes: 75,
      categoryId: 'nonexistent_test_category',
    });

    throw new Error('FAIL: Booking không được phép tạo.');
  } catch (error) {
    assert.equal(error.code, 'NO_RESOURCES');
    console.log('PASS: Từ chối booking khi không có tài nguyên phù hợp.');
  }

  const booking = await bookingRef.get();
  assert.equal(booking.exists, false);
  console.log('PASS: Không tạo booking ngoài ý muốn.');
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
