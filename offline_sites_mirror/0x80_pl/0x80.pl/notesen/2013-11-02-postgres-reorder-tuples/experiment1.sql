CREATE TABLE experiment1 (
	type 	text,
	lim		integer,
	ofs		integer,
	time 	numeric(18, 3)
);


CREATE OR REPLACE FUNCTION run_experiment1()
	RETURNS void
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		tables	text[] := ARRAY['report_cache', 'report_cache_ordered'];
		names   text[] := ARRAY['cache', 'ordered'];
		limits  INTEGER[] := ARRAY[100, 1000, 10000, 20000, 50000];
		offsets INTEGER[] := ARRAY[0, 100000, 200000];
		trials  INTEGER   := 5;

		lim     integer;
		ofs     integer;
		time    numeric(18, 3);
		query   text;
	BEGIN
		FOR t IN 1 .. 2 LOOP
		FOR j IN array_lower(limits, 1) .. array_upper(limits, 1) LOOP
			FOR k IN array_lower(offsets, 1) .. array_upper(offsets, 1) LOOP
				lim  := limits[j];
				ofs  := offsets[k];
				query  := 'SELECT * FROM ' || tables[t] || ' ORDER BY date LIMIT ' || lim || ' OFFSET ' || ofs;

				FOR i IN 1 .. trials LOOP
					RAISE NOTICE '%/%: %', i, trials, query;
					time := timed_query(query);

					INSERT INTO experiment1 VALUES (
						names[t],
						lim,
						ofs,
						time
					);
				END LOOP;
			END LOOP;
		END LOOP;
		END LOOP;
	END;
$$;


TRUNCATE experiment1;
SELECT run_experiment1();

SELECT
	cache.lim,
	cache.ofs,
	cache.type AS table,
	cache.time,
	ordered.type AS table,
	ordered.time,
	ROUND((cache.time - ordered.time)*100.0/ordered.time, 2) as speedup
FROM
	(SELECT type, lim, ofs, min(time) AS time
	 FROM experiment1 WHERE type = 'cache' GROUP BY type, lim, ofs) AS cache
JOIN
	(SELECT type, lim, ofs, min(time) AS time
	 FROM experiment1 WHERE type = 'ordered' GROUP BY type, lim, ofs) AS ordered
ON
	(cache.lim = ordered.lim and cache.ofs = ordered.ofs)
ORDER BY
	ofs, lim
