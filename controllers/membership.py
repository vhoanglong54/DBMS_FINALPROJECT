from flask import Blueprint, request, jsonify
from database import get_db_connection
import time

membership_bp = Blueprint('membership', __name__)

def map_gender(g): return 'MALE' if g == 'Nam' else 'FEMALE' if g == 'Nữ' else 'OTHER'
def map_payment(p): return 'CASH' if p == 'Tiền mặt' else 'CARD' if p == 'Thẻ' else 'BANK_TRANSFER'

@membership_bp.route('/api/hoivien', methods=['GET', 'POST'])
def handle_hoi_vien():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    if request.method == 'POST':
        req = request.json
        member_code = f"HV{int(time.time())}"
        try:
            cursor.execute(
                """INSERT INTO dbo.HoiVien (MemberCode, FullName, DateOfBirth, Gender, Phone, Email) 
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (member_code, req.get('HoTen'), req.get('NgaySinh'), map_gender(req.get('GioiTinh')), 
                 req.get('SoDienThoai'), req.get('Email'))
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
            "Email": getattr(r, 'Email', '')
        })
    cursor.close()
    conn.close()
    return jsonify(data)

@membership_bp.route('/api/hoivien/delete', methods=['POST'])
def delete_hoi_vien():
    req = request.json
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM dbo.HoiVien WHERE MemberId = ?", (req.get('MaHV'),))
        conn.commit()
        return jsonify({"success": True})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 400
    finally:
        cursor.close()
        conn.close()

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
        # Gọi Stored Procedure Transaction đăng ký gói tập
        cursor.execute("{CALL dbo.sp_DangKyGoiTapMoi (?, ?, ?, ?, ?)}", 
                       (req.get('MaHV'), req.get('MaGoi'), req.get('MaNV'), req.get('NgayBatDau'), map_payment(req.get('PhuongThucTT'))))
        conn.commit()
        return jsonify({"success": True, "message": "Đăng ký gói tập và thanh toán thành công!"})
    except Exception as e:
        error_msg = str(e).split(']')[len(str(e).split(']'))-1].strip()
        return jsonify({"success": False, "error": error_msg}), 400

@membership_bp.route('/api/view-saphethan', methods=['GET'])
def view_sap_het_han():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Truy vấn trực tiếp từ View SQL đã tạo
        cursor.execute("SELECT * FROM dbo.vw_HoiVienSapHetHan")
        data = [{"MaHV": r.MaHV, "HoTen": r.HoTen, "SoDienThoai": r.SoDienThoai, "TenGoi": r.TenGoi, "NgayKetThuc": str(r.NgayKetThuc), "SoNgayConLai": r.SoNgayConLai} for r in cursor.fetchall()]
        return jsonify(data)
    except:
        return jsonify([])