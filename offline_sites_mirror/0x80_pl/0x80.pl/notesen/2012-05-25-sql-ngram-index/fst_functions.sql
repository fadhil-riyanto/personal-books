CREATE TABLE titles (
	id		serial,
	title	text
);

CREATE OR REPLACE FUNCTION trigrams_array(word text)
	RETURNS text[]
	IMMUTABLE STRICT
	LANGUAGE "plpgsql"
AS $$
	DECLARE
		result text[];
	BEGIN
		FOR i IN 1 .. length(word) - 2 LOOP
			result := result || quote_literal(substr(lower(word), i, 3));
		END LOOP;

		RETURN result;
	END;
$$;

CREATE OR REPLACE FUNCTION trigrams_vector(text)
	RETURNS tsvector
	IMMUTABLE STRICT
	LANGUAGE "SQL"
AS $$
	SELECT array_to_string(trigrams_array($1), ' ')::tsvector;
$$;

CREATE OR REPLACE FUNCTION trigrams_query(text)
	RETURNS tsquery
	IMMUTABLE STRICT
	LANGUAGE "SQL"
AS $$
	SELECT array_to_string(trigrams_array($1), ' & ')::tsquery;
$$;

CREATE TABLE titles_gin (
	id		bigint,
	title	text
);

CREATE TABLE titles_gist (
	id		bigint,
	title	text
);

CREATE INDEX titles_trigrams_gin_idx ON titles_gin
	USING GIN(trigrams_vector(title))
;

CREATE INDEX titles_trigrams_gist_idx ON titles_gist
	USING GIST(trigrams_vector(title))
;

