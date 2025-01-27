import pandas as pd
import argparse
from sqlalchemy import create_engine
import os

def main(params):
    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    table_name = params.table_name
    url = params.url

    # dataset_name = "output.parquet"
    dataset_name = "output.csv"

    os.system(f"curl -L -o {dataset_name} {url}")

    engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{db}")
    engine.connect()

    # df = pd.read_parquet(dataset_name)
    # df.to_csv("output.csv", index=False)

    # NEW CODE
    df = pd.read_csv(dataset_name)

    df.head(n=0).to_sql(name=table_name, con=engine, if_exists='replace')
    
    df_iter = pd.read_csv(dataset_name, iterator=True, chunksize=100_000)

    # df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
    # df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)

    try:
        while True:
            df = next(df_iter)

            # df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            # df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)

            df.to_sql(name=table_name, con=engine, if_exists='append')
    except StopIteration:
        print("All data has been ingested.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ingest CSV data to Postgres')

    parser.add_argument('--user', help="username for postgres")    
    parser.add_argument('--password', help="password for postgres")
    parser.add_argument('--host', help="host for postgres")
    parser.add_argument('--port', help="port for postgres")
    parser.add_argument('--db', help="database name for postgres")
    parser.add_argument('--table_name', help="name of the table where we will write the results to")
    parser.add_argument('--url', help="url of the csv file")

    args = parser.parse_args()
    main(args)