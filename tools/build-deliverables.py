from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "deliverables"
OUT.mkdir(exist_ok=True)
ASSETS = OUT / "assets"
ASSETS.mkdir(exist_ok=True)


def diagram_font(size, bold=False):
    name = "arialbd.ttf" if bold else "arial.ttf"
    path = Path("C:/Windows/Fonts") / name
    return ImageFont.truetype(str(path), size)


def draw_arrow(draw, start, end, color="#9bdc53", width=5):
    draw.line([start, end], fill=color, width=width)
    x, y = end
    draw.polygon([(x, y), (x - 18, y - 10), (x - 18, y + 10)], fill=color)


def draw_box(draw, bounds, title, subtitle=""):
    draw.rounded_rectangle(bounds, radius=24, fill="#101b18", outline="#9bdc53", width=4)
    left, top, right, _ = bounds
    draw.text((left + 24, top + 20), title, font=diagram_font(34, True), fill="#f4f7f1")
    if subtitle:
        draw.multiline_text(
            (left + 24, top + 70), subtitle, font=diagram_font(23),
            fill="#b9c9c1", spacing=7, align="left")


def generate_architecture_diagram():
    image = Image.new("RGB", (2400, 780), "#07100d")
    draw = ImageDraw.Draw(image)
    boxes = [
        ((60, 250, 400, 520), "Người dùng", "Admin · Lễ tân\nHLV · Kế toán"),
        ((500, 250, 900, 520), "ASP.NET Core MVC", "Razor · Validation\nCookie + Policy RBAC"),
        ((1000, 250, 1370, 520), "Repository", "ADO.NET parameter\nStored procedure only"),
        ((1470, 250, 1870, 520), "SQL Server", "Transaction · Security\nIndex · View · Function"),
        ((1970, 250, 2340, 520), "Bằng chứng", "Smoke · xUnit · HTTP\nConcurrency · Benchmark")
    ]
    draw.text((60, 55), "KIẾN TRÚC HỆ THỐNG QUẢN LÝ PHÒNG GYM", font=diagram_font(54, True), fill="#f4f7f1")
    draw.text((60, 130), "Luồng dữ liệu và ranh giới bảo mật", font=diagram_font(30), fill="#9bdc53")
    for bounds, title, subtitle in boxes:
        draw_box(draw, bounds, title, subtitle)
    for current, following in zip(boxes, boxes[1:]):
        draw_arrow(draw, (current[0][2] + 15, 385), (following[0][0] - 15, 385))
    image.save(ASSETS / "architecture.png")


def generate_erd_diagram():
    image = Image.new("RGB", (2400, 1600), "#07100d")
    draw = ImageDraw.Draw(image)
    draw.text((60, 45), "ERD TỔNG THỂ — 15 BẢNG, 19 KHÓA NGOẠI", font=diagram_font(52, True), fill="#f4f7f1")
    nodes = {
        "VaiTro": (70, 180), "NguoiDung": (70, 430), "NhanVien": (70, 680),
        "AuditLog": (70, 930), "PhongTap": (70, 1180),
        "HoiVien": (860, 180), "GoiTap": (860, 430), "DangKyGoi": (860, 680),
        "HoaDon": (860, 930), "CTHoaDon": (860, 1180),
        "ThanhToan": (1660, 180), "LopTap": (1660, 430), "LichLop": (1660, 680),
        "DatLop": (1660, 930), "CheckIn": (1660, 1180)
    }
    relations = [
        ("VaiTro", "NguoiDung"), ("NguoiDung", "NhanVien"), ("NguoiDung", "AuditLog"),
        ("HoiVien", "DangKyGoi"), ("GoiTap", "DangKyGoi"), ("DangKyGoi", "HoaDon"),
        ("HoaDon", "CTHoaDon"), ("HoaDon", "ThanhToan"), ("NhanVien", "ThanhToan"),
        ("PhongTap", "LichLop"), ("LopTap", "LichLop"), ("NhanVien", "LichLop"),
        ("HoiVien", "DatLop"), ("LichLop", "DatLop"), ("HoiVien", "CheckIn"),
        ("NhanVien", "CheckIn"), ("LichLop", "CheckIn")
    ]
    for source, destination in relations:
        sx, sy = nodes[source]; dx, dy = nodes[destination]
        draw.line([(sx + 300, sy + 82), (dx, dy + 82)], fill="#49655a", width=4)
    subtitles = {
        "VaiTro": "PK RoleId", "NguoiDung": "FK RoleId", "NhanVien": "FK UserId",
        "AuditLog": "FK ChangedByUserId", "PhongTap": "PK RoomId",
        "HoiVien": "PK MemberId", "GoiTap": "PK PlanId",
        "DangKyGoi": "FK MemberId · PlanId", "HoaDon": "FK MembershipId",
        "CTHoaDon": "FK InvoiceId", "ThanhToan": "FK InvoiceId · EmployeeId",
        "LopTap": "PK ClassId", "LichLop": "FK Class · Room · Trainer",
        "DatLop": "FK Member · Session", "CheckIn": "FK Member · Staff · Session"
    }
    for name, (x, y) in nodes.items():
        draw_box(draw, (x, y, x + 300, y + 165), name, subtitles[name])
    image.save(ASSETS / "erd.png")


