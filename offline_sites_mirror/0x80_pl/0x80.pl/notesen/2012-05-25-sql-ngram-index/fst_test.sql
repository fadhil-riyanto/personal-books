
CREATE OR REPLACE FUNCTION search_gin(phrase text, out n integer, out dt numeric(18,3))
	RETURNS RECORD
	STABLE
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		st timestamp;
		et timestamp;
	BEGIN
		st := clock_timestamp();
		n  := COUNT(*) FROM titles_gin WHERE trigrams_vector(title) @@ trigrams_query(phrase);
		et := clock_timestamp();

		dt := CAST(1000 * (extract(epoch from et) - extract(epoch from st)) AS numeric(18,3));
	END;
$$;

CREATE OR REPLACE FUNCTION search_gist(phrase text, out n integer, out dt numeric(18,3))
	RETURNS RECORD
	STABLE
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		st timestamp;
		et timestamp;
	BEGIN
		st := clock_timestamp();
		n  := COUNT(*) FROM titles_gist WHERE trigrams_vector(title) @@ trigrams_query(phrase);
		et := clock_timestamp();

		dt := CAST(1000 * (extract(epoch from et) - extract(epoch from st)) AS numeric(18,3));
	END;
$$;

CREATE TABLE search_phrases (phrase text);
DELETE FROM search_phrases;

INSERT INTO search_phrases VALUES
	('wonder'),
	('poland'),
	('alice in wonderland'),
	('the odyssey'),
	('world war'),
	('whatever'),
	('other stories'),
	('Shakespear'),
	('cats'),
	('meaning of life'),
	('begin'),
	('trees'),
	('build'),
	('writer'),
	('old man'),
	('sonnets'),
	('moon'),
	('razor'),
	('dog'),
	('eagle'),
	('scientific'),
	('scientific american'),
	('europe'),
	('seven'),
	('seven periods of english')
;

CREATE TABLE results (
	phrase text,
	idx    text,
	n      integer,
	dt     numeric(18,2)
);

CREATE OR REPLACE FUNCTION prepare_test_data()
	RETURNS VOID
	LANGUAGE "plpgsql"
AS $$
	BEGIN
		IF NOT (SELECT EXISTS (SELECT 1 FROM titles_gin)) THEN
			RAISE NOTICE 'feeding tables';
			INSERT INTO titles_gin (SELECT * FROM titles);
			INSERT INTO titles_gist (SELECT * FROM titles);
		END IF;
	END;
$$;

CREATE OR REPLACE FUNCTION test()
	RETURNS VOID
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		loops constant integer := 5;
	BEGIN
		TRUNCATE results;

		FOR i IN 1 .. loops LOOP
			RAISE NOTICE 'testing GIN %/%', i, loops;
			INSERT INTO results (
				SELECT phrase, 'gin', (search_gin(phrase)).* FROM search_phrases ORDER BY phrase
			);
		END LOOP;

		FOR i IN 1 .. loops LOOP
			RAISE NOTICE 'testing GIST %/%', i, loops;
			INSERT INTO results (
				SELECT phrase, 'gist', (search_gist(phrase)).* FROM search_phrases ORDER BY phrase
			);
		END LOOP;
	END;
$$;

SELECT prepare_test_data();
SELECT test();

SELECT
	gin.phrase,
	gin.dt AS gin_time,
	gist.dt AS gist_time
FROM
	(SELECT phrase, MIN(dt) AS dt FROM results WHERE idx = 'gin' GROUP BY phrase) AS gin
JOIN
	(SELECT phrase, MIN(dt) AS dt FROM results WHERE idx = 'gist' GROUP BY phrase) AS gist
USING (phrase)
ORDER BY phrase;
