# ---------------------------------------------------------------
# UPI Payment Intelligence — Database Setup
# Connects to PostgreSQL and loads all 4 clean tables
# ---------------------------------------------------------------


import pandas as pd
from sqlalchemy import create_engine

# ── Step 1: Create connection to PostgreSQL ──
engine = create_engine('postgresql://postgres:YOUR_PASSWORD@localhost:5432/upi_intelligence')

with engine.connect() as conn:
        print("Connected to PostgreSQL successfully")


# ── Step 2: Load clean CSVs ──
transactions = pd.read_csv('data/clean/transactions_clean.csv')
users = pd.read_csv('data/clean/users_clean.csv')
merchants = pd.read_csv('data/clean/merchants_clean.csv')
fraud_labels = pd.read_csv('data/clean/fraud_labels_clean.csv')

print("✅ Clean CSVs loaded successfully")

transactions.to_sql('transactions', engine, if_exists='replace', index=False)
print("✅ transactions table loaded — 20,000 rows")

users.to_sql('users', engine, if_exists='replace', index=False)
print("✅ users table loaded — 2,000 rows")

merchants.to_sql('merchants', engine, if_exists='replace', index=False)
print("✅ merchants table loaded — 400 rows")

fraud_labels.to_sql('fraud_labels', engine, if_exists='replace', index=False)
print("✅ fraud_labels table loaded — 20,000 rows")

print("Database: upi_intelligence is ready for SQL analysis")


from sqlalchemy import text

with engine.connect() as conn:
    for table in ['transactions', 'users', 'merchants', 'fraud_labels']:
        result = conn.execute(text(f'SELECT COUNT(*) FROM {table}'))
        count = result.fetchone()[0]
        print(f"{table}: {count} rows")