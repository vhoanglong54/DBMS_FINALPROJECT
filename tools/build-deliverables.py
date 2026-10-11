"""Generate the academic Word report for the Gym Management DBMS project.

The document is generated from repository facts so that the report and the
submitted implementation do not drift apart. Microsoft Word updates the TOC
fields after generation during the verification step on Windows.
"""

from pathlib import Path
from textwrap import dedent

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables"
ASSETS = OUT / "assets"
REPORT = OUT / "HeThongQuanLyPhongGym_Report.docx"
OUT.mkdir(exist_ok=True)
ASSETS.mkdir(exist_ok=True)

BLACK = RGBColor(0, 0, 0)
GRAY = "D9D9D9"
LIGHT_GRAY = "F2F2F2"


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def shade_cell(cell, color):
    tc_pr = cell._tc.get_or_add_tcPr()
    shading = tc_pr.find(qn("w:shd"))
    if shading is None:
        shading = OxmlElement("w:shd")
        tc_pr.append(shading)
    shading.set(qn("w:fill"), color)


def set_cell_text(cell, value, bold=False, size=9.5, align=WD_ALIGN_PARAGRAPH.LEFT):
    cell.text = str(value)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    for paragraph in cell.paragraphs:
        paragraph.alignment = align
        paragraph.paragraph_format.first_line_indent = Cm(0)
        paragraph.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
        paragraph.paragraph_format.space_after = Pt(0)
        paragraph.paragraph_format.space_before = Pt(0)
        for run in paragraph.runs:
            run.font.name = "Times New Roman"
            run._element.get_or_add_rPr().rFonts.set(qn("w:eastAsia"), "Times New Roman")
            run.font.size = Pt(size)
            run.font.bold = bold
            run.font.color.rgb = BLACK


def add_table(document, caption, headers, rows, widths=None, font_size=9.5):
    paragraph = document.add_paragraph(caption, style="Table Caption")
    paragraph.paragraph_format.keep_with_next = True
    table = document.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False if widths else True
    set_repeat_table_header(table.rows[0])
    for index, header in enumerate(headers):
        cell = table.rows[0].cells[index]
        set_cell_text(cell, header, bold=True, size=font_size, align=WD_ALIGN_PARAGRAPH.CENTER)
        shade_cell(cell, GRAY)
    for row_index, row in enumerate(rows):
        cells = table.add_row().cells
        for index, value in enumerate(row):
            set_cell_text(cells[index], value, size=font_size)
            if row_index % 2 == 1:
                shade_cell(cells[index], LIGHT_GRAY)
    if widths:
        for row in table.rows:
            for index, width in enumerate(widths):
                row.cells[index].width = Cm(width)
    document.add_paragraph("").paragraph_format.space_after = Pt(0)
    return table


def add_field(paragraph, instruction, placeholder=""):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instruction_text = OxmlElement("w:instrText")
    instruction_text.set(qn("xml:space"), "preserve")
    instruction_text.text = instruction
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    result = OxmlElement("w:t")
    result.text = placeholder
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, instruction_text, separate, result, end])


def add_page_number(section):
    footer = section.footer
    footer.is_linked_to_previous = False
    paragraph = footer.paragraphs[0]
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    add_field(paragraph, "PAGE")
    for run in paragraph.runs:
        run.font.name = "Times New Roman"
        run.font.size = Pt(12)
        run.font.color.rgb = BLACK


def add_heading(document, text, level=1):
    paragraph = document.add_paragraph(text, style=f"Heading {level}")
    paragraph.paragraph_format.keep_with_next = True
    return paragraph


def add_body(document, text):
    paragraph = document.add_paragraph()
    paragraph.add_run(text)
    return paragraph


def add_code(document, code):
    paragraph = document.add_paragraph(style="Source Code")
    paragraph.add_run(dedent(code).strip())
    return paragraph


def add_picture(document, file_name, caption, width=15.5):
    path = ASSETS / file_name
    if not path.exists():
        raise FileNotFoundError(f"Missing report image: {path}")
    paragraph = document.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.first_line_indent = Cm(0)
    paragraph.add_run().add_picture(str(path), width=Cm(width))
    document.add_paragraph(caption, style="Figure Caption")


def add_chapter(document, number, title):
    document.add_page_break()
    add_heading(document, f"CHƯƠNG {number}. {title}", 1)


def read_source(relative_path):
    return (ROOT / relative_path).read_text(encoding="utf-8-sig")


def extract_object(relative_path, marker, max_lines=90):
    lines = read_source(relative_path).splitlines()
    start = next(index for index, line in enumerate(lines) if marker.lower() in line.lower())
    selected = []
    for line in lines[start:]:
        if selected and line.strip().upper() == "GO":
            break
        selected.append(line)
        if len(selected) >= max_lines:
            selected.append("-- Trích đoạn dừng tại đây; mã đầy đủ nằm trong tệp nguồn.")
            break
    return "\n".join(selected)


