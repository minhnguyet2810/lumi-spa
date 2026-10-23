const SLOT_MINUTES = 15;
const SLOT_MS = SLOT_MINUTES * 60 * 1000;

function getSlotTimes(startAt, durationMinutes) {
  if (
    !(startAt instanceof Date) ||
    !Number.isFinite(startAt.getTime()) ||
    !Number.isInteger(durationMinutes) ||
    durationMinutes <= 0 ||
    startAt.getTime() % SLOT_MS !== 0
  ) {
    throw new Error('Invalid booking time or duration.');
  }

  const endMs = startAt.getTime() + durationMinutes * 60 * 1000;
  const slots = [];

  for (let time = startAt.getTime(); time < endMs; time += SLOT_MS) {
    slots.push(new Date(time).toISOString());
  }

  return slots;
}

function supportsCategory(resource, categoryId) {
  return resource.isActive === true &&
    Array.isArray(resource.categories) &&
    resource.categories.includes(categoryId);
}

module.exports = {
  SLOT_MINUTES,
  getSlotTimes,
  supportsCategory,
};

function findEligibleResources(staffDocs, roomDocs, categoryId) {
  const staff = staffDocs
    .filter(item => supportsCategory(item.data, categoryId))
    .sort((a, b) => a.id.localeCompare(b.id));

  const rooms = roomDocs
    .filter(item => supportsCategory(item.data, categoryId))
    .sort((a, b) => a.id.localeCompare(b.id));

  return { staff, rooms };
}

module.exports.findEligibleResources = findEligibleResources;

function getResourceSlotIds(resourceType, resourceId, slotTimes) {
  if (!['staff', 'room'].includes(resourceType) ||
      !/^[A-Za-z0-9_-]+$/.test(resourceId) ||
      !Array.isArray(slotTimes)) {
    throw new Error('Invalid resource slot arguments.');
  }

  return slotTimes.map(time => {
    const timestamp = new Date(time);
    if (!Number.isFinite(timestamp.getTime())) {
      throw new Error('Invalid slot timestamp.');
    }
    return `${resourceType}_${resourceId}_${timestamp.toISOString().replace(/[-:.]/g, '')}`;
  });
}

module.exports.getResourceSlotIds = getResourceSlotIds;
