import pyodbc
import pandas as pd


def open_connection():
    conn = pyodbc.connect('Driver={SQL Server};'
                          'Server=aydess;'
                          'Database=MIX;'
                          'Trusted_Connection=yes;')
    return conn


def close_connection(conn):
    if conn != None:
        conn.close()


def custom_query(query):
    res = None
    try:
        conn = open_connection()
        res = pd.read_sql(query, conn)
    except:
        print('error occurred')
    finally:
        close_connection(conn)
        return res