TABLES = [
    ("VaiTro", "Danh mục vai trò nghiệp vụ dùng chung giữa cơ chế xác thực ứng dụng và phân quyền.", [
        ("RoleId", "smallint IDENTITY", "Không", "PK", "Khóa thay thế của vai trò."),
        ("RoleCode", "varchar(30)", "Không", "UNIQUE; CHECK chữ hoa và dấu gạch dưới", "Mã ADMIN, RECEPTIONIST, TRAINER hoặc ACCOUNTANT."),
        ("RoleName", "nvarchar(100)", "Không", "UNIQUE", "Tên hiển thị của vai trò."),
        ("Description", "nvarchar(500)", "Có", "", "Mô tả phạm vi trách nhiệm."),
        ("IsActive", "bit", "Không; mặc định 1", "", "Trạng thái sử dụng."),
        ("CreatedAt", "datetime2(0)", "Không; SYSUTCDATETIME", "", "Thời điểm tạo theo UTC."),
    ]),
    ("NguoiDung", "Tài khoản đăng nhập, thông tin khóa tạm và vật liệu băm mật khẩu.", [
        ("UserId", "int IDENTITY", "Không", "PK", "Khóa tài khoản."),
        ("RoleId", "smallint", "Không", "FK → VaiTro", "Vai trò nghiệp vụ được gán."),
        ("Username", "varchar(50)", "Không", "UNIQUE; CHECK độ dài/ký tự", "Tên đăng nhập chuẩn hóa."),
        ("PasswordHash", "varbinary(64)", "Không", "", "Giá trị băm PBKDF2, không lưu mật khẩu rõ."),
        ("PasswordSalt", "varbinary(32)", "Không", "", "Salt riêng của tài khoản."),
        ("PasswordIterations", "int", "Không; 100000", "CHECK 100000–1000000", "Số vòng lặp PBKDF2."),
        ("MustChangePassword", "bit", "Không; 1", "", "Buộc đổi mật khẩu khởi tạo."),
        ("FailedLoginCount", "tinyint", "Không; 0", "CHECK 0–20", "Số lần đăng nhập sai liên tiếp."),
        ("LockedUntil", "datetime2(0)", "Có", "", "Thời điểm kết thúc khóa tạm."),
        ("LastLoginAt", "datetime2(0)", "Có", "", "Lần đăng nhập thành công gần nhất."),
        ("IsActive", "bit", "Không; 1", "", "Trạng thái tài khoản."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc tạo và cập nhật."),
        ("RowVersion", "rowversion", "Không", "", "Phát hiện cập nhật đồng thời."),
    ]),
    ("NhanVien", "Hồ sơ nhân viên và liên kết tùy chọn với tài khoản hệ thống.", [
        ("EmployeeId", "int IDENTITY", "Không", "PK", "Khóa nhân viên."),
        ("UserId", "int", "Có", "FK → NguoiDung; UNIQUE có lọc", "Tài khoản của nhân viên nếu được cấp."),
        ("EmployeeCode", "varchar(20)", "Không", "UNIQUE; CHECK", "Mã nhân viên."),
        ("FullName", "nvarchar(120)", "Không", "", "Họ tên đầy đủ."),
        ("DateOfBirth", "date", "Có", "", "Ngày sinh."),
        ("Gender", "varchar(10)", "Có", "CHECK miền giá trị", "Giới tính chuẩn hóa."),
        ("Phone", "varchar(15)", "Không", "CHECK 9–15 ký tự số/+", "Số điện thoại."),
        ("Email", "varchar(254)", "Có", "", "Địa chỉ thư điện tử."),
        ("Address", "nvarchar(300)", "Có", "", "Địa chỉ liên hệ."),
        ("HireDate", "date", "Không", "", "Ngày bắt đầu làm việc."),
        ("EmployeeType", "varchar(20)", "Không", "CHECK MANAGER/RECEPTIONIST/TRAINER/ACCOUNTANT", "Loại nhân viên nghiệp vụ."),
        ("IsActive", "bit", "Không; 1", "", "Khóa mềm hồ sơ."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("HoiVien", "Hồ sơ hội viên, thông tin liên hệ, y tế và chỉ số thể trạng.", [
        ("MemberId", "int IDENTITY", "Không", "PK", "Khóa hội viên."),
        ("MemberCode", "varchar(20)", "Không", "UNIQUE; CHECK", "Mã hội viên sinh theo sequence."),
        ("FullName", "nvarchar(120)", "Không", "", "Họ tên hội viên."),
        ("DateOfBirth", "date", "Không", "CHECK từ 01/01/1900", "Ngày sinh."),
        ("Gender", "varchar(10)", "Có", "CHECK miền giá trị", "Giới tính."),
        ("Phone", "varchar(15)", "Không", "CHECK 9–15 ký tự số/+", "Số điện thoại."),
        ("Email", "varchar(254)", "Có", "UNIQUE có lọc", "Email, duy nhất nếu được khai báo."),
        ("Address", "nvarchar(300)", "Có", "", "Địa chỉ."),
        ("EmergencyContact", "nvarchar(150)", "Có", "", "Liên hệ khẩn cấp."),
        ("MedicalNote", "nvarchar(1000)", "Có", "", "Lưu ý sức khỏe phục vụ tập luyện."),
        ("JoinedAt", "date", "Không; ngày hiện tại", "DEFAULT", "Ngày gia nhập."),
        ("ChieuCao", "int", "Có", "CHECK 50–250", "Chiều cao theo centimet."),
        ("CanNang", "int", "Có", "CHECK 20–300", "Cân nặng theo kilogram."),
        ("ThoiGianTap", "nvarchar(50)", "Có", "", "Khung giờ tập mong muốn."),
        ("IsActive", "bit", "Không; 1", "", "Khóa mềm hội viên."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("GoiTap", "Danh mục gói thành viên và quyền lợi sử dụng.", [
        ("PlanId", "int IDENTITY", "Không", "PK", "Khóa gói tập."),
        ("PlanCode", "varchar(20)", "Không", "UNIQUE", "Mã gói."),
        ("PlanName", "nvarchar(120)", "Không", "", "Tên thương mại."),
        ("Description", "nvarchar(500)", "Có", "", "Mô tả quyền lợi."),
        ("DurationDays", "smallint", "Không", "CHECK 1–1095", "Thời hạn theo ngày."),
        ("Price", "decimal(18,2)", "Không", "CHECK ≥ 0", "Giá hiện hành."),
        ("MaxCheckInsPerDay", "tinyint", "Không; 1", "CHECK 1–10", "Giới hạn lượt vào trong ngày."),
        ("AllowsClasses", "bit", "Không; 1", "", "Có quyền tham gia lớp hay không."),
        ("IsActive", "bit", "Không; 1", "", "Trạng thái kinh doanh."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("DangKyGoi", "Giao dịch mua gói và khoảng hiệu lực của quyền thành viên.", [
        ("MembershipId", "bigint IDENTITY", "Không", "PK", "Khóa đăng ký."),
        ("MemberId", "int", "Không", "FK → HoiVien", "Hội viên mua gói."),
        ("PlanId", "int", "Không", "FK → GoiTap", "Gói được mua."),
        ("SoldByEmployeeId", "int", "Không", "FK → NhanVien", "Nhân viên bán."),
        ("StartDate; EndDate", "date", "Không", "CHECK EndDate ≥ StartDate", "Khoảng hiệu lực."),
        ("PriceAtPurchase", "decimal(18,2)", "Không", "CHECK ≥ 0", "Giá chụp tại thời điểm bán."),
        ("Status", "varchar(20)", "Không; PENDING", "CHECK 5 trạng thái", "Trạng thái vòng đời đăng ký."),
        ("CancellationReason", "nvarchar(500)", "Có", "Bắt buộc khi CANCELLED", "Lý do hủy."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("HoaDon", "Chứng từ công nợ phát sinh từ đăng ký gói.", [
        ("InvoiceId", "bigint IDENTITY", "Không", "PK", "Khóa hóa đơn."),
        ("InvoiceCode", "varchar(30)", "Không", "UNIQUE", "Mã hóa đơn sinh theo sequence."),
        ("MembershipId", "bigint", "Không", "FK → DangKyGoi", "Đăng ký tạo công nợ."),
        ("CreatedByEmployeeId", "int", "Không", "FK → NhanVien", "Người lập hóa đơn."),
        ("IssuedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm phát hành."),
        ("TotalAmount; PaidAmount", "decimal(18,2)", "Không; 0", "CHECK 0 ≤ Paid ≤ Total", "Tổng phải thu và đã thu."),
        ("Status", "varchar(20)", "Không; PENDING", "CHECK PENDING/PARTIAL/PAID/CANCELLED", "Trạng thái công nợ."),
        ("Note", "nvarchar(500)", "Có", "", "Ghi chú nghiệp vụ."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("CTHoaDon", "Các dòng cấu thành tổng giá trị hóa đơn.", [
        ("InvoiceDetailId", "bigint IDENTITY", "Không", "PK", "Khóa dòng hóa đơn."),
        ("InvoiceId", "bigint", "Không", "FK → HoaDon", "Hóa đơn cha."),
        ("ItemType", "varchar(30)", "Không", "CHECK 5 loại", "Loại hàng hóa/dịch vụ."),
        ("Description", "nvarchar(250)", "Không", "", "Diễn giải dòng."),
        ("Quantity", "smallint", "Không; 1", "CHECK > 0", "Số lượng."),
        ("UnitPrice", "decimal(18,2)", "Không", "CHECK ≥ 0", "Đơn giá."),
        ("DiscountAmount", "decimal(18,2)", "Không; 0", "CHECK hợp lệ", "Giảm giá của dòng."),
        ("LineTotal", "decimal(18,2)", "Tính toán", "PERSISTED", "Quantity × UnitPrice − DiscountAmount."),
        ("CreatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm tạo."),
    ]),
    ("ThanhToan", "Các lần thu tiền cho một hóa đơn.", [
        ("PaymentId", "bigint IDENTITY", "Không", "PK", "Khóa thanh toán."),
        ("PaymentCode", "varchar(30)", "Không", "UNIQUE", "Mã phiếu thu."),
        ("InvoiceId", "bigint", "Không", "FK → HoaDon", "Hóa đơn được thanh toán."),
        ("ReceivedByEmployeeId", "int", "Không", "FK → NhanVien", "Nhân viên nhận tiền."),
        ("Amount", "decimal(18,2)", "Không", "CHECK > 0", "Số tiền của lần thu."),
        ("PaymentMethod", "varchar(20)", "Không", "CHECK 4 phương thức", "Tiền mặt, chuyển khoản, thẻ hoặc ví điện tử."),
        ("Status", "varchar(20)", "Không; COMPLETED", "CHECK 4 trạng thái", "Trạng thái giao dịch."),
        ("TransactionReference", "varchar(100)", "Có", "", "Mã đối soát ngoài hệ thống."),
        ("PaidAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm thu."),
        ("Note", "nvarchar(500)", "Có", "", "Ghi chú."),
        ("CreatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm tạo bản ghi."),
    ]),
    ("PhongTap", "Tài nguyên phòng dùng để xếp lịch lớp.", [
        ("RoomId", "int IDENTITY", "Không", "PK", "Khóa phòng."),
        ("RoomCode", "varchar(20)", "Không", "UNIQUE", "Mã phòng."),
        ("RoomName", "nvarchar(100)", "Không", "", "Tên phòng."),
        ("Capacity", "smallint", "Không", "CHECK 1–500", "Sức chứa vật lý."),
        ("Location", "nvarchar(200)", "Có", "", "Vị trí trong cơ sở."),
        ("IsActive", "bit", "Không; 1", "", "Trạng thái khai thác."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("LopTap", "Danh mục loại lớp và đặc điểm mặc định.", [
        ("ClassId", "int IDENTITY", "Không", "PK", "Khóa loại lớp."),
        ("ClassCode", "varchar(20)", "Không", "UNIQUE", "Mã loại lớp."),
        ("ClassName", "nvarchar(120)", "Không", "", "Tên lớp."),
        ("Description", "nvarchar(500)", "Có", "", "Nội dung tập luyện."),
        ("DefaultDurationMinutes", "smallint", "Không", "CHECK 15–240", "Thời lượng mặc định."),
        ("DifficultyLevel", "varchar(20)", "Không; ALL_LEVELS", "CHECK 4 mức", "Độ khó."),
        ("IsActive", "bit", "Không; 1", "", "Trạng thái danh mục."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("LichLop", "Buổi lớp cụ thể gắn loại lớp, phòng và huấn luyện viên.", [
        ("SessionId", "bigint IDENTITY", "Không", "PK", "Khóa buổi học."),
        ("ClassId", "int", "Không", "FK → LopTap", "Loại lớp."),
        ("RoomId", "int", "Không", "FK → PhongTap", "Phòng tổ chức."),
        ("TrainerId", "int", "Không", "FK → NhanVien", "Huấn luyện viên."),
        ("StartAt; EndAt", "datetime2(0)", "Không", "CHECK EndAt > StartAt", "Khoảng thời gian buổi học."),
        ("Capacity", "smallint", "Không", "CHECK 1–500; trigger ≤ sức chứa phòng", "Số chỗ mở bán."),
        ("Status", "varchar(20)", "Không; SCHEDULED", "CHECK 4 trạng thái", "Trạng thái buổi học."),
        ("Note", "nvarchar(500)", "Có", "", "Ghi chú."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("DatLop", "Đặt chỗ, hàng chờ và kết quả tham dự của hội viên.", [
        ("BookingId", "bigint IDENTITY", "Không", "PK", "Khóa đặt chỗ."),
        ("MemberId", "int", "Không", "FK → HoiVien; UNIQUE cùng SessionId", "Hội viên đặt chỗ."),
        ("SessionId", "bigint", "Không", "FK → LichLop; UNIQUE cùng MemberId", "Buổi được đặt."),
        ("Status", "varchar(20)", "Không; CONFIRMED", "CHECK 5 trạng thái", "Xác nhận, chờ, tham dự, vắng hoặc hủy."),
        ("BookedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm đặt."),
        ("CancelledAt", "datetime2(0)", "Có", "Ràng buộc theo Status", "Thời điểm hủy."),
        ("CancellationReason", "nvarchar(500)", "Có", "", "Lý do hủy."),
        ("CreatedAt; UpdatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Mốc audit."),
        ("RowVersion", "rowversion", "Không", "", "Phiên bản dòng."),
    ]),
    ("CheckIn", "Sự kiện hội viên vào tập tự do hoặc tham dự buổi lớp.", [
        ("CheckInId", "bigint IDENTITY", "Không", "PK", "Khóa lượt vào."),
        ("MemberId", "int", "Không", "FK → HoiVien", "Hội viên check-in."),
        ("EmployeeId", "int", "Không", "FK → NhanVien", "Nhân viên tiếp nhận."),
        ("SessionId", "bigint", "Có", "FK → LichLop", "Buổi lớp; rỗng nếu tập tự do."),
        ("CheckedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm vào."),
        ("CheckInMethod", "varchar(20)", "Không; FRONT_DESK", "CHECK 3 phương thức", "Nguồn ghi nhận lượt vào."),
        ("Note", "nvarchar(500)", "Có", "", "Ghi chú vận hành."),
        ("CreatedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm tạo."),
    ]),
    ("AuditLog", "Nhật ký thay đổi và đăng nhập để truy vết sự kiện quan trọng.", [
        ("AuditId", "bigint IDENTITY", "Không", "PK", "Khóa nhật ký."),
        ("TableName", "sysname", "Không", "", "Tên đối tượng phát sinh thay đổi."),
        ("ActionType", "varchar(10)", "Không", "CHECK INSERT/UPDATE/DELETE/LOGIN", "Loại sự kiện."),
        ("EntityKey", "nvarchar(200)", "Không", "", "Khóa thực thể dạng văn bản."),
        ("OldValues; NewValues", "nvarchar(max)", "Có", "CHECK ISJSON", "Ảnh dữ liệu trước và sau."),
        ("ChangedByUserId", "int", "Có", "FK → NguoiDung", "Tài khoản thực hiện."),
        ("CorrelationId", "uniqueidentifier", "Không; NEWID", "DEFAULT", "Mã tương quan xuyên suốt thao tác."),
        ("ChangedAt", "datetime2(0)", "Không; UTC", "DEFAULT", "Thời điểm sự kiện."),
    ]),
]


def configure_document(document):
    section = document.sections[0]
    section.page_width = Cm(21)
    section.page_height = Cm(29.7)
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(3)
    section.right_margin = Cm(2)
    section.header_distance = Cm(1.2)
    section.footer_distance = Cm(1.2)

    normal = document.styles["Normal"]
    normal.font.name = "Times New Roman"
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
    normal.font.size = Pt(13)
    normal.font.color.rgb = BLACK
    normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    normal.paragraph_format.first_line_indent = Cm(1)
    normal.paragraph_format.line_spacing = 1.5
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.widow_control = True

    heading_settings = {
        "Heading 1": (16, WD_ALIGN_PARAGRAPH.CENTER, Pt(12), Pt(12)),
        "Heading 2": (14, WD_ALIGN_PARAGRAPH.LEFT, Pt(10), Pt(6)),
        "Heading 3": (13, WD_ALIGN_PARAGRAPH.LEFT, Pt(8), Pt(4)),
    }
    for style_name, (size, alignment, before, after) in heading_settings.items():
        style = document.styles[style_name]
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
        style.font.size = Pt(size)
        style.font.bold = True
        style.font.color.rgb = BLACK
        style.paragraph_format.alignment = alignment
        style.paragraph_format.first_line_indent = Cm(0)
        style.paragraph_format.space_before = before
        style.paragraph_format.space_after = after
        style.paragraph_format.keep_with_next = True

    for name in ("Figure Caption", "Table Caption"):
        style = document.styles.add_style(name, WD_STYLE_TYPE.PARAGRAPH)
        style.font.name = "Times New Roman"
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
        style.font.size = Pt(12)
        style.font.italic = True
        style.font.color.rgb = BLACK
        style.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
        style.paragraph_format.first_line_indent = Cm(0)
        style.paragraph_format.line_spacing = 1
        style.paragraph_format.space_before = Pt(3)
        style.paragraph_format.space_after = Pt(6)
        style.paragraph_format.keep_with_next = name == "Table Caption"

    code = document.styles.add_style("Source Code", WD_STYLE_TYPE.PARAGRAPH)
    code.font.name = "Consolas"
    code._element.rPr.rFonts.set(qn("w:eastAsia"), "Consolas")
    code.font.size = Pt(10)
    code.font.color.rgb = BLACK
    code.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.LEFT
    code.paragraph_format.first_line_indent = Cm(0)
    code.paragraph_format.left_indent = Cm(0.4)
    code.paragraph_format.right_indent = Cm(0.2)
    code.paragraph_format.line_spacing_rule = WD_LINE_SPACING.SINGLE
    code.paragraph_format.space_before = Pt(3)
    code.paragraph_format.space_after = Pt(6)


def add_cover(document):
    section = document.sections[0]
    section.different_first_page_header_footer = True
    for _ in range(2):
        document.add_paragraph("")
    p = document.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    run = p.add_run("TRƯỜNG: ........................................................\nKHOA/BỘ MÔN: ................................................")
    run.bold = True
    run.font.size = Pt(14)

    document.add_paragraph("")
    p = document.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    run = p.add_run("BÁO CÁO ĐỒ ÁN\nHỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU")
    run.bold = True
    run.font.size = Pt(20)

    document.add_paragraph("")
    p = document.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    run = p.add_run("ĐỀ TÀI\nHỆ THỐNG QUẢN LÝ PHÒNG GYM")
    run.bold = True
    run.font.size = Pt(22)

    for _ in range(3):
        document.add_paragraph("")
    rows = [
        ("Giảng viên hướng dẫn", ": ........................................................"),
        ("Lớp học phần", ": ........................................................"),
        ("Sinh viên thực hiện", ": Điền họ tên và MSSV trong Phụ lục A"),
    ]
    table = document.add_table(rows=0, cols=2)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for label, value in rows:
        cells = table.add_row().cells
        set_cell_text(cells[0], label, bold=True, size=13)
        set_cell_text(cells[1], value, size=13)
    for _ in range(3):
        document.add_paragraph("")
    p = document.add_paragraph("TP. HỒ CHÍ MINH, THÁNG 10 NĂM 2026")
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.runs[0].bold = True

    content = document.add_section(WD_SECTION.NEW_PAGE)
    content.page_width = Cm(21)
    content.page_height = Cm(29.7)
    content.top_margin = Cm(2.5)
    content.bottom_margin = Cm(2.5)
    content.left_margin = Cm(3)
    content.right_margin = Cm(2)
    add_page_number(content)


def add_front_matter(document):
    add_heading(document, "MỤC LỤC", 1)
    p = document.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    add_field(p, 'TOC \\o "1-3" \\h \\z \\u', "Mục lục sẽ được Word cập nhật.")

    figure_list_heading = add_heading(document, "DANH MỤC HÌNH", 1)
    figure_list_heading.paragraph_format.page_break_before = True
    p = document.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    add_field(p, 'TOC \\h \\z \\t "Figure Caption,1"', "Danh mục hình sẽ được Word cập nhật.")

    table_list_heading = add_heading(document, "DANH MỤC BẢNG", 1)
    table_list_heading.paragraph_format.page_break_before = True
    p = document.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    add_field(p, 'TOC \\h \\z \\t "Table Caption,1"', "Danh mục bảng sẽ được Word cập nhật.")

    add_heading(document, "DANH MỤC TỪ VIẾT TẮT", 1)
    add_table(document, "Bảng 0.1. Từ viết tắt sử dụng trong báo cáo", ["Từ viết tắt", "Nội dung"], [
        ("CSDL", "Cơ sở dữ liệu"),
        ("DBMS", "Database Management System – Hệ quản trị cơ sở dữ liệu"),
        ("ERD", "Entity–Relationship Diagram – Sơ đồ thực thể–liên kết"),
        ("FK/PK", "Foreign Key/Primary Key – Khóa ngoại/khóa chính"),
        ("RBAC", "Role-Based Access Control – Kiểm soát truy cập theo vai trò"),
        ("UI/UX", "Giao diện người dùng/Trải nghiệm người dùng"),
    ], [3, 13.5], font_size=11)


def build_report():
    document = Document()
    configure_document(document)
    document.core_properties.title = "Hệ thống quản lý phòng gym"
    document.core_properties.subject = "Báo cáo đồ án Hệ quản trị cơ sở dữ liệu"
    document.core_properties.author = "Nhóm thực hiện đề tài"
    document.core_properties.comments = "Sinh tự động từ mã nguồn và bằng chứng của repository."

    add_cover(document)
    add_front_matter(document)

    add_chapter(document, 1, "TỔNG QUAN ĐỀ TÀI")
    add_body(document, "Chương này xác định bối cảnh, phát biểu bài toán, mục tiêu và phạm vi để toàn bộ thiết kế dữ liệu cùng ứng dụng thống nhất một ranh giới nghiệp vụ.")
    add_heading(document, "1.1. Lý do chọn đề tài", 2)
    add_body(document, "Phòng gym là môi trường có dữ liệu biến động liên tục giữa quầy lễ tân, khu tập, lớp nhóm và bộ phận kế toán. Một hội viên có thể mua nhiều gói theo thời gian, thanh toán thành nhiều lần, đặt chỗ tại các buổi học có giới hạn sức chứa và phát sinh nhiều lượt check-in. Nếu các bộ phận quản lý bằng bảng tính tách rời, mã hội viên dễ trùng, quyền sử dụng khó kiểm chứng, tổng tiền đã thu có thể sai lệch và số chỗ của lớp có thể bị bán vượt mức.")
    add_body(document, "Đề tài phù hợp với môn Hệ quản trị cơ sở dữ liệu vì bài toán không chỉ yêu cầu lưu trữ. Tính đúng đắn phụ thuộc vào khóa, ràng buộc miền, quan hệ tham chiếu, transaction nhiều bảng, khóa đồng thời, phân quyền và index. Do đó, hệ thống được phát triển theo hướng database-first: SQL Server là nơi bảo vệ luật cốt lõi, còn ứng dụng web tạo quy trình thao tác thân thiện và thể hiện kết quả từ CSDL thật.")

    add_heading(document, "1.2. Phát biểu bài toán", 2)
    add_body(document, "Hệ thống cần quản lý vòng đời hội viên từ lúc tạo hồ sơ, chọn gói tập, lập hóa đơn, ghi nhận thanh toán, kích hoạt quyền sử dụng, đặt lớp, hủy chỗ đến check-in. Bên cạnh đó, người quản trị cần quản lý phòng, loại lớp, lịch huấn luyện viên, công suất buổi học và các tài khoản nhân viên. Kế toán cần đối soát doanh thu theo thời gian; lễ tân cần tra cứu nhanh tình trạng gói; huấn luyện viên cần nhìn thấy lịch phụ trách.")
    add_body(document, "Mọi thao tác ghi phải giữ được tính nguyên tử. Một đăng ký mới chỉ hợp lệ khi đồng thời tạo được đăng ký, hóa đơn và dòng hóa đơn; một lần thanh toán không được làm tổng đã thu vượt quá tổng phải thu; hai yêu cầu đặt chỗ đồng thời không được cùng chiếm ghế cuối. Những quy tắc này phải đúng ngay cả khi thao tác không đi qua giao diện web.")

    add_heading(document, "1.3. Mục tiêu thực hiện", 2)
    add_body(document, "Mục tiêu nghiệp vụ là hình thành một nguồn dữ liệu thống nhất cho hội viên, gói, doanh thu và vận hành lớp. Mục tiêu kỹ thuật là xây dựng lược đồ quan hệ đạt 3NF, cài đặt đầy đủ constraint, trigger, view, function, stored procedure, transaction, role và index; sau đó tích hợp với ASP.NET Core MVC thông qua truy vấn tham số hóa và procedure. Hệ thống phải tái tạo được trên một database rỗng bằng bộ script có thứ tự, đồng thời cung cấp bằng chứng kiểm thử thành công, lỗi, rollback, concurrency, phân quyền và hiệu năng.")

    add_heading(document, "1.4. Phạm vi thực hiện", 2)
    add_body(document, "Phiên bản đồ án phục vụ một cơ sở phòng gym. Phạm vi bao gồm tài khoản nhân viên với bốn vai trò nghiệp vụ, hồ sơ hội viên và thể trạng, gói tập, đăng ký, hóa đơn, thanh toán, phòng tập, loại lớp, lịch lớp, đặt chỗ, hàng chờ, check-in, dashboard, tìm kiếm và báo cáo. Dữ liệu giao dịch được lưu trên SQL Server; thời điểm audit sử dụng UTC để nhất quán, còn dữ liệu hiển thị được quy đổi phù hợp với giờ Việt Nam.")
    add_body(document, "Các nội dung ngoài phạm vi gồm kết nối cổng thanh toán thật, điều khiển cổng ra vào, nhận diện sinh trắc học, quản lý kho, tính lương, ứng dụng di động và nhiều chi nhánh. Việc loại trừ này giúp đồ án tập trung chứng minh đúng các năng lực DBMS thay vì mở rộng sang hạ tầng thương mại chưa cần thiết.")

    add_heading(document, "1.5. Đối tượng sử dụng và quy trình tổng quát", 2)
    add_body(document, "Quản trị viên có quyền điều hành toàn hệ thống; lễ tân quản lý hội viên, đăng ký, booking và check-in; huấn luyện viên theo dõi hoạt động lớp; kế toán xử lý thanh toán và báo cáo tài chính. Quy trình chính bắt đầu khi lễ tân tạo hội viên, chọn gói và ngày hiệu lực. Procedure đăng ký tạo công nợ trong cùng transaction. Sau khi thanh toán đủ, gói chuyển sang ACTIVE. Hội viên có thể đặt lớp nếu gói còn hiệu lực và cho phép tham gia lớp; hệ thống xác nhận chỗ hoặc đưa vào hàng chờ dựa trên sức chứa. Khi hội viên tới phòng gym, procedure check-in xác minh giới hạn lượt và ghi nhận sự kiện.")

    add_chapter(document, 2, "PHÂN TÍCH VÀ THIẾT KẾ CƠ SỞ DỮ LIỆU")
    add_body(document, "Thiết kế dữ liệu được hình thành từ các quy tắc nghiệp vụ của Chương 1. Các thực thể ổn định được tách khỏi sự kiện giao dịch; khóa thay thế bảo đảm liên kết bền vững, còn mã nghiệp vụ có UNIQUE để hỗ trợ tra cứu. Khóa ngoại duy trì toàn vẹn tham chiếu theo nguyên tắc của SQL Server [1].")
    add_heading(document, "2.1. Phân tích yêu cầu dữ liệu", 2)
    add_body(document, "Nhóm danh tính gồm vai trò, tài khoản và nhân viên. Nhóm hội viên–tài chính gồm hội viên, gói, đăng ký, hóa đơn, dòng hóa đơn và thanh toán. Nhóm vận hành gồm phòng, loại lớp, lịch lớp, đặt chỗ và check-in. AuditLog đứng độc lập để lưu ảnh thay đổi dạng JSON và người thực hiện. Cách phân nhóm này phản ánh đúng ranh giới nghiệp vụ nhưng vẫn liên kết qua khóa ngoại khi một giao dịch cần biết nhân viên, hội viên hoặc buổi học liên quan.")
    add_table(document, "Bảng 2.1. Quy tắc nghiệp vụ trọng yếu", ["Mã", "Quy tắc", "Cơ chế bảo vệ"], [
        ("BR-01", "Mã hội viên, tài khoản, hóa đơn và thanh toán không được trùng.", "UNIQUE, sequence"),
        ("BR-02", "Một hội viên không có hai gói ACTIVE chồng lấn.", "Procedure và khóa giao dịch"),
        ("BR-03", "Tổng đã thu nằm trong khoảng từ 0 đến tổng hóa đơn.", "CHECK và procedure"),
        ("BR-04", "Phòng và huấn luyện viên không có hai lịch trùng thời gian.", "Trigger và index"),
        ("BR-05", "Sức chứa lịch không vượt sức chứa phòng; booking xác nhận không vượt sức chứa lịch.", "Trigger, transaction, UPDLOCK"),
        ("BR-06", "Hội viên chỉ đặt lớp/check-in khi có gói phù hợp còn hiệu lực.", "Function và procedure"),
        ("BR-07", "Ứng dụng không ghi trực tiếp vào bảng nghiệp vụ.", "Database role, DENY DML, GRANT EXECUTE"),
    ], [1.7, 9.2, 5.6], font_size=10)

    add_heading(document, "2.2. Mô hình ERD và đối chiếu trên SQL Server", 2)
    add_body(document, "Mô hình ERD gồm 15 thực thể và 19 quan hệ khóa ngoại. Chuỗi HoiVien–DangKyGoi–HoaDon–CTHoaDon/ThanhToan mô tả quyền sử dụng và dòng tiền. Chuỗi PhongTap/LopTap/NhanVien–LichLop–DatLop/CheckIn mô tả tài nguyên và hoạt động lớp. NhanVien xuất hiện ở cả hai miền vì nhân viên là tác nhân bán gói, lập hóa đơn, thu tiền, huấn luyện và tiếp nhận check-in. Các thực thể, khóa chính và quan hệ được mô tả đầy đủ trong lược đồ quan hệ, từ điển dữ liệu và ma trận khóa ngoại ở các mục tiếp theo.")
    add_body(document, "Hai phần của ERD dưới đây được mở trực tiếp bằng Database Diagram của SQL Server Management Studio 22 trên GymManagementDemo. Chế độ Keys chỉ giữ tên bảng, khóa chính và các cột tham chiếu để đường quan hệ không bị che bởi những cột mô tả. Miền hội viên–tài chính và miền vận hành được tách thành hai hình để chữ vẫn đọc được khi in trên giấy A4; đây là hai vùng của cùng một lược đồ 15 bảng, không phải sơ đồ tự dựng.")
    add_picture(document, "ssms-00a-erd-membership.png", "Hình 2.1. ERD miền hội viên, gói tập, hóa đơn và thanh toán trong SSMS", 15.2)
    add_picture(document, "ssms-00b-erd-operations.png", "Hình 2.2. ERD miền lịch lớp, đặt chỗ và check-in trong SSMS", 15.2)
    add_body(document, "Để đối chiếu số lượng và tên quan hệ mà không phụ thuộc bố cục sơ đồ, truy vấn catalog tiếp tục đọc sys.foreign_keys cùng sys.foreign_key_columns. Kết quả hiển thị bảng con, cột FK, bảng cha, cột PK và tên constraint; thanh trạng thái xác nhận truy vấn chạy thành công trên đúng database.")
    add_picture(document, "ssms-01-object-inventory.png", "Hình 2.3. Thống kê đối tượng và danh sách khóa ngoại truy vấn trực tiếp trong SSMS", 16)

    add_heading(document, "2.3. Lược đồ quan hệ", 2)
    add_body(document, "Lược đồ quan hệ được viết ngắn gọn như sau: VaiTro(RoleId); NguoiDung(UserId, RoleId); NhanVien(EmployeeId, UserId); HoiVien(MemberId); GoiTap(PlanId); DangKyGoi(MembershipId, MemberId, PlanId, SoldByEmployeeId); HoaDon(InvoiceId, MembershipId, CreatedByEmployeeId); CTHoaDon(InvoiceDetailId, InvoiceId); ThanhToan(PaymentId, InvoiceId, ReceivedByEmployeeId); PhongTap(RoomId); LopTap(ClassId); LichLop(SessionId, ClassId, RoomId, TrainerId); DatLop(BookingId, MemberId, SessionId); CheckIn(CheckInId, MemberId, EmployeeId, SessionId); AuditLog(AuditId, ChangedByUserId). Thuộc tính đầu tiên trong mỗi quan hệ là khóa chính; các thuộc tính tham chiếu được thể hiện trên ERD và trong từ điển dữ liệu bên dưới.")

    add_heading(document, "2.4. Chuẩn hóa dữ liệu", 2)
    add_body(document, "Các bảng đạt dạng chuẩn thứ nhất vì mỗi cột chứa giá trị nguyên tử và không có nhóm lặp. Dạng chuẩn thứ hai được bảo đảm vì các bảng dùng khóa chính đơn; riêng ràng buộc duy nhất ghép MemberId–SessionId trong DatLop chỉ biểu diễn khóa ứng viên và mọi thuộc tính mô tả phụ thuộc toàn bộ vào booking. Dạng chuẩn thứ ba đạt được khi thông tin vai trò, gói, phòng, loại lớp và nhân viên được tách thành quan hệ riêng; bảng giao dịch chỉ lưu khóa tham chiếu và dữ kiện của chính sự kiện.")
    add_body(document, "PriceAtPurchase trong DangKyGoi không phải dữ liệu dư thừa ngoài kiểm soát mà là ảnh giá tại thời điểm bán, cần giữ nguyên khi giá gói hiện hành thay đổi. LineTotal là cột tính toán persisted để công thức dòng hóa đơn luôn thống nhất. Số chỗ còn lại, doanh thu ngày và công suất không được lưu lặp mà được tính qua function hoặc view. Những lựa chọn này cân bằng chuẩn hóa với nhu cầu lưu lịch sử kế toán.")

    add_heading(document, "2.5. Từ điển dữ liệu chi tiết", 2)
    add_body(document, "Từ điển sau mô tả đầy đủ 15 bảng theo phiên bản schema hiện hành. Ký hiệu UTC trong cột mặc định cho biết giá trị được tạo bằng SYSUTCDATETIME(). Những ràng buộc nhiều bảng như không trùng lịch hoặc không vượt sức chứa được nêu ở cột ràng buộc nhưng cài đặt bằng trigger/procedure trong Chương 3.")
    for index, (name, description, columns) in enumerate(TABLES, start=1):
        add_heading(document, f"2.5.{index}. Bảng {name}", 3)
        add_body(document, description)
        add_table(document, f"Bảng 2.{index + 1}. Cấu trúc bảng {name}", ["Tên cột", "Kiểu dữ liệu", "Null/Mặc định", "Ràng buộc", "Ý nghĩa"], columns, [2.6, 2.7, 2.8, 4.1, 4.3], font_size=10)

    add_heading(document, "2.6. Các quyết định thiết kế quan trọng", 2)
    add_body(document, "Thiết kế không chỉ phản ánh danh sách trường mà còn xác định cách dữ liệu tồn tại trong suốt vòng đời hệ thống. Bảng sau ghi rõ lựa chọn, lý do và ảnh hưởng để người bảo trì không vô tình phá vỡ các giả định nghiệp vụ khi mở rộng schema.")
    add_table(document, "Bảng 2.17. Quyết định thiết kế và ảnh hưởng", ["Quyết định", "Lý do", "Ảnh hưởng đến cài đặt"], [
        ("Khóa thay thế dạng IDENTITY", "Liên kết không phụ thuộc mã nghiệp vụ có thể đổi theo chính sách.", "Mã người dùng nhìn thấy vẫn có UNIQUE và được sinh theo sequence khi cần."),
        ("Không xóa dây chuyền giao dịch", "Hóa đơn, thanh toán, booking và check-in là bằng chứng lịch sử.", "FK không dùng ON DELETE CASCADE; hồ sơ chủ yếu được khóa mềm bằng IsActive."),
        ("Lưu tiền bằng decimal(18,2)", "Tránh sai số biểu diễn của float và đủ miền giá trị cho đồ án.", "Mọi phép cộng, giảm giá và công nợ dùng cùng độ chính xác."),
        ("Chụp PriceAtPurchase", "Giá lịch sử không được thay đổi khi quản trị cập nhật GoiTap.Price.", "Báo cáo doanh thu dựa trên giao dịch đã chốt, không join lại giá hiện hành."),
        ("UTC cho audit, giờ địa phương cho lịch", "Audit cần nhất quán; lịch một cơ sở cần khớp giờ nhân viên nhập.", "fn_GioVN chuyển đổi khi so sánh sự kiện UTC với StartAt/EndAt."),
        ("RowVersion trên bản ghi dễ xung đột", "Nhận biết người dùng đang sửa phiên bản cũ mà không khóa dài.", "Repository có thể bổ sung optimistic concurrency khi mở rộng màn hình chỉnh sửa."),
        ("Trạng thái bằng varchar có CHECK", "Giá trị dễ đọc trong demo nhưng vẫn bị giới hạn miền.", "Procedure điều khiển chuyển trạng thái; dữ liệu ngoài miền bị constraint từ chối."),
        ("Dữ liệu tổng hợp không lưu lặp", "SeatsLeft, doanh thu ngày và công suất thay đổi theo giao dịch nguồn.", "View/function tính lại từ dữ liệu gốc, tránh đồng bộ nhiều bản sao."),
        ("Audit JSON", "Cho phép lưu ảnh trước/sau linh hoạt giữa nhiều bảng.", "ISJSON kiểm tra cấu trúc; CorrelationId nối các thay đổi cùng một thao tác."),
        ("Procedure là API ghi", "Một đường ghi thống nhất giúp kiểm soát validation, transaction và quyền.", "rl_GymApp được EXECUTE cần thiết nhưng bị DENY DML trực tiếp."),
    ], [4.2, 6.4, 5.9], font_size=9.8)
    add_body(document, "Các quyết định trên ưu tiên tính đúng đắn và khả năng truy vết của đồ án DBMS. Khi chuyển sang mô hình nhiều chi nhánh hoặc thanh toán trực tuyến, schema có thể bổ sung BranchId, khóa idempotency và bảng sự kiện mà không cần phá vỡ khóa chính hay lịch sử giao dịch hiện tại.")

    add_heading(document, "2.7. Ma trận quan hệ và lực lượng số", 2)
    add_body(document, "Mười chín khóa ngoại hiện thực hóa các quan hệ một–nhiều và quan hệ tùy chọn trên ERD. Cột con luôn đặt index khi phục vụ truy vấn trọng yếu hoặc được bao phủ bởi một index ghép; thao tác xóa không lan truyền tự động để tránh mất lịch sử ngoài ý muốn.")
    add_table(document, "Bảng 2.18. Ma trận 19 khóa ngoại", ["Bảng con", "Cột FK", "Bảng cha", "Lực lượng số và ý nghĩa"], [
        ("NguoiDung", "RoleId", "VaiTro", "Một vai trò có nhiều tài khoản; mỗi tài khoản bắt buộc một vai trò."),
        ("NhanVien", "UserId", "NguoiDung", "Một–không hoặc một; nhân viên có thể chưa được cấp tài khoản."),
        ("DangKyGoi", "MemberId", "HoiVien", "Một hội viên có nhiều lần đăng ký theo thời gian."),
        ("DangKyGoi", "PlanId", "GoiTap", "Một gói được bán cho nhiều đăng ký."),
        ("DangKyGoi", "SoldByEmployeeId", "NhanVien", "Một nhân viên có thể bán nhiều đăng ký."),
        ("HoaDon", "MembershipId", "DangKyGoi", "Mỗi hóa đơn thuộc một đăng ký; đăng ký có chứng từ công nợ."),
        ("HoaDon", "CreatedByEmployeeId", "NhanVien", "Nhân viên lập nhiều hóa đơn."),
        ("CTHoaDon", "InvoiceId", "HoaDon", "Một hóa đơn có một hoặc nhiều dòng chi tiết."),
        ("ThanhToan", "InvoiceId", "HoaDon", "Một hóa đơn có thể được thanh toán nhiều lần."),
        ("ThanhToan", "ReceivedByEmployeeId", "NhanVien", "Nhân viên tiếp nhận nhiều khoản thu."),
        ("LichLop", "ClassId", "LopTap", "Một loại lớp được tổ chức thành nhiều buổi."),
        ("LichLop", "RoomId", "PhongTap", "Một phòng chứa nhiều buổi không trùng thời gian."),
        ("LichLop", "TrainerId", "NhanVien", "Một HLV phụ trách nhiều buổi không trùng thời gian."),
        ("DatLop", "MemberId", "HoiVien", "Một hội viên có nhiều booking ở các buổi khác nhau."),
        ("DatLop", "SessionId", "LichLop", "Một buổi có nhiều booking theo giới hạn capacity."),
        ("CheckIn", "MemberId", "HoiVien", "Một hội viên có nhiều lượt vào."),
        ("CheckIn", "EmployeeId", "NhanVien", "Một nhân viên ghi nhận nhiều lượt vào."),
        ("CheckIn", "SessionId", "LichLop", "Quan hệ tùy chọn; NULL biểu diễn tập tự do."),
        ("AuditLog", "ChangedByUserId", "NguoiDung", "Quan hệ tùy chọn; sự kiện hệ thống có thể không gắn người dùng."),
    ], [3.2, 3.3, 3.2, 6.8], font_size=9.5)
    add_body(document, "Ma trận cho thấy không có quan hệ nhiều–nhiều chưa được tách. Quan hệ giữa hội viên và buổi lớp được giải quyết bằng DatLop; quan hệ giữa đăng ký và các khoản thu được giải quyết qua HoaDon–ThanhToan. Cách biểu diễn này cho phép lưu thuộc tính riêng của quan hệ như trạng thái booking, thời điểm đặt, số tiền và phương thức thanh toán.")

    add_chapter(document, 3, "CÀI ĐẶT CƠ SỞ DỮ LIỆU TRÊN SQL SERVER")
    add_heading(document, "3.1. Quy trình cài đặt", 2)
    add_body(document, "Bộ cài nằm trong thư mục database và được điều phối bởi run-database.ps1. Script nhận tên SQL Server cùng tên database qua tham số, truyền SQLCMD variable và thực thi theo thứ tự phụ thuộc. Tùy chọn DropExisting chỉ dùng cho môi trường demo hoặc kiểm thử. Quá trình dựng mới đi từ tạo database, schema, constraint, function, trigger, view, index, procedure, security, seed đến smoke test; bất kỳ lỗi nào cũng làm tiến trình dừng thay vì để lại trạng thái tưởng như thành công.")
    add_code(document, """
    .\\database\\run-database.ps1 `
      -Server '.\\SQLEXPRESS' `
      -DatabaseName 'GymManagementDemo' `
      -DropExisting
    """)
    add_body(document, "Kết quả clean install ghi nhận 15 bảng, 19 khóa ngoại, 43 CHECK đáng tin cậy, 6 trigger, 9 view, 20 index không phải khóa chính, 42 stored procedure, 9 function và 5 database role. Các con số được truy vấn trực tiếp từ catalog hệ thống thay vì đếm thủ công.")
    add_picture(document, "ssms-01-object-inventory.png", "Hình 3.1. Kết quả đếm đối tượng của GymManagementDemo trong SSMS", 16)
    add_body(document, "Ảnh chụp SSMS cho thấy câu lệnh đọc sys.tables, sys.foreign_keys, sys.check_constraints, sys.triggers, sys.views, sys.indexes, sys.procedures và sys.objects. Dòng trạng thái hiển thị Query executed successfully, instance (local)\\SQLEXPRESS và database GymManagementDemo, nên số liệu trong báo cáo có thể đối chiếu trực tiếp với CSDL đã cài trên máy.")

    add_heading(document, "3.2. Tạo bảng và ràng buộc", 2)
    add_body(document, "Script 01_schema.sql đặt XACT_ABORT ON và bao toàn bộ thao tác tạo bảng trong TRY/CATCH cùng transaction. Nếu schema đã tồn tại, script chủ động THROW để tránh chạy đè dữ liệu. PK dùng clustered index mặc định; FK chỉ ra quan hệ tham chiếu; UNIQUE bảo vệ mã nghiệp vụ; CHECK giới hạn miền trạng thái, tiền, ngày và định dạng; DEFAULT thống nhất giá trị khởi tạo.")
    add_code(document, """
    CREATE TABLE dbo.DatLop
    (
        BookingId   bigint IDENTITY(1,1) NOT NULL,
        MemberId    int NOT NULL,
        SessionId   bigint NOT NULL,
        Status      varchar(20) NOT NULL
            CONSTRAINT DF_DatLop_Status DEFAULT ('CONFIRMED'),
        BookedAt    datetime2(0) NOT NULL
            CONSTRAINT DF_DatLop_BookedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_DatLop PRIMARY KEY CLUSTERED (BookingId),
        CONSTRAINT FK_DatLop_HoiVien FOREIGN KEY (MemberId)
            REFERENCES dbo.HoiVien(MemberId),
        CONSTRAINT FK_DatLop_LichLop FOREIGN KEY (SessionId)
            REFERENCES dbo.LichLop(SessionId),
        CONSTRAINT UQ_DatLop_Member_Session UNIQUE (MemberId, SessionId),
        CONSTRAINT CK_DatLop_Status CHECK
            (Status IN ('CONFIRMED','WAITLISTED','ATTENDED','NO_SHOW','CANCELLED'))
    );
    """)
    add_body(document, "Đoạn trích cho thấy một đặt chỗ không thể tồn tại nếu hội viên hoặc buổi học không tồn tại; một hội viên không thể đặt trùng cùng buổi; trạng thái ngoài miền bị từ chối ngay tại CSDL. Đây là lớp bảo vệ áp dụng cho mọi nguồn ghi, kể cả công cụ SQL ngoài ứng dụng [1].")
    add_picture(document, "ssms-02-table-constraints.png", "Hình 3.2. Cột, kiểu dữ liệu, khóa và constraint của bảng HoiVien trong SSMS", 16)

    add_heading(document, "3.3. Trigger", 2)
    add_body(document, "Sáu trigger được dùng cho quy tắc cần quan sát nhiều dòng hoặc nhiều bảng: ngăn xóa hội viên đang có gói hiệu lực; xác minh người được xếp lịch là TRAINER; ngăn trùng phòng hoặc HLV; giới hạn capacity của lịch theo phòng; ngăn số booking CONFIRMED vượt sức chứa; và ngăn đặt chỗ vào buổi không hợp lệ. Trigger được viết theo tập inserted/deleted, không giả định mỗi lệnh chỉ tác động một dòng.")
    add_code(document, extract_object("database/03b_operations_triggers.sql", "CREATE OR ALTER TRIGGER dbo.trg_LichLop_NoOverlap", 45))
    add_body(document, "Trigger minh họa dùng điều kiện giao nhau nửa mở: hai khoảng thời gian trùng khi thời điểm bắt đầu của khoảng thứ nhất nhỏ hơn thời điểm kết thúc của khoảng thứ hai và ngược lại. Điều kiện áp dụng đồng thời cho phòng hoặc huấn luyện viên, bỏ qua lịch đã hủy và kiểm tra toàn bộ tập inserted. Khi phát hiện vi phạm, transaction hiện tại bị rollback rồi trả mã lỗi nghiệp vụ 52002.")
    add_picture(document, "ssms-04-error-trigger.png", "Hình 3.3. Procedure từ chối số tiền sai và trigger ngăn lịch trùng trong SSMS", 16)
    add_table(document, "Bảng 3.1. Trigger và trách nhiệm", ["Trigger", "Bảng", "Trách nhiệm"], [
        ("trg_HoiVien_PreventDeleteActive", "HoiVien", "Từ chối xóa cứng hội viên còn gói ACTIVE."),
        ("trg_LichLop_ValidateTrainerRole", "LichLop", "Chỉ chấp nhận nhân viên loại TRAINER đang hoạt động."),
        ("trg_LichLop_NoOverlap", "LichLop", "Ngăn trùng lịch phòng và huấn luyện viên."),
        ("trg_LichLop_CapacityWithinRoom", "LichLop", "Giới hạn sức chứa buổi theo phòng."),
        ("trg_DatLop_EnforceSessionCapacity", "DatLop", "Ngăn số chỗ CONFIRMED vượt capacity."),
        ("trg_DatLop_PreventInvalidSessionBooking", "DatLop", "Ngăn booking vào buổi hủy hoặc đã bắt đầu."),
    ], [5.3, 2.6, 8.6], font_size=9.5)

    add_heading(document, "3.4. View", 2)
    add_body(document, "Chín view tạo contract đọc ổn định cho tra cứu và báo cáo. vw_HoiVienSapHetHan tìm gói sắp hết; vw_LichLop_ConCho, vw_LichLop_HomNay và vw_CongSuatLop phục vụ vận hành; vw_LichSuCheckIn tổng hợp điểm danh; vw_TV4_HoiVienTraCuu và vw_TV4_DoanhThuTheoNgay phục vụ màn hình tìm kiếm/báo cáo; vw_HoiVienCoBan và vw_NhanVienTaiKhoan giới hạn cột theo nhu cầu bảo mật. View cơ bản không trả PasswordHash, PasswordSalt hoặc MedicalNote cho vai trò không cần biết.")
    add_code(document, extract_object("database/04b_operations_views.sql", "CREATE OR ALTER VIEW dbo.vw_LichLop_ConCho", 40))
    add_body(document, "vw_LichLop_ConCho nối buổi học với tên lớp, phòng và huấn luyện viên, sau đó dùng OUTER APPLY để đếm những trạng thái thật sự chiếm chỗ. WAITLISTED và CANCELLED không được tính, nhờ đó SeatsLeft là một giá trị dẫn xuất nhất quán cho cả giao diện lẫn các báo cáo công suất.")
    add_picture(document, "ssms-06-view-function.png", "Hình 3.4. Kết quả thực thi view lịch còn chỗ và function điều kiện đặt lớp", 16)

    add_heading(document, "3.5. Stored procedure", 2)
    add_body(document, "Bốn mươi hai stored procedure là API dữ liệu của ứng dụng. Nhóm hội viên–billing quản lý hồ sơ, gói, đăng ký, thanh toán và hủy gói. Nhóm vận hành quản lý phòng, loại lớp, lịch, booking, check-in và tra cứu nhanh. Nhóm báo cáo cung cấp dashboard, doanh thu, công suất và điểm danh. Nhóm bảo mật xử lý xác thực, đếm đăng nhập sai, ghi đăng nhập thành công và đổi mật khẩu.")
    add_table(document, "Bảng 3.2. Phân nhóm stored procedure", ["Nhóm", "Số lượng", "Procedure tiêu biểu", "Đặc điểm"], [
        ("Hội viên và billing", "13", "sp_HoiVien_Luu; sp_DangKyGoiTapMoi; sp_ThanhToan_Them", "Giao dịch hồ sơ, công nợ và thanh toán."),
        ("Vận hành", "20", "sp_LichLop_TaoLich; sp_DatLop_DatCho; sp_CheckIn_GhiNhan", "Phòng, lớp, lịch, booking, hàng chờ, check-in."),
        ("Báo cáo", "5", "sp_TV4_DashboardHoiVien; sp_TV4_BaoCaoDoanhThu", "Truy vấn lọc và tổng hợp cho web."),
        ("Xác thực", "4", "sp_AuthenticateUser; sp_RecordFailedLogin", "Đăng nhập, lockout và đổi mật khẩu."),
    ], [3.1, 1.6, 6.3, 5.5], font_size=9.5)
    add_code(document, extract_object("database/06a_membership_procedures.sql", "CREATE OR ALTER PROCEDURE dbo.sp_DangKyGoiTapMoi", 55))
    add_body(document, "Đoạn mở đầu của sp_DangKyGoiTapMoi cho thấy procedure nhận khóa hội viên, gói, nhân viên và ngày bắt đầu; phần thân xác minh dữ liệu tham chiếu, khóa phạm vi cần thiết, tính ngày kết thúc, chụp giá và tạo ba bản ghi liên quan. Mã đầy đủ được trình bày tiếp trong Phụ lục B để chứng minh nhánh COMMIT và CATCH/ROLLBACK.")

    add_heading(document, "3.6. Function", 2)
    add_body(document, "Chín function đóng gói phép tính có thể tái sử dụng. fn_TongDoanhThuHoiVien và fn_XepHangHoiVien hỗ trợ phân tích giá trị hội viên; fn_GioVN quy đổi thời gian; fn_ChoTrongLop trả số ghế còn; fn_GoiHieuLuc và fn_DieuKienDatLop kiểm tra quyền sử dụng; fn_SoLuotCheckInTrongNgay kiểm soát giới hạn lượt; fn_CoTheHuyDatLop đánh giá thời hạn hủy; fn_LichLopTheoKhoang là inline table-valued function trả lịch trong một khoảng.")
    add_code(document, extract_object("database/07b_operations_functions.sql", "CREATE OR ALTER FUNCTION dbo.fn_ChoTrongLop", 32))
    add_body(document, "fn_ChoTrongLop tính sức chứa trừ số booking ở ba trạng thái chiếm chỗ. Function trả NULL nếu buổi không tồn tại và có thể trả số âm nếu dữ liệu từng bị vượt chỗ, giúp kiểm toán phát hiện sai lệch thay vì che giấu bằng cách ép về 0.")

    add_heading(document, "3.7. Index", 2)
    add_body(document, "Index được thiết kế theo truy vấn thực tế thay vì tạo cho mọi cột [5]. Ngoài index phục vụ PK/UNIQUE, bảy index tải công việc tập trung vào gói theo hội viên–trạng thái, hóa đơn theo đăng ký–trạng thái, booking theo buổi–trạng thái, chống trùng lịch theo phòng/HLV–thời gian, tìm lịch theo thời điểm và lịch sử check-in theo hội viên–thời gian.")
    index_lines = read_source("database/05b_operations_indexes.sql").splitlines()
    add_code(document, "\n".join(index_lines[20:58]))
    add_body(document, "Các cột đứng đầu index trùng với điều kiện lọc và nối phổ biến; cột INCLUDE đáp ứng dữ liệu trả về nhưng không làm mở rộng khóa sắp xếp. Script kiểm tra sys.indexes trước khi CREATE nên có thể chạy lại an toàn trong quá trình tích hợp.")
    add_table(document, "Bảng 3.3. Index phục vụ tải công việc", ["Index", "Cột khóa", "Truy vấn hưởng lợi"], [
        ("IX_DangKyGoi_MemberId_Status", "MemberId, Status", "Kiểm tra gói hiệu lực của hội viên."),
        ("IX_HoaDon_MembershipId_Status", "MembershipId, Status", "Tìm công nợ của đăng ký."),
        ("IX_DatLop_SessionId_Status", "SessionId, Status", "Đếm chỗ xác nhận và hàng chờ."),
        ("IX_LichLop_RoomId_StartAt_EndAt", "RoomId, StartAt, EndAt", "Phát hiện trùng phòng."),
        ("IX_LichLop_TrainerId_StartAt_EndAt", "TrainerId, StartAt, EndAt", "Phát hiện trùng HLV."),
        ("IX_LichLop_StartAt_Status", "StartAt, Status", "Tra lịch theo thời gian."),
        ("IX_CheckIn_MemberId_CheckedAt", "MemberId, CheckedAt", "Đếm và tra cứu lượt check-in."),
    ], [6.2, 5.2, 5.1], font_size=9.3)
    add_body(document, "Benchmark với cùng truy vấn cho thấy logical reads trên LichLop giảm từ 16 xuống 6, tương đương 62,5%. Kết quả được thu bằng SET STATISTICS IO, TIME ON và không dùng thay đổi câu truy vấn để làm sai lệch so sánh.")
    add_picture(document, "ssms-07-index-statistics.png", "Hình 3.5. STATISTICS IO/TIME trước và sau index: logical reads giảm từ 16 xuống 6", 16)
    add_picture(document, "ssms-08-index-execution-plan.png", "Hình 3.6. Actual Execution Plan sử dụng Nonclustered Index Seek", 16)

    add_heading(document, "3.8. Kiểm thử SQL", 2)
    add_body(document, "Smoke test xác minh seed, object count, truy vấn view và luồng giao dịch chính. Các script chuyên biệt còn kiểm tra rollback khi dữ liệu vi phạm, quyền GRANT/DENY, booking đồng thời và index trước–sau. Kết quả kiểm thử cạnh tranh được trình bày tại Chương 4; dữ liệu thử của benchmark và concurrency đều được dọn sau khi chụp bằng chứng để database demo trở về trạng thái nghiệp vụ ban đầu.")

    add_chapter(document, 4, "QUẢN LÝ GIAO DỊCH VÀ BẢO MẬT")
    add_heading(document, "4.1. Nguyên tắc quản lý transaction", 2)
    add_body(document, "SQL Server coi transaction là một đơn vị công việc phải hoàn thành toàn bộ hoặc không để lại thay đổi [2]. Các procedure nhiều bảng đặt SET XACT_ABORT ON, mở transaction trong TRY, COMMIT khi mọi bước hợp lệ và ROLLBACK trong CATCH nếu XACT_STATE khác 0. Việc THROW lại lỗi giữ nguyên thông tin cho repository và giao diện, đồng thời tránh nuốt lỗi khiến người dùng tưởng thao tác đã thành công.")
    add_table(document, "Bảng 4.1. Các nghiệp vụ transaction chính", ["Nghiệp vụ", "Bảng bị tác động", "Điều kiện nguyên tử"], [
        ("Đăng ký gói mới", "DangKyGoi, HoaDon, CTHoaDon", "Cả ba bản ghi cùng được tạo hoặc cùng rollback."),
        ("Ghi nhận thanh toán", "ThanhToan, HoaDon, DangKyGoi", "Khoản thu, công nợ và kích hoạt gói đồng bộ."),
        ("Hủy gói", "DangKyGoi, HoaDon", "Trạng thái hủy và chứng từ liên quan nhất quán."),
        ("Đặt chỗ", "LichLop, DatLop", "Khóa buổi học trước khi quyết định CONFIRMED/WAITLISTED."),
        ("Hủy chỗ", "DatLop", "Hủy booking và đôn người chờ lâu nhất trong cùng giao dịch."),
        ("Check-in", "DangKyGoi, CheckIn, DatLop", "Quyền sử dụng và trạng thái tham dự thay đổi đồng bộ."),
    ], [4.1, 5.5, 6.9], font_size=9.5)

    add_heading(document, "4.2. Minh họa đăng ký và thanh toán", 2)
    add_body(document, "sp_DangKyGoiTapMoi khóa phạm vi đăng ký của hội viên, từ chối gói chồng lấn, chụp giá hiện hành, tạo đăng ký PENDING, hóa đơn PENDING và dòng MEMBERSHIP. sp_ThanhToan_Them khóa hóa đơn, kiểm tra số tiền không vượt công nợ, tạo phiếu thu, cập nhật PaidAmount/Status và chỉ chuyển đăng ký sang ACTIVE khi hóa đơn PAID. Nếu một bước lỗi, toàn bộ transaction rollback nên không tồn tại gói không có hóa đơn hoặc tiền thu không phản ánh vào công nợ.")
    add_picture(document, "ssms-03-transaction-rollback.png", "Hình 4.1. Dữ liệu được tạo đầy đủ trong transaction và biến mất sau ROLLBACK", 16)
    add_body(document, "Kết quả SSMS cho thấy procedure tạo đồng thời đăng ký, hóa đơn và trạng thái PAID trong transaction thử. Sau lệnh ROLLBACK, tổng số đăng ký trở về đúng giá trị ban đầu và không còn khóa của dữ liệu thử; cột KetQua trả PASS. Kịch bản lỗi ở Hình 3.3 cũng xác nhận số lượng đăng ký, hóa đơn và thanh toán đều không đổi khi procedure THROW.")

    add_heading(document, "4.3. Điều khiển đồng thời", 2)
    add_body(document, "Nghiệp vụ đặt ghế cuối sử dụng UPDLOCK và HOLDLOCK trên LichLop cùng tập booking liên quan. Phiên đến sau phải chờ phiên trước commit rồi mới đếm lại số chỗ, vì vậy không thể cùng nhìn thấy một ghế trống cũ. Ràng buộc UNIQUE(MemberId, SessionId) ngăn một hội viên tạo hai booking cho cùng buổi. Trigger sức chứa là lớp phòng vệ cuối trong trường hợp nguồn ghi bỏ qua procedure.")
    add_code(document, """
    BEGIN TRANSACTION;
    SELECT @Capacity = Capacity
    FROM dbo.LichLop WITH (UPDLOCK, HOLDLOCK)
    WHERE SessionId = @SessionId AND Status = 'SCHEDULED';

    SELECT @Confirmed = COUNT_BIG(*)
    FROM dbo.DatLop WITH (UPDLOCK, HOLDLOCK)
    WHERE SessionId = @SessionId AND Status = 'CONFIRMED';

    SET @BookingStatus = CASE WHEN @Confirmed < @Capacity
                              THEN 'CONFIRMED' ELSE 'WAITLISTED' END;
    """)
    add_picture(document, "ssms-09-concurrency.png", "Hình 4.2. Hai phiên đồng thời tranh một chỗ: CONFIRMED và WAITLISTED", 16)
    add_body(document, "Trong lần chạy được ghi ở Hình 4.2, phiên A giữ khóa hơn 6 giây; phiên B bắt đầu sau đó khoảng một giây và phải chờ hơn 5 giây. Khi A commit, B đếm lại dữ liệu mới rồi nhận WAITLISTED. Trạng thái cuối có đúng một CONFIRMED trên capacity bằng 1 và cả hai dòng đều trả PASS, chứng minh không xảy ra overbooking.")

    add_heading(document, "4.4. Mô hình bảo mật nhiều lớp", 2)
    add_body(document, "Bảo mật được triển khai từ giao diện đến CSDL. Cookie authentication xác định danh tính; authorization policy giới hạn controller theo RoleCode [7]. Repository chỉ gửi tham số tới procedure, không ghép chuỗi SQL. Tài khoản dịch vụ của web thuộc rl_GymApp, được EXECUTE các procedure cần thiết nhưng bị DENY INSERT, UPDATE, DELETE trên bảng nghiệp vụ. SQL Server role cung cấp ranh giới cuối ngay cả khi một lỗi ứng dụng cố ghi trực tiếp [3], [4].")
    add_table(document, "Bảng 4.2. Vai trò và phạm vi quyền", ["Vai trò", "Phạm vi nghiệp vụ", "Giới hạn chính"], [
        ("rl_GymAdmin", "Quản trị toàn hệ thống", "Không cấp cho tài khoản dịch vụ thường ngày."),
        ("rl_LeTan", "Hội viên, đăng ký, booking, check-in", "Không quản trị tài khoản hoặc báo cáo tài chính đầy đủ."),
        ("rl_HuanLuyenVien", "Lịch và dữ liệu lớp cần thiết", "Không xử lý thanh toán; không xem dữ liệu nhạy cảm."),
        ("rl_KeToan", "Hóa đơn, thanh toán, doanh thu", "Không sửa lịch lớp hoặc hồ sơ sức khỏe."),
        ("rl_GymApp", "EXECUTE API procedure của ứng dụng", "DENY DML trực tiếp trên bảng."),
    ], [3.3, 7.2, 6], font_size=9.5)
    add_picture(document, "ssms-05-security-permissions.png", "Hình 4.3. Kiểm thử role lễ tân: được đọc view nhưng bị DENY sửa trực tiếp bảng", 16)
    add_body(document, "Kịch bản tạo user tạm không có login, thêm vào rl_LeTan rồi EXECUTE AS USER. Vai trò đọc được vw_HoiVienCoBan nhưng UPDATE trực tiếp HoiVien nhận lỗi quyền 229; hai kiểm tra đều PASS. Sau kiểm thử, user tạm được gỡ khỏi role và xóa nên không để lại tài khoản thử trong database.")

    add_heading(document, "4.5. Xác thực và bảo vệ dữ liệu", 2)
    add_body(document, "Mật khẩu được băm PBKDF2 với salt riêng và số vòng lặp lưu cùng tài khoản; mật khẩu rõ không được ghi vào database hoặc log. Cách lưu này phù hợp nguyên tắc password storage của OWASP [8]. Sau năm lần sai, tài khoản bị khóa tạm 15 phút. Đăng nhập thành công đặt lại bộ đếm và được ghi AuditLog. Form thay đổi dữ liệu dùng anti-forgery token theo cơ chế ASP.NET Core [10], model validation kiểm tra đầu vào và mọi SQL parameter có kiểu xác định.")

    add_chapter(document, 5, "XÂY DỰNG ỨNG DỤNG")
    add_heading(document, "5.1. Kiến trúc hệ thống", 2)
    add_body(document, "Ứng dụng dùng mô hình ASP.NET Core MVC: controller tiếp nhận HTTP request và kiểm tra quyền; model/view-model mô tả dữ liệu giao diện; Razor view tạo HTML; service xử lý xác thực; repository gọi SQL Server. Đây là cách phân tách trách nhiệm chuẩn của MVC [6]. Luật cốt lõi không bị sao chép vào giao diện mà được giữ tại stored procedure, function, trigger và constraint.")
    add_body(document, "Connection string được lưu bằng user-secrets khi phát triển thay vì commit vào Git. SqlConnectionFactory tạo kết nối theo cấu hình; repository tạo SqlCommand dạng StoredProcedure, khai báo SqlParameter và ánh xạ kết quả về view-model. Cách tham số hóa giảm nguy cơ SQL injection và làm rõ contract kiểu dữ liệu [9].")
    add_body(document, "Luồng xử lý bắt đầu tại Razor form, đi qua controller và authorization policy tới service/repository. Repository mở SqlConnection, gọi stored procedure với tham số có kiểu và chỉ trả kết quả sau khi SQL Server hoàn tất transaction. Chiều đọc đi qua procedure, view hoặc function; chiều ghi không cho phép ứng dụng thao tác trực tiếp bảng. Health check sử dụng một kết nối độc lập để xác nhận database sẵn sàng mà không thay đổi dữ liệu nghiệp vụ.")

    add_heading(document, "5.2. Công nghệ sử dụng", 2)
    add_table(document, "Bảng 5.1. Công nghệ và vai trò", ["Công nghệ", "Phiên bản/loại", "Vai trò trong hệ thống"], [
        ("SQL Server Express", "SQL Server", "Lưu trữ, transaction, role, index và lập trình T-SQL."),
        ("ASP.NET Core MVC", ".NET 8", "Ứng dụng web, routing, validation, authorization."),
        ("ADO.NET", "Microsoft.Data.SqlClient", "Gọi stored procedure bằng tham số có kiểu."),
        ("Razor, HTML, CSS", "Server-rendered UI", "Giao diện đáp ứng, biểu mẫu và bảng dữ liệu."),
        ("xUnit", ".NET test", "Kiểm thử service, model và authorization."),
        ("PowerShell, sqlcmd", "Tự động hóa", "Dựng database và chạy kịch bản kiểm thử."),
        ("Git/GitHub", "Quản lý phiên bản", "Theo dõi thay đổi, issue và tích hợp nhánh."),
    ], [4.1, 4.1, 8.3], font_size=9.5)

    add_heading(document, "5.3. Màn hình đăng nhập", 2)
    add_body(document, "Màn hình đăng nhập chỉ yêu cầu tên đăng nhập và mật khẩu, thông báo lỗi không tiết lộ tài khoản có tồn tại hay không. Khi xác thực thành công, cookie chứa claim định danh và RoleCode; thanh điều hướng được điều chỉnh theo policy nhưng controller vẫn kiểm tra quyền độc lập.")
    add_picture(document, "01-login.png", "Hình 5.1. Màn hình đăng nhập với hình nền chủ đề phòng gym", 15.5)

    add_heading(document, "5.4. Dashboard", 2)
    add_body(document, "Dashboard tổng hợp số hội viên, gói sắp hết hạn, tình trạng công nợ và hoạt động trong ngày. Các thẻ chỉ số đóng vai trò định hướng thao tác, còn số liệu được lấy từ view/procedure báo cáo thay vì tính từ dữ liệu giả trên trình duyệt.")
    add_picture(document, "02-dashboard.png", "Hình 5.2. Dashboard sau khi đăng nhập", 15.5)

    add_heading(document, "5.5. Quản lý hội viên", 2)
    add_body(document, "Màn hình hội viên hỗ trợ tìm theo mã, tên, điện thoại hoặc email; hiển thị trạng thái và cho phép mở chi tiết/chỉnh sửa theo quyền. Biểu mẫu nhập kiểm tra trường bắt buộc, ngày sinh, điện thoại, chiều cao và cân nặng trước khi repository gọi sp_HoiVien_Luu. Database vẫn kiểm tra lại miền dữ liệu để bảo vệ trường hợp nguồn ghi khác.")
    add_picture(document, "03-members.png", "Hình 5.3. Danh sách và tra cứu hội viên", 15.5)

    add_heading(document, "5.6. Đăng ký gói và thanh toán", 2)
    add_body(document, "Màn hình đăng ký cho phép chọn hội viên, gói, ngày bắt đầu và nhân viên bán. Giá cùng ngày kết thúc do database xác định theo gói tại thời điểm transaction. Danh sách đăng ký hiển thị trạng thái công nợ; chức năng thanh toán chỉ chấp nhận số tiền còn thiếu và cập nhật ngay trạng thái hóa đơn/gói sau khi procedure commit.")
    add_picture(document, "04-memberships.png", "Hình 5.4. Quản lý đăng ký gói và thanh toán", 15.5)

    add_heading(document, "5.7. Vận hành lớp và check-in", 2)
    add_body(document, "Khu vực vận hành tập hợp phòng, loại lớp, lịch, booking và check-in. Khi tạo lịch, người dùng chọn loại lớp, phòng, HLV, thời gian và sức chứa; trigger từ chối trùng lịch hoặc sức chứa vượt phòng. Khi đặt chỗ, giao diện hiển thị kết quả CONFIRMED hoặc WAITLISTED do transaction trả về. Check-in tra cứu hội viên, kiểm tra gói và giới hạn lượt trong cùng procedure.")
    add_picture(document, "05-operations.png", "Hình 5.5. Màn hình vận hành lớp và check-in", 15.5)

    add_heading(document, "5.8. Báo cáo doanh thu", 2)
    add_body(document, "Màn hình báo cáo nhận khoảng ngày, gọi procedure tổng hợp và trình bày tổng doanh thu cùng chi tiết theo ngày. Controller không tự cộng tiền từ dữ liệu tải rời rạc; quy tắc trạng thái thanh toán và khoảng thời gian được áp dụng thống nhất trong SQL Server. Người dùng không thuộc policy báo cáo sẽ nhận Access Denied dù biết URL.")
    add_picture(document, "06-revenue-report.png", "Hình 5.6. Báo cáo doanh thu theo khoảng thời gian", 15.5)

    add_heading(document, "5.9. Kết quả kiểm thử ứng dụng", 2)
    add_body(document, "Bộ test Release chạy 24 test và đạt 24/24, không có test bị bỏ qua. HTTP smoke test kiểm tra health, login và mười route có bảo vệ, tất cả trả mã mong đợi; luồng end-to-end tạo hội viên HV000101, mua gói PREMIUM-90, thanh toán đủ, đặt lớp và check-in thành công với trạng thái ACTIVE, PAID và CONFIRMED. Kết quả chứng minh giao diện đang thao tác trên SQL Server thật chứ không dùng dữ liệu tĩnh.")
    add_table(document, "Bảng 5.2. Tổng hợp bằng chứng kiểm thử", ["Nhóm kiểm thử", "Kết quả", "Bằng chứng lưu trong repository"], [
        ("Clean install", "Đạt", "Script dựng database rỗng hoàn tất và đếm đúng object."),
        ("SQL smoke/rollback", "Đạt", "tests/sql và database/10*.sql."),
        ("Quyền", "Đạt", "Một thao tác được GRANT và một thao tác bị DENY theo login mẫu."),
        ("Concurrency", "Đạt", "Session B chờ 4,835 giây; kết quả 1 CONFIRMED + 1 WAITLISTED."),
        ("Index", "Đạt", "Logical reads LichLop giảm 16 xuống 6."),
        ("xUnit", "24/24", "dotnet test GymManagement.sln --configuration Release."),
        ("HTTP và end-to-end", "Đạt", "Health, login, 10 route và luồng hội viên–check-in."),
    ], [4.1, 2.3, 10.1], font_size=9.5)

    add_chapter(document, 6, "KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN")
    add_heading(document, "6.1. Kết quả đạt được", 2)
    add_body(document, "Đồ án đã xây dựng một hệ thống quản lý phòng gym có thể dựng lại và trình diễn hoàn chỉnh trên SQL Server cùng ASP.NET Core MVC. CSDL gồm 15 bảng liên kết bởi 19 khóa ngoại, có constraint, trigger, view, function, procedure, index và năm role. Các quy trình đăng ký–hóa đơn–thanh toán, đặt chỗ–hàng chờ và check-in được bảo vệ bằng transaction; giao diện cung cấp đăng nhập, hội viên, gói, thanh toán, vận hành và báo cáo.")
    add_body(document, "Kết quả kiểm thử cho thấy database cài sạch thành công, 24/24 unit test đạt, các route web hoạt động, phân quyền chặn đúng thao tác, concurrency không bán vượt ghế và index làm giảm logical reads. Vì script, mã ứng dụng và bằng chứng được lưu chung repository, kết quả báo cáo có thể được tái tạo thay vì chỉ mô tả lý thuyết.")

    add_heading(document, "6.2. Hạn chế", 2)
    add_body(document, "Hệ thống hiện phục vụ một cơ sở và chưa tích hợp thanh toán ngoài, thiết bị kiểm soát cửa hoặc ứng dụng di động. Ảnh chụp minh họa dựa trên dữ liệu demo nên chưa phản ánh khối lượng vận hành dài hạn. Cơ chế báo cáo đáp ứng rubric nhưng chưa có kho dữ liệu riêng, lịch làm mới hay dashboard phân tích nâng cao. Việc triển khai Internet cũng cần hạ tầng SQL Server, HTTPS, secret store, backup và giám sát mà môi trường máy cá nhân chưa cung cấp liên tục.")

    add_heading(document, "6.3. Hướng phát triển", 2)
    add_body(document, "Giai đoạn tiếp theo có thể bổ sung mô hình đa chi nhánh với BranchId và chính sách phân vùng dữ liệu; tích hợp cổng thanh toán qua webhook có idempotency; thêm QR hoặc thiết bị cửa cho check-in; phát triển ứng dụng di động và thông báo lịch; xây dựng cơ chế gia hạn tự động, đóng băng gói, hoàn tiền và khuyến mãi. Về kỹ thuật, hệ thống nên dùng migration có phiên bản, secret manager, job backup/restore định kỳ, telemetry, kiểm thử tải, CI/CD và môi trường staging trước production.")

    document.add_page_break()
    add_heading(document, "TÀI LIỆU THAM KHẢO", 1)
    references = [
        "[1] Microsoft, “Primary and foreign key constraints,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/sql/relational-databases/tables/primary-and-foreign-key-constraints. [Accessed: Oct. 11, 2026].",
        "[2] Microsoft, “Transactions (Transact-SQL),” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/sql/t-sql/language-elements/transactions-transact-sql. [Accessed: Oct. 11, 2026].",
        "[3] Microsoft, “SQL Server security,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/sql/relational-databases/security. [Accessed: Oct. 11, 2026].",
        "[4] Microsoft, “Getting started with Database Engine permissions,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/getting-started-with-database-engine-permissions. [Accessed: Oct. 11, 2026].",
        "[5] Microsoft, “SQL Server index design guide,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/sql/relational-databases/sql-server-index-design-guide. [Accessed: Oct. 11, 2026].",
        "[6] Microsoft, “Overview of ASP.NET Core MVC,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/aspnet/core/mvc/overview. [Accessed: Oct. 11, 2026].",
        "[7] Microsoft, “Use cookie authentication without ASP.NET Core Identity,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/aspnet/core/security/authentication/cookie. [Accessed: Oct. 11, 2026].",
        "[8] OWASP Foundation, “Password Storage Cheat Sheet,” OWASP Cheat Sheet Series. [Online]. Available: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html. [Accessed: Oct. 11, 2026].",
        "[9] Microsoft, “SqlCommand.Parameters property,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/en-us/dotnet/api/microsoft.data.sqlclient.sqlcommand.parameters. [Accessed: Oct. 11, 2026].",
        "[10] Microsoft, “Prevent Cross-Site Request Forgery (XSRF/CSRF) attacks in ASP.NET Core,” Microsoft Learn. [Online]. Available: https://learn.microsoft.com/aspnet/core/security/anti-request-forgery. [Accessed: Oct. 11, 2026].",
    ]
    for reference in references:
        p = document.add_paragraph(reference)
        p.paragraph_format.first_line_indent = Cm(-0.8)
        p.paragraph_format.left_indent = Cm(0.8)
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_after = Pt(6)

    appendix_a = add_heading(document, "PHỤ LỤC A. PHÂN CÔNG CÔNG VIỆC", 1)
    appendix_a.paragraph_format.page_break_before = True
    add_body(document, "Bảng phân công xác định trách nhiệm chính và sản phẩm nghiệm thu của từng thành viên. Họ tên và MSSV được điền trước khi nộp bản chính thức; việc đánh giá mức độ hoàn thành căn cứ commit, issue, pull request, script, kiểm thử và phần báo cáo tương ứng.")
    add_table(document, "Bảng A.1. Phân công chi tiết", ["Thành viên", "Họ tên – MSSV", "Trách nhiệm chính", "Sản phẩm nghiệm thu"], [
        ("TV1 – Trưởng nhóm", "................................", "Phân tích tổng thể; ERD và schema nền tảng; tài khoản, nhân viên, bảo mật; tích hợp develop/main; clean install; kiểm soát rubric và biên tập báo cáo.", "01_schema.sql; 08_security.sql; kiến trúc; checklist tích hợp; báo cáo hoàn chỉnh."),
        ("TV2", "................................", "Hội viên, gói tập, đăng ký, hóa đơn và thanh toán; procedure/trigger/view/function/index của module; test thành công và rollback.", "02a, 03a, 04a, 05a, 06a, 07a; giao diện hội viên/gói/billing; test module."),
        ("TV3", "................................", "Phòng, loại lớp, lịch, booking, hàng chờ, concurrency và check-in; object SQL, giao diện và kịch bản kiểm thử vận hành.", "02b, 03b, 04b, 05b, 06b, 07b; giao diện operations; concurrency test."),
        ("TV4", "................................", "Dashboard, tìm kiếm, báo cáo, repository tích hợp, UX/UI, HTTP/end-to-end test, ảnh minh họa và hỗ trợ tổng hợp bằng chứng.", "04c, 06c; reports/search/dashboard; smoke app; ảnh và số liệu báo cáo."),
    ], [2.7, 3.1, 6.4, 4.3], font_size=9.5)
    add_body(document, "Quy trình phối hợp sử dụng issue để mô tả tiêu chí nghiệm thu. Mỗi thành viên phát triển trên nhánh ngắn xuất phát từ develop, tự kiểm thử trước khi mở pull request; trưởng nhóm rà xung đột schema, chạy lại clean install và test tích hợp. Chỉ phiên bản đã đạt toàn bộ kiểm thử mới được hợp nhất từ develop vào main để tạo mốc nộp.")

    document.add_page_break()
    add_heading(document, "PHỤ LỤC B. SOURCE CODE CHÍNH", 1)
    add_body(document, "Phụ lục trích các đoạn mã quyết định tính đúng đắn của hệ thống. Mã đầy đủ nằm trong repository tại đường dẫn ghi dưới từng mục; các đoạn bị rút gọn chỉ để báo cáo giữ được khả năng đọc và không thay thế source nộp kèm.")

    add_heading(document, "B.1. Transaction đăng ký gói", 2)
    add_body(document, "Nguồn: database/06a_membership_procedures.sql. Procedure tạo đăng ký, hóa đơn và dòng hóa đơn trong cùng transaction.")
    add_code(document, extract_object("database/06a_membership_procedures.sql", "CREATE OR ALTER PROCEDURE dbo.sp_DangKyGoiTapMoi", 105))

    add_heading(document, "B.2. Transaction đặt chỗ và hàng chờ", 2)
    add_body(document, "Nguồn: database/06b_operations_procedures.sql. Procedure sử dụng khóa cập nhật để quyết định trạng thái đặt chỗ an toàn khi có truy cập đồng thời.")
    add_code(document, extract_object("database/06b_operations_procedures.sql", "CREATE OR ALTER PROCEDURE dbo.sp_DatLop_DatCho", 110))

    add_heading(document, "B.3. Phân quyền database", 2)
    add_body(document, "Nguồn: database/08_security.sql. Đoạn trích tạo role và chặn DML trực tiếp đối với tài khoản ứng dụng.")
    security_lines = read_source("database/08_security.sql").splitlines()
    add_code(document, "\n".join(security_lines[:140]))

    add_heading(document, "B.4. Cấu hình pipeline ứng dụng", 2)
    add_body(document, "Nguồn: src/GymManagement.Web/Program.cs. Đoạn mã cấu hình dependency injection, cookie, authorization policy, health check và routing.")
    program_lines = read_source("src/GymManagement.Web/Program.cs").splitlines()
    add_code(document, "\n".join(program_lines[:135]))

    add_heading(document, "B.5. Kết nối SQL Server", 2)
    add_body(document, "Nguồn: src/GymManagement.Web/Data/SqlConnectionFactory.cs. Factory lấy connection string từ cấu hình bí mật và tạo SqlConnection cho repository.")
    add_code(document, read_source("src/GymManagement.Web/Data/SqlConnectionFactory.cs"))

    add_heading(document, "B.6. Dịch vụ xác thực", 2)
    add_body(document, "Nguồn: src/GymManagement.Web/Services/AuthenticationService.cs. Dịch vụ chuẩn hóa tên đăng nhập, kiểm tra khóa tạm, xác minh PBKDF2 và cập nhật trạng thái đăng nhập thông qua repository.")
    add_code(document, read_source("src/GymManagement.Web/Services/AuthenticationService.cs"))

    add_heading(document, "B.7. Repository đăng ký và thanh toán", 2)
    add_body(document, "Nguồn: src/GymManagement.Web/Data/SqlMembershipRepository.cs. Trích đoạn cho thấy ứng dụng chỉ gọi stored procedure, khai báo kiểu cùng kích thước SqlParameter và nhận khóa sinh ra qua tham số OUTPUT; không ghép chuỗi SQL từ dữ liệu người dùng.")
    membership_repository_lines = read_source("src/GymManagement.Web/Data/SqlMembershipRepository.cs").splitlines()
    add_code(document, "\n".join(membership_repository_lines[:170]))

    for section in document.sections:
        section.page_width = Cm(21)
        section.page_height = Cm(29.7)
        section.top_margin = Cm(2.5)
        section.bottom_margin = Cm(2.5)
        section.left_margin = Cm(3)
        section.right_margin = Cm(2)

    document.settings.update_fields_on_open = True
    document.save(REPORT)
    print(f"Generated {REPORT}")


if __name__ == "__main__":
    build_report()
