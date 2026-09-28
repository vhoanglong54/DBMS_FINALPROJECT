let editingMaHV = null;

function handleLogin() {
    const user = document.getElementById('loginUser').value.trim().toLowerCase();
    const pass = document.getElementById('loginPass').value;

    const accounts = {
        "thanhtam1710": { name: "Thanh Tâm", avatar: "TT" },
        "hoanglong2006": { name: "Hoàng Long", avatar: "HL" },
        "baotran123": { name: "Bảo Trân", avatar: "BT" },
        "thaongan": { name: "Thảo Ngân", avatar: "TN" }
    };

    if (accounts[user] && pass === "1234") {
        const acc = accounts[user];
        document.getElementById('sidebarName').textContent = acc.name;
        document.getElementById('sidebarAvatar').textContent = acc.avatar;
        document.getElementById('loginScreen').classList.add('hidden');
        loadHoiVienData();
        loadDropdownData();
    } else {
        alert('❌ Sai tên đăng nhập hoặc mật khẩu! (Mật khẩu mặc định là: 1234)');
    }
}

function switchTab(tabId, element) {
    document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.menu-item').forEach(el => el.classList.remove('active'));
    
    document.getElementById(tabId).classList.add('active');
    element.classList.add('active');

    const titles = {
        'tabHoiVien': 'Quản Lý Thông Tin Hội Viên',
        'tabDangKy': 'Đăng Ký Gói Tập & Thanh Toán (Transaction)',
        'tabGoiTap': 'Các Gói Tập & Ưu Đãi Hệ Thống',
        'tabBaoCao': 'Báo Cáo Hội Viên Sắp Hết Hạn (View)'
    };
    document.getElementById('pageTitle').textContent = titles[tabId];

    if (tabId === 'tabHoiVien') loadHoiVienData();
    if (tabId === 'tabDangKy') loadDropdownData();
    if (tabId === 'tabGoiTap') loadGoiTapData();
    if (tabId === 'tabBaoCao') loadViewData();
}

function openModal(modalId) { document.getElementById(modalId).classList.add('active'); }
function closeModal(modalId) { document.getElementById(modalId).classList.remove('active'); }

function validateData(ngaySinh, chieuCao, canNang) {
    if (ngaySinh) {
        const birthDate = new Date(ngaySinh);
        const today = new Date();
        let age = today.getFullYear() - birthDate.getFullYear();
        const m = today.getMonth() - birthDate.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) age--;
        if (age < 10 || age > 100) { alert('❌ Thông tin không hợp lệ!'); return false; }
    }
    if (chieuCao !== "" && (Number(chieuCao) < 50 || Number(chieuCao) > 250)) { alert('❌ Thông tin không hợp lệ!'); return false; }
    if (canNang !== "" && (Number(canNang) < 20 || Number(canNang) > 300)) { alert('❌ Thông tin không hợp lệ!'); return false; }
    return true;
}

