CREATE TABLE article (
	artID INTEGER PRIMARY KEY AUTOINCREMENT,
	url TEXT NOT NULL,
	title TEXT
);
CREATE TABLE tag (
       tagID INTEGER PRIMARY KEY AUTOINCREMENT,
       tag TEXT NOT NULL
);
CREATE TABLE tagLinks (
       artID INTEGER NOT NULL REFERENCES article(artID),
       tagID INTEGER NOT NULL REFERENCES tag(tagID),
       PRIMARY KEY (artID,tagID)
);

-- Useless now ; created while parsing pearltrees.rdf

-- CREATE VIRTUAL TABLE webpage USING FTS3 (
--        pgcontent TEXT,
--        artID INTEGER NOT NULL REFERENCES article(artID)
-- );

.exit
