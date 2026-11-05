const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const db = require('../firebase');
const { requireAuth } = require('../auth');

const router = express.Router();

router.use(requireAuth);

// GET /api/me
router.get('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const doc = await db.collection('users').doc(uid).get();

    if (!doc.exists) {
      const defaultData = {
        uid,
        email: req.user.email || '',
        displayName: req.user.name || req.user.displayName || (req.user.email ? req.user.email.split('@')[0] : 'Khách hàng LUMI'),
        name: req.user.name || req.user.displayName || (req.user.email ? req.user.email.split('@')[0] : 'Khách hàng LUMI'),
        phone: req.user.phone_number || '',
        phoneNumber: req.user.phone_number || '',
        role: 'customer',
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      if (db.hasCredentials) {
        try {
          await db.collection('users').doc(uid).set(defaultData, { merge: true });
        } catch (_) {}
      }
      return res.json({
        success: true,
        data: defaultData,
      });
    }

    const userData = doc.data() || {};
    return res.json({
      success: true,
      data: {
        uid,
        displayName: userData.displayName || userData.name || req.user.name || '',
        phone: userData.phone || userData.phoneNumber || '',
        email: userData.email || req.user.email || '',
        ...userData,
      },
    });
  } catch (error) {
    console.error('Profile GET error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải hồ sơ.',
    });
  }
});

// PATCH /api/me
router.patch('/', async (req, res) => {
  try {
    const uid = req.user.uid;
    const {
      displayName,
      name,
      phone,
      phoneNumber,
      address,
      gender,
      birthday,
      photoUrl,
      avatarUrl,
    } = req.body || {};
    const updates = {};

    const resolvedName = displayName !== undefined ? displayName : name;
    if (resolvedName !== undefined) {
      if (
        typeof resolvedName !== 'string' ||
        !resolvedName.trim() ||
        resolvedName.trim().length > 100
      ) {
        return res.status(400).json({
          success: false,
          message: 'Tên không hợp lệ.',
        });
      }
      updates.displayName = resolvedName.trim();
      updates.name = resolvedName.trim();
    }

    const resolvedPhone = phone !== undefined ? phone : phoneNumber;
    if (resolvedPhone !== undefined) {
      if (
        typeof resolvedPhone !== 'string' ||
        !/^[0-9+().\s-]{8,20}$/.test(resolvedPhone.trim())
      ) {
        return res.status(400).json({
          success: false,
          message: 'Số điện thoại không hợp lệ.',
        });
      }
      updates.phone = resolvedPhone.trim();
      updates.phoneNumber = resolvedPhone.trim();
    }

    if (address !== undefined && typeof address === 'string') {
      updates.address = address.trim();
    }

    if (gender !== undefined && typeof gender === 'string') {
      updates.gender = gender.trim();
    }

    if (birthday !== undefined && typeof birthday === 'string') {
      updates.birthday = birthday.trim();
    }

    const resolvedPhoto = photoUrl !== undefined ? photoUrl : avatarUrl;
    if (resolvedPhoto !== undefined && typeof resolvedPhoto === 'string') {
      updates.photoUrl = resolvedPhoto.trim();
      updates.avatarUrl = resolvedPhoto.trim();
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Không có thông tin cần cập nhật.',
      });
    }

    const ref = db.collection('users').doc(uid);
    const existing = await ref.get();

    updates.updatedAt = FieldValue.serverTimestamp();

    if (!existing.exists) {
      updates.uid = uid;
      updates.email = req.user.email || '';
      updates.role = 'customer';
      updates.createdAt = FieldValue.serverTimestamp();
      await ref.set(updates, { merge: true });
    } else {
      await ref.update(updates);
    }

    // Đồng bộ sang Firebase Auth nếu có thể
    if (updates.displayName) {
      try {
        const { getAuth } = require('firebase-admin/auth');
        await getAuth().updateUser(uid, { displayName: updates.displayName });
      } catch (_) {}
    }

    return res.json({
      success: true,
      message: 'Cập nhật hồ sơ thành công.',
      data: updates,
    });
  } catch (error) {
    console.error('Profile PATCH error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật hồ sơ.',
    });
  }
});