function xemChiTietHoiVien(maHV, hoTen) {
    document.getElementById('cardChiTietHV').style.display = 'block';
    document.getElementById('tieuDeChiTietHV').textContent = `Chi tiết Gói tập & Ưu đãi hội viên: ${hoTen} (Mã: HV${String(maHV).padStart(4, '0')})`;

    fetch(`/api/hoivien/chitiet/${maHV}`)
        .then(res => res.json())
        .then(res => {
            const tbody = document.getElementById('tableGoiChiTietHVBody');
            tbody.innerHTML = '';
            
            if (res.success && res.danh_sach_goi && res.danh_sach_goi.length > 0) {
                res.danh_sach_goi.forEach(g => {
                    let badgeStyle = g.SoNgayConLai >= 0 ? 'badge-success' : 'badge-warning';
                    let textTrangThai = g.SoNgayConLai >= 0 ? `Còn lại ${g.SoNgayConLai} ngày` : `Đã quá hạn ${Math.abs(g.SoNgayConLai)} ngày`;

                    tbody.innerHTML += `
                        <tr>
                            <td><b>PM-${g.MaDK}</b></td>
                            <td><b>${g.TenGoi}</b></td>
                            <td><span class="badge badge-vip">${g.UuDai || 'Không'}</span></td>
                            <td>${g.NgayDangKy}</td>
                            <td><b>${g.NgayKetThuc}</b></td>
                            <td><span class="badge ${badgeStyle}">${textTrangThai}</span></td>
                        </tr>
                    `;
                });
            } else {
                tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Hội viên chưa đăng ký gói tập nào.</td></tr>`;
            }
        }).catch(err => console.log("Lỗi tải chi tiết:", err));
}

function dongChiTietHV() {
    document.getElementById('cardChiTietHV').style.display = 'none';
}

function loadHoiVienData() {
    fetch('/api/hoivien')
        .then(res => res.json())
        .then(data => {
            const tbody = document.getElementById('tableHoiVienBody');
            tbody.innerHTML = '';
            
            if (!data || data.length === 0) {
                tbody.innerHTML = `<tr><td colspan="8" style="text-align: center;">Chưa có dữ liệu hội viên.</td></tr>`;
                return;
            }

            data.forEach(r => {
                let badgeClass = 'badge-success';
                if (r.HangHoiVien === 'VIP Gold' || r.HangHoiVien === 'Diamond') badgeClass = 'badge-vip';

                let thehinh = (r.ChieuCao && r.CanNang) ? `${r.ChieuCao} cm / ${r.CanNang} kg` : 'N/A cm / N/A kg';
                let thoigiantap = r.ThoiGianTap || 'N/A';
                let hanghv = r.HangHoiVien || 'Standard';
                let hienThiMa = `HV${String(r.MaHV).padStart(4, '0')}`;

                tbody.innerHTML += `
                    <tr>
                        <td><b>${hienThiMa}</b></td>
                        <td>${r.HoTen}</td>
                        <td>${r.SoDienThoai}</td>
                        <td>${r.Email || ''}</td>
                        <td>${thehinh}</td>
                        <td>${thoigiantap}</td>
                        <td><span class="badge ${badgeClass}">${hanghv}</span></td>
                        <td>
                            <div style="display: flex; gap: 6px;">
                                <button class="btn btn-outline" style="height: 28px; font-size: 11px;" onclick="openEditModal(${r.MaHV}, '${r.HoTen || ''}', '${r.SoDienThoai || ''}', '${r.Email || ''}', '${r.ChieuCao || ''}', '${r.CanNang || ''}', '${r.ThoiGianTap || 'Linh hoạt'}')">Sửa / Xóa</button>
                                <button class="btn btn-outline" style="height: 28px; font-size: 11px; background-color: #f0fdfa; color: var(--primary-hover); border-color: var(--primary-border);" onclick="xemChiTietHoiVien(${r.MaHV}, '${r.HoTen}')">🔍 Chi tiết</button>
                            </div>
                        </td>
                    </tr>
                `;
            });
        }).catch(err => console.log("Lỗi tải dữ liệu:", err));
}

function loadGoiTapData() {
    fetch('/api/goitap')
        .then(res => res.json())
        .then(data => {
            const tbody = document.getElementById('tableGoiTapBody');
            tbody.innerHTML = '';
            data.forEach(r => {
                tbody.innerHTML += `
                    <tr>
                        <td><b>PL-${r.MaGoi}</b></td>
                        <td><b>${r.TenGoi}</b></td>
                        <td>${r.ThoiHan} tháng</td>
                        <td>${Number(r.GiaGoi).toLocaleString('vi-VN')} đ</td>
                        <td><span class="badge badge-success">${r.UuDai || 'Không có ưu đãi'}</span></td>
                    </tr>
                `;
            });
        }).catch(err => console.log("Lỗi tải gói tập:", err));
}

function loadDropdownData() {
    fetch('/api/dropdown-data')
        .then(res => res.json())
        .then(data => {
            const selHV = document.getElementById('txMaHV');
            selHV.innerHTML = '';
            if (data.hoi_vien && data.hoi_vien.length > 0) {
                data.hoi_vien.forEach(hv => {
                    selHV.innerHTML += `<option value="${hv.MaHV}">[HV${String(hv.MaHV).padStart(4, '0')}] ${hv.HoTen}</option>`;
                });
            }

            const selGoi = document.getElementById('txMaGoi');
            selGoi.innerHTML = '';
            if (data.goi_tap && data.goi_tap.length > 0) {
                data.goi_tap.forEach(g => {
                    selGoi.innerHTML += `<option value="${g.MaGoi}">[PL-${g.MaGoi}] ${g.TenGoi}</option>`;
                });
            }

            const selNV = document.getElementById('txMaNV');
            selNV.innerHTML = '';
            if (data.nhan_vien && data.nhan_vien.length > 0) {
                data.nhan_vien.forEach(nv => {
                    selNV.innerHTML += `<option value="${nv.MaNV}">[NV-${nv.MaNV}] ${nv.HoTen}</option>`;
                });
            }
        }).catch(err => console.log("Lỗi tải dropdown:", err));
}

function addHoiVien() {
    const hoten = document.getElementById('inputHoTen').value.trim();
    const sdt = document.getElementById('inputSdt').value.trim();
    const ngaysinh = document.getElementById('inputNgaySinh').value;
    const chieucao = document.getElementById('inputChieuCao').value;
    const cannang = document.getElementById('inputCanNang').value;

    if (!hoten || !sdt) { alert('Vui lòng nhập đầy đủ Họ tên và Số điện thoại!'); return; }
    if (!validateData(ngaysinh, chieucao, cannang)) return;

    const payload = {
        HoTen: hoten,
        SoDienThoai: sdt,
        Email: document.getElementById('inputEmail').value,
        NgaySinh: ngaysinh,
        GioiTinh: document.getElementById('inputGioiTinh').value,
        ChieuCao: chieucao,
        CanNang: cannang,
        ThoiGianTap: document.getElementById('inputThoiGianTap').value,
        HangHoiVien: document.getElementById('inputHangHV').value
    };

    fetch('/api/hoivien', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) {
            alert("✅ Thêm hội viên thành công!");
            closeModal('modalThemHV');
            loadHoiVienData();
        } else {
            alert("❌ " + res.error);
        }
    });
}

function addGoiTap() {
    const tengoi = document.getElementById('inputTenGoi').value.trim();
    const thoihan = document.getElementById('inputThoiHan').value;
    const giagoi = document.getElementById('inputGiaGoi').value;
    const uudai = document.getElementById('inputUuDai').value;

    if (!tengoi || !giagoi) { alert('Vui lòng nhập tên gói và giá tiền!'); return; }

    const payload = { TenGoi: tengoi, ThoiHan: thoihan, GiaGoi: giagoi, UuDai: uudai || 'Không có' };

    fetch('/api/goitap', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) {
            alert("✅ Thêm gói ưu đãi thành công!");
            closeModal('modalThemGoi');
            loadGoiTapData();
        } else {
            alert("❌ " + res.error);
        }
    });
}

function openEditModal(maHV, hoten, sdt, email, chieucao, cannang, thoigiantap) {
    editingMaHV = maHV;
    document.getElementById('editHoTen').value = hoten;
    document.getElementById('editSdt').value = sdt;
    document.getElementById('editEmail').value = email;
    document.getElementById('editChieuCao').value = chieucao;
    document.getElementById('editCanNang').value = cannang;
    document.getElementById('editThoiGianTap').value = thoigiantap;
    openModal('modalSuaHV');
}

function updateHoiVien() {
    const chieucao = document.getElementById('editChieuCao').value;
    const cannang = document.getElementById('editCanNang').value;
    if (!validateData(null, chieucao, cannang)) return;

    const payload = {
        MaHV: editingMaHV,
        HoTen: document.getElementById('editHoTen').value,
        SoDienThoai: document.getElementById('editSdt').value,
        Email: document.getElementById('editEmail').value,
        ChieuCao: chieucao,
        CanNang: cannang,
        ThoiGianTap: document.getElementById('editThoiGianTap').value
    };

    fetch('/api/hoivien/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) {
            alert("✅ Cập nhật thông tin thành công!");
            closeModal('modalSuaHV');
            loadHoiVienData();
        } else {
            alert("❌ " + res.error);
        }
    });
}

function deleteHoiVien() {
    if (!confirm("Bạn có chắc chắn muốn xóa hội viên này không?")) return;

    fetch('/api/hoivien/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ MaHV: editingMaHV })
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) {
            alert("✅ Đã xóa hội viên thành công!");
            closeModal('modalSuaHV');
            loadHoiVienData();
        } else {
            alert("❌ " + res.error);
        }
    });
}

function submitTransaction() {
    const payload = {
        MaHV: document.getElementById('txMaHV').value,
        MaGoi: document.getElementById('txMaGoi').value,
        MaNV: document.getElementById('txMaNV').value,
        NgayBatDau: new Date().toISOString().split('T')[0],
        PhuongThucTT: document.getElementById('txPTTT').value
    };

    fetch('/api/dangky', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) alert("✅ " + res.message);
        else alert("❌ Lỗi Transaction: " + res.error);
    });
}

function loadViewData() {
    fetch('/api/view-saphethan')
        .then(res => res.json())
        .then(data => {
            const tbody = document.getElementById('tableBaoCaoBody');
            tbody.innerHTML = '';
            if (!data || data.length === 0) {
                tbody.innerHTML = `<tr><td colspan="6" style="text-align: center;">Không có hội viên nào sắp hết hạn.</td></tr>`;
                return;
            }
            data.forEach(r => {
                tbody.innerHTML += `
                    <tr>
                        <td><b>HV${String(r.MaHV).padStart(4, '0')}</b></td>
                        <td>${r.HoTen}</td>
                        <td>${r.SoDienThoai}</td>
                        <td>${r.TenGoi}</td>
                        <td>${r.NgayKetThuc}</td>
                        <td><b>${r.SoNgayConLai} ngày</b></td>
                    </tr>
                `;
            });
        });
}