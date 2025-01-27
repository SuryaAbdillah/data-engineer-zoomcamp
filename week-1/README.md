## Question 1. Understanding docker first run
Run docker with the python:3.12.8 image in an interactive mode, use the entrypoint bash.

What's the version of pip in the image?

- 24.3.1
- 24.2.1
- 23.3.1
- 23.2.1

**Answer: 24.3.1** 
We can try by running this docker command. This command will trigger the system to pull the specified version of python library.
```yaml
docker run -it --entrypoint bash python:3.12.8
```

after that, we can print the pip version:
```yaml
pip --version
```

![Image](https://github.com/user-attachments/assets/ef9ab409-f3d3-4f51-9ba1-406acb2e96f4)

## Question 2. Understanding Docker networking and docker-compose

Given the following `docker-compose.yaml`, what is the `hostname` and `port` that **pgadmin** should use to connect to the postgres database?

```yaml
services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: 'postgres'
      POSTGRES_PASSWORD: 'postgres'
      POSTGRES_DB: 'ny_taxi'
    ports:
      - '5433:5432'
    volumes:
      - vol-pgdata:/var/lib/postgresql/data

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
      PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
      - "8080:80"
    volumes:
      - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
  vol-pgdata:
    name: vol-pgdata
  vol-pgadmin_data:
    name: vol-pgadmin_data
```

- postgres:5433
- localhost:5432
- db:5433
- postgres:5432
- db:5432

**Answer: db:5432**

- hostname: db
- internal network port: 5432

## PREPARE POSTGRES

**I use the previous code to store the database**

this is my previous command:

```yaml
URL="http://172.30.32.1:8000/dataset/yellow_tripdata_2021-01.parquet"

python ingest_data.py \
    --user=postgres \
    --password=root \
    --host=pg-database \
    --port=5432 \
    --db=ny_taxi \
    --table_name=yellow_taxi_trips \
    --url=${URL}
```

**GREEN TAXI TRIPS, OCT 2019**

**Download dataset**
I manually run curl command and unzip the zip file.
```yaml
curl -L -o "dataset/green_tripdata_2019-10.csv.gz" https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
```

**Ingest data to postgres**

modify ingest_data.py with change `read_paquet` to `read_csv`

```yaml
URL="http://172.30.32.1:8000/dataset/green_tripdata_2019-10.csv/green_tripdata_2019-10.csv"

python ingest_data.py \
    --user=postgres \
    --password=root \
    --host=pg-database \
    --port=5432 \
    --db=ny_taxi \
    --table_name=green_taxi_trips \
    --url=${URL}
```

**TAXI ZONE LOOKUP**

**Download dataset**
I manually run curl command.
```yaml
curl -L -o "dataset/taxi_zone_lookup.csv" https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

**Ingest data to postgres**

```yaml
URL="http://172.30.32.1:8000/dataset/taxi_zone_lookup.csv"

python ingest_data.py \
    --user=postgres \
    --password=root \
    --host=pg-database \
    --port=5432 \
    --db=ny_taxi \
    --table_name=taxi_zone_lookup \
    --url=${URL}
```

since my current environment takes input in `.parquet` format, I need to modify my code to determine the correct format.

## Question 3. Trip Segmentation Count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
1. Up to 1 mile
2. In between 1 (exclusive) and 3 miles (inclusive),
3. In between 3 (exclusive) and 7 miles (inclusive),
4. In between 7 (exclusive) and 10 miles (inclusive),
5. Over 10 miles 

Answers:

- 104,802;  197,670;  110,612;  27,831;  35,281
- 104,802;  198,924;  109,603;  27,678;  35,189
- 104,793;  201,407;  110,612;  27,831;  35,281
- 104,793;  202,661;  109,603;  27,678;  35,189
- 104,838;  199,013;  109,645;  27,688;  35,202

**Answer: 104,802; 198,924; 109603; 27,678; 35,189**

```sql
-- During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:
ALTER TABLE
    green_taxi_trips
ALTER COLUMN
    lpep_pickup_datetime TYPE TIMESTAMP USING lpep_pickup_datetime :: TIMESTAMP,
ALTER COLUMN
    lpep_dropoff_datetime TYPE TIMESTAMP USING lpep_dropoff_datetime :: TIMESTAMP;

-- 1. Up to 1 mile
SELECT
    COUNT(*)
FROM
    green_taxi_trips
WHERE
    DATE(lpep_dropoff_datetime) >= '2019-10-01'
    AND DATE(lpep_dropoff_datetime) < '2019-11-01'
    AND trip_distance <= 1;

-- 2. In between 1 (exclusive) and 3 miles (inclusive),
SELECT
    COUNT(*)
FROM
    green_taxi_trips
WHERE
    DATE(lpep_dropoff_datetime) >= '2019-10-01'
    AND DATE(lpep_dropoff_datetime) < '2019-11-01'
    AND trip_distance > 1
    AND trip_distance <= 3;

-- 3. In between 3 (exclusive) and 7 miles (inclusive),
SELECT
    COUNT(*)
FROM
    green_taxi_trips
WHERE
    DATE(lpep_dropoff_datetime) >= '2019-10-01'
    AND DATE(lpep_dropoff_datetime) < '2019-11-01'
    AND trip_distance > 3
    AND trip_distance <= 7;

-- 4. In between 7 (exclusive) and 10 miles (inclusive),
SELECT
    COUNT(*)
FROM
    green_taxi_trips
WHERE
    DATE(lpep_dropoff_datetime) >= '2019-10-01'
    AND DATE(lpep_dropoff_datetime) < '2019-11-01'
    AND trip_distance > 7
    AND trip_distance <= 10;

-- 5. Over 10 miles 
SELECT
    COUNT(*)
FROM
    green_taxi_trips
WHERE
    DATE(lpep_dropoff_datetime) >= '2019-10-01'
    AND DATE(lpep_dropoff_datetime) < '2019-11-01'
    AND trip_distance > 10;
```

## Question 4. Longest trip for each day

Which was the pick up day with the longest trip distance?
Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance. 

- 2019-10-11
- 2019-10-24
- 2019-10-26
- 2019-10-31

**Answer: 2019-10-31, with index 386795**

```sql
-- Which was the pick up day with the longest trip distance?
-- Use the pick up time for your calculations.
-- Tip: For every day, we only care about one single trip with the longest distance.

SELECT DATE(green_taxi_trips."lpep_pickup_datetime")
FROM green_taxi_trips
ORDER BY trip_distance DESC
LIMIT 1;
```

![Image](https://github.com/user-attachments/assets/cc790df1-999d-4cd7-8252-b037a7a38a08)

## Question 5. Three biggest pickup zones

Which were the top pickup locations with over 13,000 in
`total_amount` (across all trips) for 2019-10-18?

Consider only `lpep_pickup_datetime` when filtering by date.
 
- East Harlem North, East Harlem South, Morningside Heights
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park

**Answer: East Harlem North, East Harlem South, Morningside Heights**

```sql
-- Which were the top pickup locations with over 13,000 in
-- `total_amount` (across all trips) for 2019-10-18?
-- Consider only `lpep_pickup_datetime` when filtering by date.
SELECT temp_a."PULocationID", tzl."Zone", temp_a."final_total_amount"
FROM (
	SELECT gtt."PULocationID", SUM(gtt."total_amount") AS "final_total_amount"
	FROM green_taxi_trips gtt 
	WHERE DATE(gtt."lpep_pickup_datetime") = '2019-10-18'
	GROUP BY gtt."PULocationID"
	HAVING SUM(gtt."total_amount") > 13000
	ORDER BY "final_total_amount" DESC
	) temp_a
JOIN taxi_zone_lookup tzl
	ON temp_a."PULocationID" = tzl."LocationID";
```

![Image](https://github.com/user-attachments/assets/69f7b31b-e478-44b9-b985-f4940711e0ce)

## Question 6. Largest tip

For the passengers picked up in October 2019 in the zone
named "East Harlem North" which was the drop off zone that had
the largest tip?

Note: it's `tip` , not `trip`

We need the name of the zone, not the ID.

- Yorkville West
- JFK Airport
- East Harlem North
- East Harlem South

**Answer: JFK Airport**

```sql
-- For the passengers picked up in October 2019 in the zone
-- named "East Harlem North" which was the drop off zone that had
-- the largest tip?
-- Note: it's `tip` , not `trip`
-- We need the name of the zone, not the ID.
SELECT tzl."Zone", temp_a.*
FROM (
	SELECT gtt."DOLocationID", gtt."tip_amount"
	FROM green_taxi_trips gtt
	WHERE gtt."PULocationID" = (
		SELECT "LocationID"
		FROM taxi_zone_lookup
		WHERE "Zone" = 'East Harlem North'
	)
		AND EXTRACT(YEAR FROM gtt."lpep_pickup_datetime") = 2019
		AND EXTRACT(MONTH FROM gtt."lpep_pickup_datetime") = 10
	ORDER BY gtt."tip_amount" DESC
	LIMIT 1
) temp_a
JOIN taxi_zone_lookup tzl
	ON temp_a."DOLocationID" = tzl."LocationID";
```

![Image](https://github.com/user-attachments/assets/f53ac2df-0fca-4d58-9ddc-d18b3c41c5af)

## Question 7. Terraform Workflow

Which of the following sequences, **respectively**, describes the workflow for: 
1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:
- terraform import, terraform apply -y, terraform destroy
- teraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- terraform init, terraform apply -auto-approve, terraform destroy
- terraform import, terraform apply -y, terraform rm

**Answer: terraform init, terraform apply -auto-approve, terraform destroy**