generate_architecture_diagram()
generate_erd_diagram()

topics = [
    (1,"Bối cảnh bài toán","Phòng gym cần một nguồn dữ liệu duy nhất cho hội viên, tài chính, lớp học và kiểm soát lượt vào."),
    (1,"Mục tiêu hệ thống","Hệ thống hỗ trợ vận hành hằng ngày, giảm nhập liệu trùng và cung cấp báo cáo quản trị trực tiếp từ SQL Server."),
    (1,"Phạm vi phiên bản","Một cơ sở, thanh toán do nhân viên xác nhận, check-in tại quầy và không tích hợp cổng thanh toán hoặc khóa cửa thật."),
    (1,"Đối tượng sử dụng","ADMIN, RECEPTIONIST, TRAINER và ACCOUNTANT có menu, dữ liệu và quyền thao tác khác nhau."),
    (1,"Phương pháp thực hiện","Nhóm phát triển theo contract database, module nghiệp vụ, tích hợp trên develop và kiểm chứng trên database sạch."),
    (1,"Công nghệ","SQL Server, T-SQL, ASP.NET Core MVC .NET 8, ADO.NET, Razor và xUnit được chọn để bám sát mục tiêu DBMS."),
    (1,"Cấu trúc báo cáo","Sáu chương đi từ yêu cầu, thiết kế, cài đặt, ứng dụng đến kiểm thử và đánh giá."),
    (2,"Quản lý hồ sơ hội viên","Hồ sơ có mã duy nhất, thông tin liên hệ, thể trạng, lưu ý sức khỏe và khóa mềm IsActive."),
    (2,"Quản lý gói tập","Gói có thời hạn, giá bán, số lượt check-in tối đa, quyền tham gia lớp và trạng thái kinh doanh."),
    (2,"Đăng ký và gia hạn","Mỗi đăng ký chụp giá tại thời điểm bán, cấm khoảng thời gian chồng lấn và chỉ ACTIVE khi đã trả đủ."),
    (2,"Hóa đơn và thanh toán","Hóa đơn hỗ trợ PENDING, PARTIAL, PAID; thanh toán không được vượt công nợ và lưu phương thức, tham chiếu."),
    (2,"Phòng và loại lớp","Phòng giới hạn sức chứa; loại lớp quy định thời lượng và độ khó; cả hai dùng khóa mềm."),
    (2,"Lịch và huấn luyện viên","Lịch phải dùng HLV hoạt động, không trùng phòng hoặc HLV và không vượt sức chứa phòng."),
    (2,"Đặt chỗ và hàng chờ","Gói phải còn hiệu lực tại ngày học; hết chỗ chuyển WAITLISTED và tự đôn khi có người hủy."),
    (2,"Check-in và báo cáo","Check-in kiểm tra gói, giới hạn lượt, có thể gắn buổi lớp; báo cáo gồm doanh thu, công suất và điểm danh."),
    (3,"Mô hình kiến trúc","MVC gọi repository ADO.NET; repository gọi stored procedure; SQL Server giữ ràng buộc và transaction."),
    (3,"Thiết kế ERD","Mười lăm bảng liên kết bởi mười chín khóa ngoại, tách danh mục, giao dịch, lịch và audit."),
    (3,"Chuẩn hóa 3NF","Giá mua được chụp trong đăng ký; dòng hóa đơn và thanh toán tách bảng; số chỗ và tổng chi là dữ liệu dẫn xuất."),
    (3,"Bảng VaiTro và NguoiDung","Tài khoản tham chiếu vai trò, lưu PBKDF2 hash/salt, lockout và rowversion, không lưu mật khẩu rõ."),
    (3,"Bảng NhanVien","Nhân viên gắn tài khoản tùy chọn và phân loại manager, lễ tân, HLV hoặc kế toán."),
    (3,"Bảng HoiVien","MemberCode và email có tính duy nhất; chiều cao, cân nặng có CHECK; dữ liệu nhạy cảm không lộ trong view cơ bản."),
    (3,"Bảng GoiTap và DangKyGoi","Ngày, giá và trạng thái được kiểm tra; hủy bắt buộc lý do; mỗi gói giữ lịch sử độc lập."),
    (3,"Bảng tài chính","HoaDon, CTHoaDon và ThanhToan tách đúng quan hệ một-nhiều, tiền dùng decimal(18,2)."),
    (3,"Bảng lớp học","PhongTap, LopTap và LichLop biểu diễn tài nguyên, định nghĩa lớp và buổi tổ chức cụ thể."),
    (3,"Bảng đặt chỗ","DatLop duy nhất theo hội viên–buổi, hỗ trợ CONFIRMED, WAITLISTED, ATTENDED, NO_SHOW, CANCELLED."),
    (3,"Bảng CheckIn và AuditLog","Lượt vào lưu UTC; audit có JSON hợp lệ, correlation id và người thay đổi."),
    (3,"Constraint và mặc định","Database sạch ghi nhận 43 CHECK đáng tin cậy cùng UNIQUE, DEFAULT, PK và FK."),
    (4,"Bộ cài database","run-database.ps1 truyền SQLCMD variable, chạy đúng dependency và dừng ngay khi script lỗi."),
    (4,"Stored procedure hội viên","sp_HoiVien_Luu thực hiện create/update có kiểm tra ngày sinh, chuẩn hóa email và sinh mã bằng sequence."),
    (4,"Transaction đăng ký gói","sp_DangKyGoiTapMoi khóa hội viên, chống chồng lấn và tạo đăng ký, hóa đơn, chi tiết, thanh toán nguyên tử."),
    (4,"Transaction thanh toán","sp_ThanhToan_Them khóa hóa đơn, chặn trả quá, cập nhật công nợ và kích hoạt gói khi đủ tiền."),
    (4,"Procedure danh mục","Phòng, loại lớp và gói tập dùng upsert và SetActive để bảo toàn lịch sử thay vì xóa cứng."),
    (4,"Transaction tạo và hủy lịch","Tạo lịch kiểm tra phòng, HLV; hủy lịch đồng thời hủy các booking còn hiệu lực."),
    (4,"Transaction đặt chỗ","UPDLOCK, HOLDLOCK trên LichLop tuần tự hóa hai giao dịch tranh chỗ và loại bỏ overbooking."),
    (4,"Transaction hủy chỗ","Hủy tuân thủ mốc hai giờ và đôn booking WAITLISTED lâu nhất lên CONFIRMED."),
    (4,"Transaction check-in","Procedure kiểm gói, số lượt ngày, booking lớp rồi ghi CheckIn trong cùng transaction."),
    (4,"Trigger","Sáu trigger bảo vệ xóa hội viên active, HLV, trùng lịch, sức chứa phòng, sức chứa booking và trạng thái buổi."),
    (4,"View và function","Chín view cùng chín function cung cấp lịch, số chỗ, gói hiệu lực, doanh thu và dữ liệu báo cáo."),
    (4,"Index","Hai mươi non-PK index phục vụ tìm hội viên, công nợ, lịch, đếm booking và lịch sử check-in."),
    (4,"Bảo mật SQL Server","Năm role áp dụng GRANT, DENY, REVOKE; rl_GymApp chỉ execute procedure và không DML bảng trực tiếp."),
    (5,"Xác thực ứng dụng","Login đọc hash từ sp_AuthenticateUser, kiểm PBKDF2 và ghi nhận thành công/thất bại để lockout."),
    (5,"Phân quyền giao diện","Cookie claim RoleCode ánh xạ policy; mỗi vai trò chỉ thấy và gọi action phù hợp."),
    (5,"CRUD hội viên","Danh sách, tìm kiếm, thêm, sửa, chi tiết và khóa mềm đều gọi procedure có parameter."),
    (5,"Ứng dụng billing","Màn hình đăng ký tạo giao dịch nhiều bảng; màn hình thanh toán phản ánh công nợ còn lại."),
    (5,"Ứng dụng vận hành","UI quản lý phòng, loại lớp, lịch, booking, hàng chờ và check-in; lỗi nghiệp vụ hiển thị cho người dùng."),
    (5,"Dashboard và tìm kiếm","Dashboard tải dữ liệu theo vai trò; tìm hội viên phân trang và escape ký tự LIKE."),
    (5,"Báo cáo","Doanh thu, công suất lớp, điểm danh và hội viên sắp hết hạn đều lấy từ view/procedure."),
    (5,"UX và xử lý lỗi","Giao diện responsive theo chủ đề gym, điều hướng theo vai trò, validation hai lớp, anti-forgery, trạng thái tiếng Việt, thông báo lỗi kết nối và health endpoint."),
    (6,"Chiến lược kiểm thử","Kiểm thử gồm unit, clean-install SQL, smoke theo module, security, HTTP end-to-end, concurrency và index."),
    (6,"Kết quả clean install","Database kiểm thử đạt 15 bảng, 6 trigger, 9 view, 20 index, 42 procedure, 9 function và 5 role."),
    (6,"Kết quả end-to-end","Tạo hội viên, thanh toán gói, đặt lớp và check-in qua HTTP tạo đúng trạng thái ACTIVE, PAID, CONFIRMED."),
    (6,"Kết quả concurrency và index","Session cạnh tranh chờ 4,835 giây và vào WAITLISTED; logical reads lịch lớp giảm từ 18 xuống 3."),
    (6,"Đánh giá và hướng phát triển","Hệ thống đạt phạm vi học phần; hướng sau gồm audit đầy đủ, cổng thanh toán, QR, đa chi nhánh và CI SQL container."),
]

