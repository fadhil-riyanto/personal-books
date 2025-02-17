CREATE TABLE report_cache (
	idx1 integer,
	idx2 integer,
	idx3 integer,
	date date,
	count1 integer,
	count2 integer,
	count3 integer,
	count4 integer
);

CREATE TABLE report_cache_ordered (LIKE report_cache);

CREATE INDEX idx_report_cache_date ON report_cache(date);
CREATE INDEX idx_report_cache_ordered_date ON report_cache_ordered(date);


CREATE OR REPLACE FUNCTION randint(integer, integer)
	RETURNS integer
	LANGUAGE "SQL"
	VOLATILE
AS $$
	SELECT floor($1 + ($2 - $1 + 1) * random())::integer;
$$;


CREATE OR REPLACE FUNCTION mkdate(y integer, m integer, d integer)
	RETURNS date
	LANGUAGE "plpgsql"
	IMMUTABLE
AS $$
	DECLARE
		ys text := y;
		ms text := m;
		ds text := d;
	BEGIN
		IF m < 10 THEN
			ms := '0' || ms;
		END IF;

		IF d < 10 THEN
			ds := '0' || ds;
		END IF;

		RETURN (ys || '-' || ms || '-' || ds)::date;
	END;
$$;


CREATE OR REPLACE FUNCTION randdate()
	RETURNS date
	LANGUAGE "SQL"
	VOLATILE
AS $$
	SELECT mkdate(
		randint(2011, 2013),
		randint(1, 12),
		randint(1, 28)
	);
$$;


CREATE OR REPLACE FUNCTION random_data(integer)
	RETURNS SETOF report_cache
	LANGUAGE "SQL"
AS $$
		SELECT
			randint(1, 100),
			randint(1, 1000),
			randint(1, 10000),
			randdate(),
			randint(1, 100),
			randint(1, 1000),
			randint(1, 10000),
			randint(1, 100000)
		FROM
			generate_series(1, $1) AS g;
$$;


CREATE OR REPLACE FUNCTION timed_query(query text)
	RETURNS numeric(18, 2)
	STABLE
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		st timestamp;
		et timestamp;
	BEGIN
		st := clock_timestamp();
		EXECUTE query;
		et := clock_timestamp();

		RETURN CAST(1000 * (extract(epoch from et) - extract(epoch from st)) AS numeric(18, 3));
	END;
$$;


CREATE OR REPLACE FUNCTION init()
	RETURNS void
	LANGUAGE "SQL"
AS $$
	TRUNCATE report_cache;
	INSERT INTO report_cache (SELECT * FROM random_data(1000000));

	TRUNCATE report_cache_ordered;
	INSERT INTO report_cache_ordered (
		SELECT * FROM report_cache ORDER BY date
	);
$$;
