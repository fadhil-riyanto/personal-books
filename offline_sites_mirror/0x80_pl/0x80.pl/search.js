"use strict";
// Model

const DOC_URL   = 0;
const DOC_TITLE = 1;
const DOC_TEXT  = 2;
const DEBUG_WEIGHTS = false;

class Document {
    constructor(doc_raw) {
        this.url   = doc_raw[DOC_URL];
        this.title = doc_raw[DOC_TITLE];
        this.title_lowercase = this.title.toLowerCase();

        this._text = doc_raw[DOC_TEXT];
        this._text_lowercase = undefined;
    }

    text() {
        return this._text;
    }

    text_lowercase() {
        if (this._text_lowercase == undefined) {
            const txt = this.text();
            this._text_lowercase = txt.toLowerCase();
        }

        return this._text_lowercase;
    }
}

function get_document(id) {
    let doc = DOCUMENTS[id];

    if (Array.isArray(doc)) {
        // lazy replace
        doc = new Document(doc);
        DOCUMENTS[id] = doc;
    }

    return doc;
}

class Query {
    constructor(words) {
        this.words = new Set();
        for (const word of words) {
            this.words.add(word.toLowerCase());
        }

        let trigrams = new Set();
        for (const word of this.words) {
            for (const trigram of get_trigrams(word)) {
                trigrams.add(trigram);
            }
        }

        this.documents = new Set();
        const has_intersection = (typeof this.documents.intersection !== 'undefined');
        let first = true;
        for (const trigram of trigrams) {
            const set = get_document_set(trigram)
            if (set == undefined) {
                this.documents = new Set();
                return;
            }

            if (first) {
                this.documents = set;
                first = false;
            } else {
                if (has_intersection) {
                    this.documents = this.documents.intersection(set);
                } else {
                    let tmp = new Set();
                    for (const el of this.documents) {
                        if (set.has(el)) {
                            tmp.add(el);
                        }
                    }
                    this.documents = tmp;
                }
            }
        }
    }
}

function get_document_set(trigram) {
    const set = TRIGRAMS[trigram];
    if (set == undefined) {
        return undefined;
    }

    if (Array.isArray(set)) {
        // perform lazy expansion
        let res = new Set();
        for (let item of set) {
            if (Array.isArray(item)) {
                const first = item[0];
                const last  = item[1];
                for (let i=first; i <= last; i++) {
                    res.add(i);
                }
            } else {
                res.add(item);
            }
        }

        TRIGRAMS[trigram] = res;
        return res;
    }

    return set;
}

function get_trigrams(s) {
    let res = [];
    for (let i=0; i < s.length - 2; i++) {
        res.push(s.substr(i, 3));
    }

    return res;
}

class Result {
    constructor(query) {
        this.query      = query;
        this.text_hits  = new Map();
        this.title_hits = new Map();

        for (const word of query.words) {
            this.text_hits.set(word, null);
            this.title_hits.set(word, null);
        }
    }

    weight() {
        const WORD_WEIGHT   = 1000;
        const TITLE_WEIGHT  = 10;
        const TEXT_WEIGHT   = 1;

        let not_seen_words = new Set(this.query.words);
        let words_count = not_seen_words.size;

        let text_hits = 0;
        for (const [word, hits] of this.text_hits) {
            if (hits != null) {
                text_hits += hits.size;
                not_seen_words.delete(word);
            }
        }

        let title_hits = 0;
        for (const [word, hits] of this.title_hits) {
            if (hits != null) {
                title_hits += hits.size;
                not_seen_words.delete(word);
            }
        }

        let word_hits = words_count - not_seen_words.size;

        return word_hits  * WORD_WEIGHT
             + text_hits  * TEXT_WEIGHT
             + title_hits * TITLE_WEIGHT;
    }
}

// Searching

function find_occurances(doc, query) {
    let res = new Result(query);
    const text  = doc.text_lowercase();
    const title = doc.title_lowercase;
    for (const word of query.words) {
        res.text_hits.set(word, find_positions(text, word));
        res.title_hits.set(word, find_positions(title, word));
    }

    return res;
}

function find_positions(text, str) {
    let res = new Set();
    let n = 0;

    while (text) {
        const pos = text.indexOf(str);
        if (pos < 0) {
            break;
        }

        res.add(n + pos);

        n += pos + 1;
        text = text.substr(pos + 1);
    }

    if (res.size == 0) {
        return null;
    }

    return res;
}

// View

class ViewOptions {
    constructor() {
        this.max_context_length = 30;   // chars
        this.max_contexes = 10;         // hits
    }
}

function display_result(results, all, query, view_options) {
    let p = document.createElement("p");
    p.innerText = "found " + all.length + " " + pluralize(all.length, "article");
    results.appendChild(p);

    let list = document.createElement("ol");
    results.appendChild(list);

    let link_options = new ViewOptions();
    link_options.max_context_length = 1024;
    link_options.max_length = 1024;

    let even = true;
    for (const result_item of all) {
        let li = document.createElement("li");
        if (even) {
            li.classList.add("even");
        } else {
            li.classList.add("odd");
        }
        even = !even;

        list.appendChild(li);

        const doc = result_item[1];
        const result = result_item[0];

        let link = document.createElement("a");
        link.setAttribute('href', doc.url);
        link.setAttribute('target', "blank");
        highlight(link, doc.title, result.title_hits, link_options);
        if (DEBUG_WEIGHTS) {
            link.innerHTML += " (" + result.weight() + ")";
        }

        li.appendChild(link)

        let item = document.createElement("p");
        highlight(item, doc.text(), result.text_hits, view_options);
        li.append(item)
    }
}