assert len(topics) == 53

# Sắp lại nội dung đúng sáu chương bắt buộc của rubric. Chỉ số dùng 1-based để
# người duy trì có thể đối chiếu trực tiếp với danh sách chủ đề phía trên.
raw_topics = topics
chapter_plan = {
    1: list(range(1, 8)),
    2: list(range(8, 28)),
    3: [28, 29, 32, 37, 38, 39],
    4: [30, 31, 33, 34, 35, 36, 40],
    5: list(range(41, 53)),
    6: [53]
}
topics = [
    (chapter, raw_topics[index - 1][1], raw_topics[index - 1][2])
    for chapter, indexes in chapter_plan.items()
    for index in indexes
]
assert len(topics) == 53

def set_cell_text(cell, text):
    cell.text = str(text)
    for paragraph in cell.paragraphs:
        for run in paragraph.runs:
            run.font.name = "Times New Roman"
            run._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman")
            run.font.size = Pt(11)

def add_field(paragraph, instruction):
    run = paragraph.add_run()
    begin = OxmlElement("w:fldChar"); begin.set(qn("w:fldCharType"), "begin")
    text = OxmlElement("w:instrText"); text.set(qn("xml:space"), "preserve"); text.text = instruction
    separate = OxmlElement("w:fldChar"); separate.set(qn("w:fldCharType"), "separate")
    end = OxmlElement("w:fldChar"); end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, text, separate, end])