// Helper serialize address doc
function serializeAddress(doc) {
  const data = doc.data() || {};
  return {
    id: doc.id,
    recipientName: data.recipientName || '',
    phone: data.phone || '',
    province: data.province || '',
    district: data.district || '',
    ward: data.ward || '',
    street: data.street || '',
    fullAddress: data.fullAddress || '',
    label: data.label || 'Nhà riêng',
    isDefault: data.isDefault === true,
    createdAt: data.createdAt?.toDate?.().toISOString() || data.createdAt || null,
    updatedAt: data.updatedAt?.toDate?.().toISOString() || data.updatedAt || null,
  };
}

// GET /api/me/addresses - Lấy danh sách địa chỉ nhận hàng
router.get('/addresses', async (req, res) => {
  try {
    const snap = await db.collection('addresses')
      .where('userId', '==', req.user.uid)
      .get();

    const addresses = snap.docs.map(serializeAddress);

    addresses.sort((a, b) => {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return (b.createdAt || '').localeCompare(a.createdAt || '');
    });

    return res.json({
      success: true,
      count: addresses.length,
      data: addresses,
    });
  } catch (error) {
    console.error('Addresses GET error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể tải danh sách địa chỉ.',
    });
  }
});

// POST /api/me/addresses - Thêm địa chỉ nhận hàng mới
router.post('/addresses', async (req, res) => {
  try {
    const {
      recipientName,
      phone,
      province = '',
      district = '',
      ward = '',
      street = '',
      fullAddress = '',
      label = 'Nhà riêng',
      isDefault = false,
    } = req.body || {};

    if (!recipientName || typeof recipientName !== 'string' || !recipientName.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Họ và tên người nhận không được để trống.',
      });
    }

    if (!phone || typeof phone !== 'string' || !/^[0-9+().\s-]{8,20}$/.test(phone.trim())) {
      return res.status(400).json({
        success: false,
        message: 'Số điện thoại không hợp lệ.',
      });
    }

    if (!street || typeof street !== 'string' || !street.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Địa chỉ cụ thể không được để trống.',
      });
    }

    const calculatedFullAddress = (fullAddress && fullAddress.trim())
      ? fullAddress.trim()
      : [street.trim(), ward.trim(), district.trim(), province.trim()].filter(Boolean).join(', ');

    const existingSnap = await db.collection('addresses')
      .where('userId', '==', req.user.uid)
      .get();

    const shouldBeDefault = isDefault === true || existingSnap.empty;

    if (shouldBeDefault && !existingSnap.empty) {
      for (const doc of existingSnap.docs) {
        if (doc.data().isDefault) {
          await doc.ref.update({ isDefault: false });
        }
      }
    }

    const docRef = db.collection('addresses').doc();
    const addressData = {
      userId: req.user.uid,
      recipientName: recipientName.trim(),
      phone: phone.trim(),
      province: (province || '').trim(),
      district: (district || '').trim(),
      ward: (ward || '').trim(),
      street: street.trim(),
      fullAddress: calculatedFullAddress,
      label: ['Nhà riêng', 'Văn phòng', 'Khác'].includes(label) ? label : 'Nhà riêng',
      isDefault: shouldBeDefault,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await docRef.set(addressData);

    return res.status(201).json({
      success: true,
      message: 'Thêm địa chỉ thành công.',
      data: {
        id: docRef.id,
        ...addressData,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    console.error('Addresses POST error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể thêm địa chỉ.',
    });
  }
});

