let editingMaHV = null;

document.addEventListener("DOMContentLoaded", () => {
    loadHoiVienData();
});

function switchTab(tabId, element) {
    document.querySelectorAll('.tab-pane').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.menu-item').forEach(el => el.classList.remove('active'));
    
    document.getElementById(tabId).classList.add('active');
    element.classList.add('active');

    const titles = {
        'tabHoiVien': 'Quản Lý Thông Tin Hội Viên',
        'tabDangKy': 'Đăng Ký Gói Tập & Thanh Toán (Transaction)',
        'tabBaoCao': 'Báo Cáo Hội Viên Sắp Hết Hạn (View SQL)'
    };
    document.getElementById('pageTitle').textContent = titles[tabId];

    if (tabId === 'tabHoiVien') loadHoiVienData();
    if (tabId === 'tabDangKy') loadDropdownData();
    if (tabId === 'tabBaoCao') loadViewData();
}

function openModal(modalId) { document.getElementById(modalId).classList.add('active'); }
function closeModal(modalId) { document.getElementById(modalId).classList.remove('active'); }

function loadHoiVienData() {
    fetch('/api/hoivien')
        .then(res => res.json())
        .then(data => {
            const tbody = document.getElementById('tableHoiVienBody');
            tbody.innerHTML = '';
            
            if (!data || data.length === 0) {
                tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: var(--text-muted);">Chưa có dữ liệu hội viên.</td></tr>`;
                return;
            }

            data.forEach(r => {
                let hienThiMa = `HV${String(r.MaHV).padStart(4, '0')}`;
                tbody.innerHTML += `
                    <tr>
                        <td><b>${hienThiMa}</b></td>
                        <td>${r.HoTen}</td>
                        <td>${r.SoDienThoai}</td>
                        <td>${r.Email || ''}</td>
                        <td>
                            <button class="btn btn-danger" style="height: 28px; font-size: 11px;" onclick="deleteHoiVien(${r.MaHV})">Xóa</button>
                        </td>
                    </tr>
                `;
            });
        }).catch(err => console.log("Lỗi tải dữ liệu hội viên:", err));
}

function addHoiVien() {
    const hoten = document.getElementById('inputHoTen').value.trim();
    const sdt = document.getElementById('inputSdt').value.trim();
    const ngaysinh = document.getElementById('inputNgaySinh').value;
    const gioitinh = document.getElementById('inputGioiTinh').value;
    const email = document.getElementById('inputEmail').value.trim();

    if (!hoten || !sdt) {
        alert('Vui lòng nhập đầy đủ Họ tên và Số điện thoại!');
        return;
    }

    const payload = { HoTen: hoten, SoDienThoai: sdt, NgaySinh: ngaysinh, GioiTinh: gioitinh, Email: email };

    fetch('/api/hoivien', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) {
            alert("Thêm hội viên thành công!");
            closeModal('modalThemHV');
            loadHoiVienData();
        } else {
            alert("Lỗi: " + res.error);
        }
    });
}

function deleteHoiVien(maHV) {
    if (!confirm("Bạn có chắc chắn muốn xóa hội viên này không?")) return;

    fetch('/api/hoivien/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ MaHV: maHV })
    })
    .then(res => res.json())
    .then(res => {
        if(res.success) {
            alert("Đã xóa hội viên thành công!");
            loadHoiVienData();
        } else {
            alert("Lỗi khi xóa: " + res.error);
        }
    });
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
                    selGoi.innerHTML += `<option value="${g.MaGoi}">[${g.HienThiMa}] ${g.TenGoi}</option>`;
                });
            }

            const selNV = document.getElementById('txMaNV');
            selNV.innerHTML = '';
            if (data.nhan_vien && data.nhan_vien.length > 0) {
                data.nhan_vien.forEach(nv => {
                    selNV.innerHTML += `<option value="${nv.MaNV}">[${nv.HienThiMa}] ${nv.HoTen}</option>`;
                });
            }
        }).catch(err => console.log("Lỗi tải dropdown dữ liệu:", err));
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
        if(res.success) {
            alert(res.message);
        } else {
            alert("Lỗi Transaction: " + res.error);
        }
    });
}

function loadViewData() {
    fetch('/api/view-saphethan')
        .then(res => res.json())
        .then(data => {
            const tbody = document.getElementById('tableBaoCaoBody');
            tbody.innerHTML = '';
            if (!data || data.length === 0) {
                tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-muted);">Không có hội viên nào sắp hết hạn.</td></tr>`;
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
                        <td><b style="color: #ea580c;">${r.SoNgayConLai} ngày</b></td>
                    </tr>
                `;
            });
        }).catch(err => console.log("Lỗi tải báo cáo View:", err));
}