doc = Document()
section = doc.sections[0]
section.top_margin = Cm(2.5); section.bottom_margin = Cm(2.5)
section.left_margin = Cm(3.0); section.right_margin = Cm(2.0)

styles = doc.styles
normal = styles["Normal"]
normal.font.name = "Times New Roman"; normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman"); normal.font.size = Pt(13)
normal.paragraph_format.line_spacing = 1.5
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.first_line_indent = Cm(1)
for name, size in [("Title", 20), ("Heading 1", 18), ("Heading 2", 15), ("Heading 3", 13)]:
    style = styles[name]; style.font.name = "Times New Roman"; style._element.rPr.rFonts.set(qn("w:eastAsia"), "Times New Roman"); style.font.size = Pt(size); style.font.bold = True

footer = section.footer.paragraphs[0]
footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
add_field(footer, "PAGE")

title = doc.add_paragraph(style="Title"); title.alignment = WD_ALIGN_PARAGRAPH.CENTER
title.add_run("BÁO CÁO ĐỒ ÁN HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU\n\nHỆ THỐNG QUẢN LÝ PHÒNG GYM")
for line in ["Học phần: DBMS330284", "Đề tài: Hệ thống quản lý phòng gym", "Năm học 2026"]:
    p=doc.add_paragraph(); p.alignment=WD_ALIGN_PARAGRAPH.CENTER; p.add_run(line)
doc.add_page_break()

