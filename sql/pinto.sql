CREATE TABLE distribution (
       id      INTEGER PRIMARY KEY NOT NULL,
       path    TEXT                NOT NULL,
       source  TEXT                NOT NULL,
       mtime   INTEGER             NOT NULL,
       md5     TEXT                NOT NULL,
       sha256  TEXT                NOT NULL
);


CREATE TABLE package (
       id            INTEGER PRIMARY KEY NOT NULL,
       name          TEXT                NOT NULL,
       version       TEXT                NOT NULL,
       distribution  INTEGER             NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(id)
);


CREATE TABLE stack (
       id          INTEGER PRIMARY KEY NOT NULL,
       name        TEXT                NOT NULL,
       mtime       INTEGER             NOT NULL,
       description TEXT                DEFAULT NULL 
);


create TABLE pin (
       id         INTEGER PRIMARY KEY NOT NULL,
       reason     TEXT                NOT NULL
);


create TABLE package_stack (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       package      INTEGER             NOT NULL,
       pin          INTEGER             DEFAULT NULL,
       FOREIGN KEY(stack)   REFERENCES stack(id),
       FOREIGN KEY(package) REFERENCES package(id),
       FOREIGN KEY(pin)     REFERENCES pin(id)
);


CREATE TABLE revision (
       id          INTEGER PRIMARY KEY NOT NULL,
       message     TEXT                NOT NULL,
       username    TEXT                NOT NULL,
       ctime       INTEGER             NOT NULL
);


CREATE TABLE package_stack_history (
       id                  INTEGER PRIMARY KEY NOT NULL,
       stack               INTEGER             NOT NULL,
       package             INTEGER             NOT NULL,
       pin                 INTEGER             DEFAULT NULL,
       created_revision    INTEGER             NOT NULL,
       deleted_revision    INTEGER             DEFAULT NULL,
       FOREIGN KEY(stack)             REFERENCES stack(id),
       FOREIGN KEY(package)           REFERENCES package(id),
       FOREIGN KEY(pin)               REFERENCES pin(id),
       FOREIGN KEY(created_revision)  REFERENCES revision(id),
       FOREIGN KEY(deleted_revision)  REFERENCES revision(id)
);

/*
CREATE TABLE dependency (
       id           INTEGER PRIMARY KEY NOT NULL,
       distribution INTEGER             NOT NULL,
       prerequisite TEXT                NOT NULL,
       version      TEXT                NOT NULL,
       stage        TEXT                DEFAULT NULL,  
       FOREIGN KEY(distribution)  REFERENCES distribution(id),
);
*/

CREATE UNIQUE INDEX distribution_idx      ON distribution(path);
CREATE UNIQUE INDEX package_idx           ON package(name, distribution);
CREATE UNIQUE INDEX stack_name_idx        ON stack(name);
CREATE        INDEX package_name_idx      ON package(name);
