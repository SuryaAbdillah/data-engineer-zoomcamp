-- During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, **respectively**, happened:

ALTER TABLE green_taxi_trips
ALTER COLUMN lpep_pickup_datetime TYPE TIMESTAMP USING lpep_pickup_datetime::TIMESTAMP,
ALTER COLUMN lpep_dropoff_datetime TYPE TIMESTAMP USING lpep_dropoff_datetime::TIMESTAMP;

-- 1. Up to 1 mile
SELECT COUNT(*)
FROM green_taxi_trips
WHERE DATE(lpep_dropoff_datetime) >= '2019-10-01'
	AND DATE(lpep_dropoff_datetime) < '2019-11-01'
	AND trip_distance <= 1;
	
-- 2. In between 1 (exclusive) and 3 miles (inclusive),
SELECT COUNT(*)
FROM green_taxi_trips
WHERE DATE(lpep_dropoff_datetime) >= '2019-10-01'
	AND DATE(lpep_dropoff_datetime) < '2019-11-01'
	AND trip_distance > 1
	AND trip_distance <= 3;
	
-- 3. In between 3 (exclusive) and 7 miles (inclusive),
SELECT COUNT(*)
FROM green_taxi_trips
WHERE DATE(lpep_dropoff_datetime) >= '2019-10-01'
	AND DATE(lpep_dropoff_datetime) < '2019-11-01'
	AND trip_distance > 3
	AND trip_distance <= 7;
	
-- 4. In between 7 (exclusive) and 10 miles (inclusive),
SELECT COUNT(*)
FROM green_taxi_trips
WHERE DATE(lpep_dropoff_datetime) >= '2019-10-01'
	AND DATE(lpep_dropoff_datetime) < '2019-11-01'
	AND trip_distance > 7
	AND trip_distance <= 10;
	
-- 5. Over 10 miles 
SELECT COUNT(*)
FROM green_taxi_trips
WHERE DATE(lpep_dropoff_datetime) >= '2019-10-01'
	AND DATE(lpep_dropoff_datetime) < '2019-11-01'
	AND trip_distance > 10;

-- Which was the pick up day with the longest trip distance?
-- Use the pick up time for your calculations.
-- Tip: For every day, we only care about one single trip with the longest distance. 
SELECT DATE(green_taxi_trips."lpep_pickup_datetime")
FROM green_taxi_trips
ORDER BY trip_distance DESC
LIMIT 1;

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
