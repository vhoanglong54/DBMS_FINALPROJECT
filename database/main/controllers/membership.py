from flask import Blueprint, request, jsonify
from database import get_db_connection
import time

membership_bp = Blueprint('membership', __name__)

# Hàm mapping chuẩn hóa dữ liệu Enum
def map_gender(g): return 'MALE' if g == 'Nam' else 'FEMALE' if g == 'Nữ' else 'OTHER'
def map_payment(p): return 'CASH' if p == 'Tiền mặt' else 'CARD' if p == 'Thẻ' else 'BANK_TRANSFER'

@membership_bp.route('/api/hoivien', methods=['GET', 'POST'])
def handle_hoi_vien():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if request.method == 'POST':
        req = request.json
        member_code = f"HV{int(time.time())}" # Tự động tạo mã HV
        try:
            cursor.execute(
                """INSERT INTO dbo.HoiVien (MemberCode, FullName, DateOfBirth, Gender, Phone, Email) 
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (member_code, req.get('HoTen'), req.get('NgaySinh'), map_gender(req.get('GioiTinh')), req.get('SoDienThoai'), req.get('Email'))
            )
            conn.commit()
            return jsonify({"success": True})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 400
        finally:
            cursor.close()
            conn.close()

    cursor.execute("SELECT MemberId, MemberCode, FullName, DateOfBirth, Gender, Phone, Email FROM dbo.HoiVien WHERE IsActive=1")
    rows = cursor.fetchall()
    
    data = []
    for r in rows:
        data.append({
            "MaHV": r.MemberId,
            "HienThiMa": r.MemberCode,
            "HoTen": r.FullName,
            "NgaySinh": str(r.DateOfBirth),
            "SoDienThoai": r.Phone,
            "Email": getattr(r, 'Email', ''),
            "ChieuCao": "N/A", "CanNang": "N/A", "ThoiGianTap": "N/A", "HangHoiVien": "Standard" # UI cần nhưng DB bỏ
        })
    cursor.close()
    conn.close()
    return jsonify(data)

@membership_bp.route('/api/hoivien/update', methods=['POST'])
def update_hoi_vien():
    req = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            """UPDATE dbo.HoiVien SET FullName=?, Phone=?, Email=? WHERE MemberId=?""",
            (req.get('HoTen'), req.get('SoDienThoai'), req.get('Email'), req.get('MaHV'))
        )
        conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400

@membership_bp.route('/api/hoivien/delete', methods=['POST'])
def delete_hoi_vien():
    req = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE dbo.HoiVien SET IsActive=0 WHERE MemberId = ?", (req.get('MaHV'),)) # Soft delete
        conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400

@membership_bp.route('/api/goitap', methods=['GET', 'POST'])
def handle_goi_tap():
    conn = get_db_connection()
    cursor = conn.cursor()

    if request.method == 'POST':
        req = request.json
        plan_code = f"PL{int(time.time())}"
        duration_days = int(req.get('ThoiHan')) * 30 # Quy đổi tháng ra ngày
        try:
            cursor.execute(
                """INSERT INTO dbo.GoiTap (PlanCode, PlanName, DurationDays, Price, Description) VALUES (?, ?, ?, ?, ?)""",
                (plan_code, req.get('TenGoi'), duration_days, req.get('GiaGoi'), req.get('UuDai'))
            )
            conn.commit()
            return jsonify({"success": True})
        except Exception as e:
            return jsonify({"success": False, "error": str(e)}), 400

    cursor.execute("SELECT PlanId, PlanName, DurationDays, Price, Description FROM dbo.GoiTap WHERE IsActive=1")
    data = [{"MaGoi": r.PlanId, "TenGoi": r.PlanName, "ThoiHan": r.DurationDays // 30, "GiaGoi": r.Price, "UuDai": r.Description} for r in cursor.fetchall()]
    cursor.close()
    conn.close()
    return jsonify(data)

@membership_bp.route('/api/dropdown-data', methods=['GET'])
def get_dropdown_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT MemberId, MemberCode, FullName FROM dbo.HoiVien WHERE IsActive=1")
        hoi_vien = [{"MaHV": r.MemberId, "HienThiMa": r.MemberCode, "HoTen": r.FullName} for r in cursor.fetchall()]
        
        cursor.execute("SELECT PlanId, PlanCode, PlanName FROM dbo.GoiTap WHERE IsActive=1")
        goi_tap = [{"MaGoi": r.PlanId, "HienThiMa": r.PlanCode, "TenGoi": r.PlanName} for r in cursor.fetchall()]
        
        cursor.execute("SELECT EmployeeId, EmployeeCode, FullName FROM dbo.NhanVien WHERE IsActive=1")
        nhan_vien = [{"MaNV": r.EmployeeId, "HienThiMa": r.EmployeeCode, "HoTen": r.FullName} for r in cursor.fetchall()]
        
        return jsonify({"hoi_vien": hoi_vien, "goi_tap": goi_tap, "nhan_vien": nhan_vien})
    except:
        return jsonify({"hoi_vien": [], "goi_tap": [], "nhan_vien": []})

@membership_bp.route('/api/dangky', methods=['POST'])
def dang_ky_goi():
    req = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("{CALL dbo.sp_DangKyGoiTapMoi (?, ?, ?, ?, ?)}", 
                       (req.get('MaHV'), req.get('MaGoi'), req.get('MaNV'), req.get('NgayBatDau'), map_payment(req.get('PhuongThucTT'))))
        conn.commit()
        return jsonify({"success": True, "message": "Đăng ký gói tập thành công!"})
    except Exception as e:
        error_msg = str(e).split(']')[len(str(e).split(']'))-1].strip()
        return jsonify({"success": False, "error": error_msg}), 400

@membership_bp.route('/api/dangky/huy', methods=['POST'])
def huy_dang_ky():
    req = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("{CALL dbo.sp_HuyGoiTap (?)}", (req.get('MaDK'),))
        conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400

@membership_bp.route('/api/view-saphethan', methods=['GET'])
def view_sap_het_han():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM dbo.vw_HoiVienSapHetHan")
        data = [{"MaHV": r.MaHV, "HoTen": r.HoTen, "SoDienThoai": r.SoDienThoai, "TenGoi": r.TenGoi, "NgayKetThuc": str(r.NgayKetThuc), "SoNgayConLai": r.SoNgayConLai} for r in cursor.fetchall()]
        return jsonify(data)
    except:
        return jsonify([])

@membership_bp.route('/api/hoivien/chitiet/<int:ma_hv>', methods=['GET'])
def get_chi_tiet_hoi_vien(ma_hv):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT MemberId, FullName FROM dbo.HoiVien WHERE MemberId = ?", (ma_hv,))
        hv = cursor.fetchone()
        if not hv: return jsonify({"success": False, "error": "Không tìm thấy!"}), 404

        cursor.execute("""
            SELECT dk.MembershipId, gt.PlanName, gt.Description, gt.Price, dk.StartDate, dk.EndDate, dk.Status,
                   DATEDIFF(day, GETDATE(), dk.EndDate) AS SoNgayConLai
            FROM dbo.DangKyGoi dk 
            JOIN dbo.GoiTap gt ON dk.PlanId = gt.PlanId 
            WHERE dk.MemberId = ?
            ORDER BY dk.MembershipId DESC
        """, (ma_hv,))
        
        danh_sach_goi = [{"MaDK": r.MembershipId, "TenGoi": r.PlanName, "UuDai": r.Description, "NgayDangKy": str(r.StartDate), "NgayKetThuc": str(r.EndDate), "TrangThai": 'Đã hủy' if r.Status == 'CANCELLED' else r.Status, "SoNgayConLai": r.SoNgayConLai} for r in cursor.fetchall()]
        return jsonify({"success": True, "hoi_vien": {"MaHV": hv.MemberId, "HoTen": hv.FullName}, "danh_sach_goi": danh_sach_goi})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400