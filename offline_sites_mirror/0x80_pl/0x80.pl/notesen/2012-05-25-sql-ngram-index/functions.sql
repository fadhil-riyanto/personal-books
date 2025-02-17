CREATE TABLE data (
	id		serial PRIMARY KEY,
	text	varchar(64)
);

CREATE TABLE index_3grams (
	ngram	varchar(3) PRIMARY KEY,
	count	integer NOT NULL,
	ids		integer[]
);

CREATE TABLE index_4grams (
	ngram	varchar(4) PRIMARY KEY,
	count	integer NOT NULL,
	ids		integer[]
);

-- return all 3-grams
CREATE OR REPLACE FUNCTION get_3grams(s text)
	RETURNS SETOF varchar(4)
	LANGUAGE "plpgsql"
	STRICT IMMUTABLE
AS $$
	BEGIN
		FOR i IN 1 .. length(s) - 2 LOOP
			RETURN NEXT substr(s, i, 3);
		END LOOP;
	END;
$$;

-- return all 4-grams
CREATE OR REPLACE FUNCTION get_4grams(s text)
	RETURNS SETOF varchar(4)
	LANGUAGE "plpgsql"
	STRICT IMMUTABLE
AS $$
	BEGIN
		FOR i IN 1 .. length(s) - 3 LOOP
			RETURN NEXT substr(s, i, 4);
		END LOOP;
	END;
$$;

-- fill 3-grams index
CREATE OR REPLACE FUNCTION create_3grams_index()
	RETURNS VOID
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		rec		data%ROWTYPE;
		tmp		char(3);
	BEGIN
		CREATE TABLE tmp3grams_index (
			id		integer NOT NULL,
			ngram	char(3) NOT NULL
		);

		RAISE NOTICE 'step 1';
		-- fill temporary table
		FOR rec IN (SELECT * FROM data) LOOP
			FOR tmp IN SELECT get_3grams(rec.text) LOOP
				INSERT INTO tmp3grams_index (id, ngram)
				     VALUES (rec.id, tmp);
			END LOOP;
		END LOOP;

		RAISE NOTICE 'step 2';
		-- feed index
		TRUNCATE index_3grams;
		INSERT INTO index_3grams (
			SELECT ngram, COUNT(id) AS count, array_agg(id) AS ids
			  FROM tmp3grams_index
			GROUP BY ngram
		);

		DROP TABLE tmp3grams_index;
	END;
$$;

-- fill 4-grams index
CREATE OR REPLACE FUNCTION create_4grams_index()
	RETURNS VOID
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		rec		data%ROWTYPE;
		tmp		char(4);
	BEGIN
		CREATE TABLE tmp4grams_index (
			id		integer NOT NULL,
			ngram	char(4) NOT NULL
		);

		RAISE NOTICE 'step 1';
		-- fill temporary table
		FOR rec IN (SELECT * FROM data) LOOP
			FOR tmp IN SELECT get_4grams(rec.text) LOOP
				INSERT INTO tmp4grams_index (id, ngram)
				     VALUES (rec.id, tmp);
			END LOOP;
		END LOOP;

		RAISE NOTICE 'step 2';
		-- feed index
		TRUNCATE index_4grams;
		INSERT INTO index_4grams (
			SELECT ngram, COUNT(id) AS count, array_agg(id) AS ids
			  FROM tmp4grams_index
			GROUP BY ngram
		);

		DROP TABLE tmp4grams_index;
	END;
$$;

-- search using 3-grams
CREATE OR REPLACE FUNCTION search_with_3grams(word text)
	RETURNS SETOF data
	STABLE
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		tgm text[] := (SELECT array_agg(gram) FROM get_3grams(word) AS gram);
		cond text[];
		query text := '';
		subquery text := '';
		ngram char(3);
		n integer;
		k integer;
	BEGIN
		n := array_upper(tgm, 1);
		IF n IS NULL THEN
			RETURN;
		END IF;

		FOR i in 1 .. n LOOP
			cond := cond || ('ngram = ''' || tgm[i] || '''');
		END LOOP;

		EXECUTE 'SELECT COUNT(*) FROM index_3grams WHERE ' || array_to_string(cond, ' OR ')
		   INTO k;

		IF k <> n THEN
			RETURN;
		END IF;

		subquery :=
			'SELECT ids FROM index_3grams'
			' WHERE ' || array_to_string(cond, ' OR ') ||
			' ORDER BY count'
			' LIMIT 1'
		;

		EXECUTE
			'SELECT count, ngram FROM index_3grams'
			' WHERE ' || array_to_string(cond, ' OR ') ||
			' ORDER BY count'
			' LIMIT 1'
		INTO k, ngram;

		RAISE NOTICE '"%" = %', ngram, k;

		query :=
			'SELECT data.* FROM data '
			' WHERE id = ANY((' || subquery || ')::integer[])'
			  ' AND text LIKE ''%' || word || '%''';

		RETURN QUERY EXECUTE query;
	END;
$$;


-- search using 4-grams
CREATE OR REPLACE FUNCTION search_with_4grams(word text)
	RETURNS SETOF data
	STABLE
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		tgm text[] := (SELECT array_agg(gram) FROM get_4grams(word) AS gram);
		cond text[];
		query text := '';
		subquery text := '';
		n integer;
		k integer;
	BEGIN
		n := array_upper(tgm, 1);
		IF n IS NULL THEN
			RETURN;
		END IF;

		FOR i in 1 .. n LOOP
			cond := cond || ('ngram = ''' || tgm[i] || '''');
		END LOOP;

		EXECUTE 'SELECT COUNT(*) FROM index_4grams WHERE ' || array_to_string(cond, ' OR ')
		   INTO k;

		IF k <> n THEN
			RETURN;
		END IF;

		subquery :=
			'SELECT ids FROM index_4grams'
			' WHERE ' || array_to_string(cond, ' OR ') ||
			' ORDER BY count'
			' LIMIT 1'
		;

		query :=
			'SELECT data.* FROM data '
			' WHERE id = ANY((' || subquery || ')::integer[])'
			  ' AND text LIKE ''%' || word || '%''';

		RETURN QUERY EXECUTE query;
	END;
$$;

-- search wrapper
CREATE OR REPLACE FUNCTION search(word text)
	RETURNS SETOF data
	STABLE
	LANGUAGE "plpgsql"
AS $$
	BEGIN
		IF length(word) > 3 THEN
			RETURN QUERY SELECT * FROM search_with_4grams(word);
		ELSIF length(word) = 3 THEN
			RETURN QUERY SELECT * FROM search_with_3grams(word);
		ELSE
			RAISE EXCEPTION 'word is too short';
		END IF;
	END;
$$;
