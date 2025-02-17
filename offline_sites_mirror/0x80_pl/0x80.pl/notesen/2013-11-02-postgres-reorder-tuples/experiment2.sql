CREATE TABLE experiment2 (
	type 	text,
	d1		date,
	d2		date,
	time 	numeric(18, 3)
);


CREATE OR REPLACE FUNCTION run_experiment2()
	RETURNS void
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		tables	text[] := ARRAY['report_cache', 'report_cache_ordered'];
		names   text[] := ARRAY['cache', 'ordered'];
		d1		text[] := ARRAY['2011-01-01', '2011-01-01', '2011-01-01', '2011-01-01', '2011-01-01', '2011-01-01'];
		d2		text[] := ARRAY['2011-02-01', '2011-03-01', '2011-06-01', '2011-09-01', '2012-01-01', '2013-01-01'];

		time    numeric(18, 3);
		trials	integer := 5;
		query   text;
	BEGIN
		FOR t IN 1 .. 2 LOOP
			FOR j IN array_lower(d1, 1) .. array_upper(d1, 1) LOOP
				query  :=
					'SELECT
						idx1,
						COUNT(count1),
						COUNT(count2),
						COUNT(count3),
						COUNT(count4)
					 FROM ' || tables[t] || '
					 WHERE
						date BETWEEN ' || quote_literal(d1[j]) || ' AND ' || quote_literal(d2[j]) || '
					 GROUP BY idx1';

				FOR i IN 1 .. trials LOOP
					RAISE NOTICE '%/%: %', i, trials, query;
					time := timed_query(query);

					INSERT INTO experiment2 VALUES (
						names[t],
						d1[j]::date,
						d2[j]::date,
						time
					);
				END LOOP;
			END LOOP;
		END LOOP;
	END;
$$;


TRUNCATE experiment2;
SELECT run_experiment2();

SELECT
	cache.d1,
	cache.d2,
	cache.d2 - cache.d1 AS days,
	cache.type AS table,
	cache.time,
	ordered.type AS table,
	ordered.time,
	ROUND((cache.time - ordered.time)*100.0/ordered.time, 2) as speedup
FROM
	(SELECT type, d1, d2, min(time) AS time
	 FROM experiment2 WHERE type = 'cache' GROUP BY type, d1, d2) AS cache
JOIN
	(SELECT type, d1, d2, min(time) AS time
	 FROM experiment2 WHERE type = 'ordered' GROUP BY type, d1, d2) AS ordered
ON
	(cache.d1 = ordered.d1 and cache.d2 = ordered.d2)
ORDER BY
	d2, d1