// PUT /api/me/addresses/:id - Cập nhật địa chỉ nhận hàng
router.put('/addresses/:id', async (req, res) => {
  try {
    const docRef = db.collection('addresses').doc(req.params.id);
    const existing = await docRef.get();

    if (!existing.exists || existing.data().userId !== req.user.uid) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy địa chỉ cần sửa.',
      });
    }

    const {
      recipientName,
      phone,
      province,
      district,
      ward,
      street,
      fullAddress,
      label,
      isDefault,
    } = req.body || {};

    const updates = {};
    if (recipientName !== undefined) {
      if (typeof recipientName !== 'string' || !recipientName.trim()) {
        return res.status(400).json({ success: false, message: 'Họ và tên không hợp lệ.' });
      }
      updates.recipientName = recipientName.trim();
    }
    if (phone !== undefined) {
      if (typeof phone !== 'string' || !/^[0-9+().\s-]{8,20}$/.test(phone.trim())) {
        return res.status(400).json({ success: false, message: 'Số điện thoại không hợp lệ.' });
      }
      updates.phone = phone.trim();
    }
    if (province !== undefined) updates.province = String(province || '').trim();
    if (district !== undefined) updates.district = String(district || '').trim();
    if (ward !== undefined) updates.ward = String(ward || '').trim();
    if (street !== undefined) {
      if (typeof street !== 'string' || !street.trim()) {
        return res.status(400).json({ success: false, message: 'Địa chỉ cụ thể không hợp lệ.' });
      }
      updates.street = street.trim();
    }
    if (label !== undefined) {
      updates.label = ['Nhà riêng', 'Văn phòng', 'Khác'].includes(label) ? label : 'Nhà riêng';
    }

    const current = existing.data();
    const finalStreet = updates.street !== undefined ? updates.street : current.street;
    const finalWard = updates.ward !== undefined ? updates.ward : current.ward;
    const finalDistrict = updates.district !== undefined ? updates.district : current.district;
    const finalProvince = updates.province !== undefined ? updates.province : current.province;

    if (fullAddress !== undefined && typeof fullAddress === 'string' && fullAddress.trim()) {
      updates.fullAddress = fullAddress.trim();
    } else {
      updates.fullAddress = [finalStreet, finalWard, finalDistrict, finalProvince].filter(Boolean).join(', ');
    }

    if (isDefault === true) {
      const allUserAddresses = await db.collection('addresses')
        .where('userId', '==', req.user.uid)
        .get();
      for (const d of allUserAddresses.docs) {
        if (d.id !== req.params.id && d.data().isDefault) {
          await d.ref.update({ isDefault: false });
        }
      }
      updates.isDefault = true;
    } else if (isDefault === false && current.isDefault) {
      // Don't unset default if it's the only address
      const allUserAddresses = await db.collection('addresses')
        .where('userId', '==', req.user.uid)
        .get();
      if (allUserAddresses.size > 1) {
        updates.isDefault = false;
        // set another as default
        const other = allUserAddresses.docs.find(d => d.id !== req.params.id);
        if (other) {
          await other.ref.update({ isDefault: true });
        }
      }
    }

    updates.updatedAt = FieldValue.serverTimestamp();
    await docRef.update(updates);

    return res.json({
      success: true,
      message: 'Cập nhật địa chỉ thành công.',
    });
  } catch (error) {
    console.error('Addresses PUT error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể cập nhật địa chỉ.',
    });
  }
});

// PATCH /api/me/addresses/:id/default - Đặt làm địa chỉ mặc định
router.patch('/addresses/:id/default', async (req, res) => {
  try {
    const docRef = db.collection('addresses').doc(req.params.id);
    const existing = await docRef.get();

    if (!existing.exists || existing.data().userId !== req.user.uid) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy địa chỉ.',
      });
    }

    const allUserAddresses = await db.collection('addresses')
      .where('userId', '==', req.user.uid)
      .get();

    for (const d of allUserAddresses.docs) {
      if (d.id !== req.params.id && d.data().isDefault) {
        await d.ref.update({ isDefault: false });
      }
    }

    await docRef.update({
      isDefault: true,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return res.json({
      success: true,
      message: 'Đã đặt làm địa chỉ mặc định.',
    });
  } catch (error) {
    console.error('Addresses default error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể đặt địa chỉ mặc định.',
    });
  }
});

// DELETE /api/me/addresses/:id - Xóa địa chỉ nhận hàng
router.delete('/addresses/:id', async (req, res) => {
  try {
    const docRef = db.collection('addresses').doc(req.params.id);
    const existing = await docRef.get();

    if (!existing.exists || existing.data().userId !== req.user.uid) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy địa chỉ cần xóa.',
      });
    }

    const wasDefault = existing.data().isDefault;
    await docRef.delete();

    if (wasDefault) {
      const remaining = await db.collection('addresses')
        .where('userId', '==', req.user.uid)
        .limit(1)
        .get();

      if (!remaining.empty) {
        await remaining.docs[0].ref.update({
          isDefault: true,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
    }

    return res.json({
      success: true,
      message: 'Đã xóa địa chỉ thành công.',
    });
  } catch (error) {
    console.error('Addresses DELETE error:', error);
    return res.status(500).json({
      success: false,
      message: 'Không thể xóa địa chỉ.',
    });
  }
});

module.exports = router;
