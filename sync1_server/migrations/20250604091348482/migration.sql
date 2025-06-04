BEGIN;


--
-- MIGRATION VERSION FOR sync1
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('sync1', '20250604091348482', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250604091348482', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
