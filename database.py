import pyodbc

def get_db_connection():
    conn = pyodbc.connect(
        r'DRIVER={SQL Server};'
        r'SERVER=localhost\SQLEXPRESS;'
        r'DATABASE=GymManagementDB;'  
        r'Trusted_connection=yes;'
    )
    return conn