doc.add_heading("Mục lục",level=1)
toc=doc.add_paragraph(); add_field(toc,"TOC \\o \"1-3\" \\h \\z \\u")
doc.add_paragraph("Mở file bằng Microsoft Word và chọn Update Field để cập nhật số trang mục lục.")
doc.add_page_break()
doc.add_heading("Danh mục hình", level=1)
for caption in [
    "Hình 2.1. Kiến trúc tổng thể của hệ thống",
    "Hình 2.2. ERD tổng thể gồm 15 bảng",
    "Hình 5.1. Màn hình đăng nhập",
    "Hình 5.2. Dashboard quản trị",
    "Hình 5.3. Danh sách hội viên",
    "Hình 5.4. Quản lý đăng ký và thanh toán",
    "Hình 5.5. Vận hành lớp học",
    "Hình 5.6. Báo cáo doanh thu"
]:
    doc.add_paragraph(caption)
doc.add_heading("Danh mục bảng", level=1)
for caption in [
    "Bảng 2.1. Từ điển dữ liệu và quan hệ",
    "Bảng 3.1. Số lượng đối tượng SQL Server",
    "Bảng 4.1. Chính sách phân quyền theo vai trò",
    "Bảng 5.1. Ma trận chức năng ứng dụng",
    "Bảng A.1. Kết quả kiểm thử rubric gate"
]:
    doc.add_paragraph(caption)

chapter_names={
    1:"TỔNG QUAN ĐỀ TÀI",
    2:"PHÂN TÍCH VÀ THIẾT KẾ CƠ SỞ DỮ LIỆU",
    3:"CÀI ĐẶT CƠ SỞ DỮ LIỆU TRÊN SQL SERVER",
    4:"QUẢN LÝ GIAO DỊCH VÀ BẢO MẬT",
    5:"XÂY DỰNG VÀ KIỂM THỬ ỨNG DỤNG",
    6:"KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN"
}
last_chapter=None
for number,(chapter,heading,detail) in enumerate(topics,1):
    doc.add_page_break()
    if chapter != last_chapter:
        doc.add_heading(f"CHƯƠNG {chapter}. {chapter_names[chapter]}",level=1)
        last_chapter=chapter
    doc.add_heading(f"{chapter}.{sum(1 for c,_,_ in topics[:number] if c==chapter)}. {heading}",level=2)
    doc.add_paragraph(detail)
    figures = {
        "Mô hình kiến trúc": [("architecture.png", "Hình 2.1. Kiến trúc tổng thể của hệ thống")],
        "Thiết kế ERD": [("erd.png", "Hình 2.2. ERD tổng thể gồm 15 bảng")],
        "Xác thực ứng dụng": [("01-login.png", "Hình 5.1. Màn hình đăng nhập")],
        "Dashboard và tìm kiếm": [
            ("02-dashboard.png", "Hình 5.2. Dashboard quản trị"),
            ("03-members.png", "Hình 5.3. Danh sách hội viên")
        ],
        "Ứng dụng billing": [("04-memberships.png", "Hình 5.4. Quản lý đăng ký và thanh toán")],
        "Ứng dụng vận hành": [("05-operations.png", "Hình 5.5. Vận hành lớp học")],
        "Báo cáo": [("06-revenue-report.png", "Hình 5.6. Báo cáo doanh thu")]
    }
    for file_name, caption in figures.get(heading, []):
        picture = ASSETS / file_name
        if picture.exists():
            paragraph = doc.add_paragraph()
            paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
            paragraph.add_run().add_picture(str(picture), width=Cm(14.5))
            caption_paragraph = doc.add_paragraph(caption)
            caption_paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
            caption_paragraph.runs[0].italic = True
    doc.add_heading("Phân tích và quyết định thiết kế",level=3)
    doc.add_paragraph(f"Đối với nội dung {heading.lower()}, nhóm ưu tiên tính nhất quán dữ liệu và khả năng chứng minh trực tiếp trên SQL Server. {detail} Quyết định được phản ánh đồng thời trong schema, stored procedure, repository và giao diện, tránh để business rule chỉ tồn tại ở một tầng dễ bị bỏ qua.")
    doc.add_paragraph("Các thao tác ghi sử dụng tham số có kiểu rõ ràng, không ghép chuỗi SQL. Ràng buộc khai báo chặn dữ liệu sai ở lớp cuối; procedure trả lỗi nghiệp vụ cụ thể; ứng dụng kiểm tra đầu vào và hiển thị thông báo an toàn. Mọi giá trị tiền tệ dùng decimal(18,2), thời điểm audit lưu UTC và lịch lớp dùng giờ Việt Nam theo contract.")
    doc.add_heading("Cài đặt và luồng dữ liệu",level=3)
    doc.add_paragraph("Yêu cầu từ Razor form đi qua action có authorization và anti-forgery, sau đó repository mở SqlConnection và gọi stored procedure. Procedure dùng SET NOCOUNT ON; thao tác nhiều bảng dùng SET XACT_ABORT ON, BEGIN TRY, BEGIN TRANSACTION, COMMIT và CATCH rollback. Kết quả đọc được ánh xạ sang view model có kiểu thay vì dynamic.")
    doc.add_paragraph("Database không phụ thuộc tên cố định: runner truyền DatabaseName bằng SQLCMD variable. Bộ cài tạo schema trước, function trước trigger/procedure có phụ thuộc, cấp quyền sau khi object tồn tại, seed idempotent rồi chạy smoke test. Cách sắp xếp này cho phép giảng viên dựng lại toàn bộ hệ thống trên database rỗng bằng một lệnh.")
    doc.add_heading("Kiểm thử và liên hệ rubric",level=3)
    doc.add_paragraph("Nội dung được kiểm tra ở mức phù hợp: CHECK/FK cho cấu trúc, smoke test T-SQL cho transaction và rollback, xUnit cho validation/xác thực, HTTP smoke test cho routing và đăng nhập thật. Các số liệu catalog và bằng chứng thực nghiệm được tổng hợp tại docs/TEST_EVIDENCE.md.")
    doc.add_paragraph("Phần này đóng góp trực tiếp vào các tiêu chí thiết kế, lập trình database, transaction–security hoặc ứng dụng của rubric DBMS330284. Nhóm chỉ đánh dấu gate sau khi chạy lại trên database sạch và có kết quả tái tạo được, không dựa vào số lượng file hay mô tả dự kiến.")