function pluralize(count, noun) {
    if (count == 0 || count > 1) {
        return noun + 's';
    }

    return noun;
}

function highlight(parent, text, matches, view_options) {
    function append_text(type, s) {
        if (s) {
            let e = document.createElement(type);
            e.innerText = s;
            parent.appendChild(e);
        }
    }

    const ranges = higlight_ranges(matches);
    const n = ranges.length;

    if (n == 0) {
        append_text("span", text);
        return;
    }

    const max_length = view_options.max_context_length;
    for (let i=0; i < n; i++) {
        const first = ranges[i][0];
        const last  = ranges[i][1];

        if (i == 0) {
            const s = get_text_on_left(text, first, max_length);
            append_text("span", s);
        }

        const highlight = text.substr(first, last - first + 1);
        append_text("b", highlight);

        if (i + 1 < n) {
            const next_range_start = ranges[i + 1][0];
            const s = get_text_between(text, last + 1, next_range_start, max_length);
            append_text("span", s);
        }

        if (i + 1 == n) {
            const s = get_text_on_right(text, last + 1, max_length);
            append_text("span", s);
        }

        if (i == view_options.max_contexes) {
            const rem = n - view_options.max_contexes;
            const s = '... and ' + rem + ' more match(es)';
            append_text("span", s);
            break;
        }
    }
}

function higlight_ranges(matches) {
    // 1. mark which positions should be highligted (there may be more matches hitting the same position)
    let active = new Set();
    for (const [word, set] of matches) {
        if (set == null) {
            continue;
        }

        const n = word.length;
        for (let pos of set) {
            for (let i=0; i < n; i++) {
                active.add(pos + i);
            }
        }
    }

    if (active.size == 0) {
        return [];
    }

    // 2. sort positions
    let tmp = [];
    for (const pos of active) {
        tmp.push(pos)
    }

    tmp.sort((a, b) => a - b);

    // 3. detect continous ranges
    return compress_ranges(tmp);
}

function compress_ranges(arr) {
    if (arr.length == 0) {
        return [];
    }

    let ranges = [];
    let first = arr[0];
    let last  = arr[0];

    for (let i=1; i < arr.length; i++) {
        if (last + 1 == arr[i]) {
            last += 1;
        } else {
            ranges.push([first, last]);
            first = last = arr[i];
        }
    }

    ranges.push([first, last]);

    return ranges;
}

const ellipsis = "[…]";

function get_text_on_left(text, pos, max_length) {
    if (pos < 0) {
        return '';
    }

    const first = pos - max_length;
    if (first >= 0) {
        return ellipsis + text.substr(first, max_length);
    } else {
        return text.substr(0, pos);
    }
}

function get_text_on_right(text, pos, max_length) {
    if (pos + max_length < text.length) {
        return text.substr(pos, max_length) + ' ' + ellipsis;
    } else {
        return text.substr(pos);
    }
}

function get_text_between(text, pos1, pos2, max_length) {
    if (pos2 - pos1 > max_length) {
        const n = max_length >> 1;
        const left  = text.substr(pos1, n);
        const right = text.substr(pos2 - n, n);

        return left + ' ' + ellipsis + ' ' + right;
    } else {
        return text.substr(pos1, pos2 - pos1);
    }
}

let l = console.log;
if (typeof document !== 'undefined') {
    document.addEventListener('DOMContentLoaded', function() {
        let input = document.getElementById("input");
        let results = document.getElementById("results");

        function search() {
            const phrase = input.value;
            const words = phrase.split(' ');

            const query = new Query(words)

            let documents = query.documents;
            if (documents.size == 0) {
                results.innerText = "no candidates found";
                return;
            }

            let all = [];
            for (const doc_id of documents) {
                const doc = get_document(doc_id);
                const matches = find_occurances(doc, query);
                if (matches.weight() > 0) {
                    all.push([matches, doc])
                }
            }

            all.sort((a, b) => b[0].weight() - a[0].weight());

            if (all.length > 0) {
                results.innerText = '';
                display_result(results, all, query, new ViewOptions())
            } else {
                results.innerText = "nothing found";
            }
        }

        document.getElementById("search").addEventListener("click", function() {
            search();
        });

        document.getElementById("clear").addEventListener("click", function() {
            results.innerText = '';
            input.value = '';
            input.focus();
        });

        input.addEventListener("keypress", function(event) {
            if (event.key === "Enter") {
                event.preventDefault();
                search();
            }
        });

        document.addEventListener("keypress", function(event) {
            if ((event.key === "S" || event.key === "s") && document.activeElement !== input) {
                event.preventDefault();
                input.focus();
            }
        });

        search();
    }, false);
}
