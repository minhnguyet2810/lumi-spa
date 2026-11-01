const { Timestamp, FieldValue } = require('firebase-admin/firestore');
const {
  getSlotTimes,
  getResourceSlotIds,
  findEligibleResources,
} = require('./booking_resources');

async function reserveBookingResources(db, options) {
  const {
    bookingRef,
    bookingData,
    startAt,
    durationMinutes,
    categoryId,
  } = options;

  const slotTimes = getSlotTimes(startAt, durationMinutes);

  const [staffSnapshot, roomSnapshot] = await Promise.all([
    db.collection('staff').get(),
    db.collection('rooms').get(),
  ]);

  const { staff, rooms } = findEligibleResources(
    staffSnapshot.docs.map(doc => ({ id: doc.id, data: doc.data() })),
    roomSnapshot.docs.map(doc => ({ id: doc.id, data: doc.data() })),
    categoryId
  );

  if (!staff.length || !rooms.length) {
    const error = new Error('Không có nhân viên hoặc phòng phù hợp.');
    error.code = 'NO_RESOURCES';
    throw error;
  }

  const candidates = [];

  for (const employee of staff) {
    for (const room of rooms) {
      const staffSlotIds = getResourceSlotIds(
        'staff', employee.id, slotTimes
      );

      const roomSlotIds = getResourceSlotIds(
        'room', room.id, slotTimes
      );

      candidates.push({
        staffId: employee.id,
        roomId: room.id,
        slotIds: [...staffSlotIds, ...roomSlotIds],
      });
    }
  }

  const allSlotIds = [
    ...new Set(candidates.flatMap(candidate => candidate.slotIds)),
  ];

  const slotRefs = allSlotIds.map(id =>
    db.collection('resource_slots').doc(id)
  );

  return db.runTransaction(async tx => {
    // Đọc lại trạng thái tài nguyên trong cùng transaction.
    const resourceRefs = [
      ...staff.map(item => db.collection('staff').doc(item.id)),
      ...rooms.map(item => db.collection('rooms').doc(item.id)),
    ];

    // Hoàn thành tất cả thao tác đọc trước khi ghi.
    const [snapshots, resourceSnapshots] = await Promise.all([
      tx.getAll(...slotRefs),
      tx.getAll(...resourceRefs),
    ]);

    const eligibleStaff = new Set();
    const eligibleRooms = new Set();

    resourceSnapshots.forEach((snapshot, index) => {
      if (!snapshot.exists) return;
      const data = snapshot.data();
      if (data.isActive !== true ||
          !Array.isArray(data.categories) ||
          !data.categories.includes(categoryId)) return;

      if (index < staff.length) eligibleStaff.add(snapshot.id);
      else eligibleRooms.add(snapshot.id);
    });

    const occupied = new Set();

    snapshots.forEach((snapshot, index) => {
      if (snapshot.exists) {
        occupied.add(allSlotIds[index]);
      }
    });

    const selected = candidates.find(candidate =>
      eligibleStaff.has(candidate.staffId) &&
      eligibleRooms.has(candidate.roomId) &&
      candidate.slotIds.every(id => !occupied.has(id))
    );

    if (!selected) {
      const error = new Error(
        'Không còn nhân viên và phòng trống trong khung giờ này.'
      );
      error.code = 'SLOT_TAKEN';
      throw error;
    }

    const slotData = {
      bookingId: bookingRef.id,
      staffId: selected.staffId,
      roomId: selected.roomId,
      status: 'held',
      createdAt: FieldValue.serverTimestamp(),
    };

    for (const slotId of selected.slotIds) {
      tx.create(
        db.collection('resource_slots').doc(slotId),
        slotData
      );
    }

    tx.create(bookingRef, {
      ...bookingData,
      staffId: selected.staffId,
      roomId: selected.roomId,
      resourceSlotIds: selected.slotIds,
      startAt: Timestamp.fromDate(startAt),
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });

    return {
      bookingId: bookingRef.id,
      staffId: selected.staffId,
      roomId: selected.roomId,
      resourceSlotIds: selected.slotIds,
      status: 'pending',
    };
  });
}

module.exports = { reserveBookingResources };