doc.add_page_break(); doc.add_heading("TÀI LIỆU THAM KHẢO",level=1)
for ref in [
    "Microsoft Learn. SQL Server Database Engine, Transact-SQL, locking, indexes và security documentation.",
    "Microsoft Learn. ASP.NET Core MVC, authentication, authorization và configuration documentation.",
    "Microsoft Learn. Microsoft.Data.SqlClient API documentation.",
    "OWASP. Authentication Cheat Sheet và SQL Injection Prevention Cheat Sheet.",
    "ABC Glofox. Gym management software capability overview.",
    "Rubric DBMS330284 do giảng viên cung cấp."
]: doc.add_paragraph(ref,style="List Number")

doc.add_page_break(); doc.add_heading("PHỤ LỤC A. KẾT QUẢ KIỂM THỬ",level=1)
evidence=[["Tables","15"],["Trusted CHECK","43"],["Triggers","6"],["Views","9"],["Non-PK indexes","20"],["Procedures","42"],["Functions","9"],["Transactional procedures","16"],["Roles","5"]]
t=doc.add_table(rows=1,cols=2); t.style="Table Grid"; set_cell_text(t.rows[0].cells[0],"Hạng mục");set_cell_text(t.rows[0].cells[1],"Kết quả")
for a,b in evidence:
    cells=t.add_row().cells;set_cell_text(cells[0],a);set_cell_text(cells[1],b)
doc.add_paragraph("Concurrency: kết nối B chờ 4.835 giây; kết quả 1 CONFIRMED và 1 WAITLISTED. Index benchmark mới nhất: logical reads LichLop giảm 16 xuống 6 (62,5%).")

doc.add_page_break(); doc.add_heading("PHỤ LỤC B. HƯỚNG DẪN DEMO",level=1)
for step in ["Chạy database/run-database.ps1 với -DropExisting trên database demo.","Cấu hình ConnectionStrings:GymDb bằng User Secrets.","Đăng nhập bốn tài khoản và minh họa menu theo role.","Tạo hội viên, mua gói, trả một phần rồi trả đủ.","Tạo lịch, đặt hai hội viên vào lớp một chỗ để minh họa hàng chờ.","Check-in và mở dashboard/báo cáo.","Chạy security, concurrency và index scripts."]:
    doc.add_paragraph(step,style="List Number")

report_path=OUT/"HeThongQuanLyPhongGym_Report.docx"
doc.core_properties.title="Hệ thống quản lý phòng gym"
doc.core_properties.subject="Đồ án DBMS330284"
doc.core_properties.author="DBMS330284 Project"
doc.save(report_path)
print(report_path)
