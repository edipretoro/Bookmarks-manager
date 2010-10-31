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

-- Useless now ; created while parsing pearltrees_export.rdf

-- CREATE VIRTUAL TABLE artContent USING FTS3 (
--        contID INTEGER PRIMARY KEY AUTOINCREMENT,
--        content TEXT,
--        artID INTEGER NOT NULL REFERENCES article(artID)
-- );

.exit
