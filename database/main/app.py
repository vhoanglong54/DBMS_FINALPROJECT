from flask import Flask, render_template
from controllers.membership import membership_bp

app = Flask(__name__, template_folder='templates', static_folder='static')

# Đăng ký Blueprint của TV2 vào ứng dụng chung
app.register_blueprint(membership_bp)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True, port=5000)