-- =====================================================================
-- 02_insert_data.sql
-- Competitive CS2 Database (Team Stardust)
-- Giovanni Castro, Jaxon Constanzo, Noah Garcia, David Rendon
--
-- Purpose: Populates every table created by 01_create_schema.sql with
--          sample data drawn from the 2025 professional CS2 season.
-- Run after: 01_create_schema.sql
--
-- What is real:
--   * Teams, player in-game names and real names, and active rosters
--   * Valve global ranking (VRS) of 2025-07-02
--   * Tournaments, prize pools, playoff entrants and final placements
--   * Every playoff series of the BLAST.tv Austin Major 2025 and IEM
--     Cologne 2025: matchups, dates, format, map picks in order, map
--     winners and series winners
-- What is approximate or generated:
--   * Some team foundation dates and player start dates (month/year level)
--   * Per-player kills / deaths / assists (generated to fit each map's
--     real round count and result; not official scoreboards)
--
-- Load order follows the foreign keys (parents before children):
--   teams, maps, tournaments -> players, tournament_entrants
--   -> playoff_series -> matches -> player_match_stats
-- Explicit IDs are used so the foreign-key values below are easy to read.
-- =====================================================================

USE cs2_competitive;

-- ---------------------------------------------------------------------
-- 1. teams
-- Top 17 of the Valve global ranking (VRS) published 2025-07-02, so
-- valve_ranking holds real values 1-17. Eternal Fire was outside the
-- top 30 that week and is stored as unranked (NULL).
-- foundation_date is approximate for some organizations.
-- ---------------------------------------------------------------------
INSERT INTO teams (team_id, team_name, foundation_date, valve_ranking) VALUES
    (1, 'Team Vitality', '2013-08-05', 1),
    (2, 'MOUZ', '2002-01-01', 2),
    (3, 'Team Spirit', '2015-12-01', 3),
    (4, 'The MongolZ', '2020-01-01', 4),
    (5, 'Team Falcons', '2017-01-01', 5),
    (6, 'Aurora Gaming', '2023-01-01', 6),
    (7, 'Natus Vincere', '2009-12-17', 7),
    (8, 'FaZe Clan', '2010-05-30', 8),
    (9, 'FURIA Esports', '2017-08-01', 9),
    (10, 'G2 Esports', '2014-02-24', 10),
    (11, 'GamerLegion', '2020-01-01', 11),
    (12, 'HEROIC', '2016-01-01', 12),
    (13, '3DMAX', '2016-01-01', 13),
    (14, 'Astralis', '2016-01-19', 14),
    (15, 'Virtus.pro', '2003-01-01', 15),
    (16, 'paiN Gaming', '2010-03-01', 16),
    (17, 'Team Liquid', '2000-01-01', 17),
    (18, 'Eternal Fire', '2021-01-01', NULL);

-- ---------------------------------------------------------------------
-- 2. maps
-- Every defuse/hostage map shipped in CS2. creation_date = date the map
-- was added to CS2 (launch 2023-09-27; Train returned 2024-11-13).
-- Overpass, Vertigo, Office and Italy have no matches in this data,
-- which shows a map can exist without being played.
-- ---------------------------------------------------------------------
INSERT INTO maps (map_id, name, creation_date) VALUES
    (1, 'Ancient', '2023-09-27'),
    (2, 'Anubis', '2023-09-27'),
    (3, 'Dust II', '2023-09-27'),
    (4, 'Inferno', '2023-09-27'),
    (5, 'Mirage', '2023-09-27'),
    (6, 'Nuke', '2023-09-27'),
    (7, 'Overpass', '2023-09-27'),
    (8, 'Vertigo', '2023-09-27'),
    (9, 'Office', '2023-09-27'),
    (10, 'Italy', '2023-09-27'),
    (11, 'Train', '2024-11-13');

-- ---------------------------------------------------------------------
-- 3. tournaments
-- Budapest Major is entered with no teams or series yet, which shows a
-- tournament can be created before its field and bracket.
-- ---------------------------------------------------------------------
INSERT INTO tournaments (tournament_id, tournament_name, tournament_year, tournament_type, prize_pool) VALUES
    (1, 'IEM Katowice', 2025, 'Premier', 1000000),
    (2, 'BLAST.tv Austin Major', 2025, 'Major', 1250000),
    (3, 'IEM Cologne', 2025, 'Premier', 1000000),
    (4, 'StarLadder Budapest Major', 2025, 'Major', 1250000);

-- ---------------------------------------------------------------------
-- 4. players
-- Active rosters at the BLAST.tv Austin Major (June 2025).
-- start_date = approximate date the player joined their current team.
-- team_ids 5, 6, 10-15, 17 and 18 have no players loaded yet,
-- which the schema allows (a team can exist before its roster).
-- ---------------------------------------------------------------------
INSERT INTO players (player_id, team_id, first_name, last_name, ign, start_date) VALUES
    (1, 1, 'Dan', 'Madesclaire', 'apEX', '2018-10-01'),
    (2, 1, 'Mathieu', 'Herbaut', 'ZywOo', '2018-10-01'),
    (3, 1, 'Shahar', 'Shushan', 'flameZ', '2024-01-01'),
    (4, 1, 'William', 'Merriman', 'mezii', '2024-01-01'),
    (5, 1, 'Robin', 'Kool', 'ropz', '2025-01-01'),
    (6, 2, 'Ludvig', 'Brolin', 'Brollan', '2023-09-01'),
    (7, 2, 'Lotan', 'Giladi', 'Spinx', '2024-01-01'),
    (8, 2, 'Dorian', 'Berman', 'xertioN', '2021-07-01'),
    (9, 2, 'Jimi', 'Salo', 'Jimpphat', '2022-01-01'),
    (10, 2, 'Adam', 'Torzsas', 'torzsi', '2021-07-01'),
    (11, 3, 'Leonid', 'Vishnyakov', 'chopper', '2021-01-01'),
    (12, 3, 'Dmitry', 'Sokolov', 'sh1ro', '2024-01-01'),
    (13, 3, 'Boris', 'Vorobyev', 'magixx', '2019-01-01'),
    (14, 3, 'Myroslav', 'Plakhotja', 'zont1x', '2022-01-01'),
    (15, 3, 'Danil', 'Kryshkovets', 'donk', '2023-01-01'),
    (16, 4, 'Garidmagnai', 'Byambasuren', 'bLitz', '2020-01-01'),
    (17, 4, 'Sodbayar', 'Munkhbold', 'Techno4K', '2022-01-01'),
    (18, 4, 'Usukhbayar', 'Banzragch', '910', '2023-01-01'),
    (19, 4, 'Ayush', 'Batbold', 'mzinho', '2023-01-01'),
    (20, 4, 'Azbayar', 'Munkhbold', 'Senzu', '2021-01-01'),
    (21, 16, 'Rodrigo', 'Bittencourt', 'biguzera', '2023-01-01'),
    (22, 16, 'Lucas', 'Soares', 'nqz', '2023-01-01'),
    (23, 16, 'Joao', 'Vinicius', 'snow', '2024-05-04'),
    (24, 16, 'David', 'Tapia', 'dav1deuS', '2025-01-10'),
    (25, 16, 'Franco', 'Garcia', 'dgt', '2025-04-24'),
    (26, 9, 'Gabriel', 'Toledo', 'FalleN', '2023-07-01'),
    (27, 9, 'Yuri', 'Boian', 'yuurih', '2017-08-01'),
    (28, 9, 'Mareks', 'Galinskis', 'YEKINDAR', '2025-02-01'),
    (29, 9, 'Kaike', 'Cerato', 'KSCERATO', '2018-01-01'),
    (30, 9, 'Danil', 'Golubenko', 'molodoy', '2025-04-01'),
    (31, 8, 'Finn', 'Andersen', 'karrigan', '2020-01-01'),
    (32, 8, 'Oleksandr', 'Kostyliev', 's1mple', '2025-05-01'),
    (33, 8, 'Havard', 'Nygaard', 'rain', '2016-01-01'),
    (34, 8, 'Jonathan', 'Jablonowski', 'EliGE', '2025-01-01'),
    (35, 8, 'David', 'Cernansky', 'frozen', '2023-07-01'),
    (36, 7, 'Aleksi', 'Virolainen', 'Aleksib', '2023-07-01'),
    (37, 7, 'Justinas', 'Lekavicius', 'jL', '2023-07-01'),
    (38, 7, 'Mihai', 'Ivan', 'iM', '2023-07-01'),
    (39, 7, 'Ihor', 'Zhdanov', 'w0nderful', '2023-07-01'),
    (40, 7, 'Valerii', 'Vakhovskyi', 'b1t', '2020-12-01');

-- ---------------------------------------------------------------------
-- 5. tournament_entrants
-- Playoff teams for each event. Placement follows the real bracket:
-- shared placements (3 = 3rd-4th, 5 = 5th-8th or 5th-6th) show that
-- several teams can hold the same placement.
-- ---------------------------------------------------------------------
INSERT INTO tournament_entrants (tournament_id, team_id, placement) VALUES
    (1, 1, 1),
    (1, 3, 2),
    (1, 4, 3),
    (1, 7, 3),
    (1, 18, 5),
    (1, 15, 5),
    (2, 1, 1),
    (2, 4, 2),
    (2, 2, 3),
    (2, 16, 3),
    (2, 3, 5),
    (2, 9, 5),
    (2, 8, 5),
    (2, 7, 5),
    (3, 3, 1),
    (3, 2, 2),
    (3, 1, 3),
    (3, 7, 3),
    (3, 4, 5),
    (3, 9, 5);

-- =====================================================================
-- BLAST.tv Austin Major 2025 playoffs
-- =====================================================================
-- 6. playoff_series: winner_id is NULL here and set at the end of the
--    event, the way a live bracket fills in.
INSERT INTO playoff_series (series_id, winner_id, tournament_id, team1_id, team2_id,
                            creation_date, best_of, schedule_date, playoff_round) VALUES
    (1, NULL, 2, 3, 2, '2025-06-16', 3, '2025-06-19', 'Quarterfinal'),
    (2, NULL, 2, 9, 16, '2025-06-16', 3, '2025-06-19', 'Quarterfinal'),
    (3, NULL, 2, 7, 1, '2025-06-16', 3, '2025-06-20', 'Quarterfinal'),
    (4, NULL, 2, 8, 4, '2025-06-16', 3, '2025-06-20', 'Quarterfinal'),
    (5, NULL, 2, 2, 1, '2025-06-20', 3, '2025-06-21', 'Semifinal'),
    (6, NULL, 2, 16, 4, '2025-06-20', 3, '2025-06-21', 'Semifinal'),
    (7, NULL, 2, 1, 4, '2025-06-21', 3, '2025-06-22', 'Grand Final');

-- 7. matches: one row per map played, with the real map pick and winner.
INSERT INTO matches (match_id, series_id, match_number, map_id, winner_id, creation_date) VALUES
    (1, 1, 1, 5, 3, '2025-06-19'),  -- Quarterfinal: Mirage 25-21
    (2, 1, 2, 3, 2, '2025-06-19'),  -- Quarterfinal: Dust II 9-13
    (3, 1, 3, 6, 2, '2025-06-19'),  -- Quarterfinal: Nuke 10-13
    (4, 2, 1, 6, 9, '2025-06-19'),  -- Quarterfinal: Nuke 13-6
    (5, 2, 2, 2, 16, '2025-06-19'),  -- Quarterfinal: Anubis 8-13
    (6, 2, 3, 4, 16, '2025-06-19'),  -- Quarterfinal: Inferno 12-16
    (7, 3, 1, 5, 1, '2025-06-20'),  -- Quarterfinal: Mirage 9-13
    (8, 3, 2, 6, 1, '2025-06-20'),  -- Quarterfinal: Nuke 11-13
    (9, 4, 1, 5, 4, '2025-06-20'),  -- Quarterfinal: Mirage 9-13
    (10, 4, 2, 2, 4, '2025-06-20'),  -- Quarterfinal: Anubis 11-13
    (11, 5, 1, 5, 1, '2025-06-21'),  -- Semifinal: Mirage 8-13
    (12, 5, 2, 4, 2, '2025-06-21'),  -- Semifinal: Inferno 13-4
    (13, 5, 3, 11, 1, '2025-06-21'),  -- Semifinal: Train 9-13
    (14, 6, 1, 5, 4, '2025-06-21'),  -- Semifinal: Mirage 5-13
    (15, 6, 2, 2, 4, '2025-06-21'),  -- Semifinal: Anubis 5-13
    (16, 7, 1, 5, 4, '2025-06-22'),  -- Grand Final: Mirage 5-13
    (17, 7, 2, 3, 1, '2025-06-22'),  -- Grand Final: Dust II 13-4
    (18, 7, 3, 4, 1, '2025-06-22');  -- Grand Final: Inferno 13-6

-- 8. player_match_stats: 10 lines per map (5 per team).
--    Kills/deaths/assists are GENERATED sample values scaled to each
--    map's real round count (team deaths = opponent's kills); they are
--    not the official scoreboards.
INSERT INTO player_match_stats (match_id, player_id, assists, kills, deaths) VALUES
    (1, 11, 7, 41, 32),
    (1, 12, 5, 34, 26),
    (1, 13, 5, 31, 32),
    (1, 14, 9, 29, 32),
    (1, 15, 9, 39, 33),
    (1, 6, 8, 38, 28),
    (1, 7, 8, 33, 30),
    (1, 8, 10, 34, 34),
    (1, 9, 8, 23, 41),
    (1, 10, 8, 27, 41),
    (2, 11, 5, 12, 16),
    (2, 12, 4, 13, 16),
    (2, 13, 5, 15, 18),
    (2, 14, 2, 15, 16),
    (2, 15, 4, 16, 15),
    (2, 6, 5, 14, 13),
    (2, 7, 5, 20, 15),
    (2, 8, 5, 14, 14),
    (2, 9, 5, 17, 15),
    (2, 10, 5, 16, 14),
    (3, 11, 5, 15, 19),
    (3, 12, 3, 13, 20),
    (3, 13, 3, 15, 15),
    (3, 14, 4, 11, 16),
    (3, 15, 4, 18, 20),
    (3, 6, 5, 26, 16),
    (3, 7, 4, 16, 18),
    (3, 8, 3, 14, 12),
    (3, 9, 3, 16, 14),
    (3, 10, 4, 18, 12),
    (4, 26, 3, 15, 13),
    (4, 27, 3, 12, 11),
    (4, 28, 2, 15, 12),
    (4, 29, 4, 12, 14),
    (4, 30, 4, 15, 12),
    (4, 21, 4, 13, 14),
    (4, 22, 3, 13, 15),
    (4, 23, 3, 12, 13),
    (4, 24, 3, 12, 14),
    (4, 25, 3, 12, 13),
    (5, 26, 4, 9, 15),
    (5, 27, 4, 14, 19),
    (5, 28, 4, 13, 13),
    (5, 29, 4, 15, 13),
    (5, 30, 4, 15, 17),
    (5, 21, 3, 18, 14),
    (5, 22, 4, 21, 15),
    (5, 23, 4, 12, 12),
    (5, 24, 3, 12, 11),
    (5, 25, 4, 14, 14),
    (6, 26, 3, 19, 22),
    (6, 27, 5, 17, 21),
    (6, 28, 5, 14, 20),
    (6, 29, 3, 15, 17),
    (6, 30, 4, 24, 23),
    (6, 21, 6, 22, 17),
    (6, 22, 7, 20, 16),
    (6, 23, 3, 18, 20),
    (6, 24, 6, 22, 15),
    (6, 25, 4, 21, 21),
    (7, 36, 3, 16, 17),
    (7, 37, 4, 12, 15),
    (7, 38, 3, 11, 19),
    (7, 39, 3, 16, 16),
    (7, 40, 3, 16, 17),
    (7, 1, 5, 15, 13),
    (7, 2, 5, 18, 14),
    (7, 3, 5, 21, 16),
    (7, 4, 5, 15, 14),
    (7, 5, 3, 15, 14),
    (8, 36, 3, 18, 16),
    (8, 37, 3, 12, 18),
    (8, 38, 4, 12, 19),
    (8, 39, 5, 16, 18),
    (8, 40, 5, 18, 17),
    (8, 1, 3, 13, 15),
    (8, 2, 3, 23, 14),
    (8, 3, 5, 15, 16),
    (8, 4, 5, 17, 17),
    (8, 5, 4, 20, 14),
    (9, 31, 3, 15, 21),
    (9, 32, 4, 14, 17),
    (9, 33, 3, 14, 16),
    (9, 34, 5, 12, 15),
    (9, 35, 4, 16, 15),
    (9, 16, 4, 18, 14),
    (9, 17, 3, 20, 16),
    (9, 18, 4, 17, 12),
    (9, 19, 3, 12, 14),
    (9, 20, 5, 17, 15),
    (10, 31, 4, 14, 21),
    (10, 32, 5, 20, 15),
    (10, 33, 3, 12, 15),
    (10, 34, 6, 15, 18),
    (10, 35, 4, 18, 19),
    (10, 16, 5, 17, 16),
    (10, 17, 4, 19, 15),
    (10, 18, 5, 16, 15),
    (10, 19, 3, 19, 16),
    (10, 20, 5, 17, 17),
    (11, 6, 2, 12, 16),
    (11, 7, 3, 13, 14),
    (11, 8, 4, 13, 15),
    (11, 9, 4, 12, 18),
    (11, 10, 2, 16, 14),
    (11, 1, 3, 13, 14),
    (11, 2, 3, 18, 13),
    (11, 3, 4, 17, 13),
    (11, 4, 3, 15, 14),
    (11, 5, 4, 14, 12),
    (12, 6, 2, 15, 9),
    (12, 7, 2, 11, 10),
    (12, 8, 3, 13, 13),
    (12, 9, 3, 10, 11),
    (12, 10, 2, 14, 10),
    (12, 1, 4, 9, 14),
    (12, 2, 3, 14, 13),
    (12, 3, 3, 12, 13),
    (12, 4, 2, 9, 10),
    (12, 5, 4, 9, 13),
    (13, 6, 5, 14, 15),
    (13, 7, 4, 14, 16),
    (13, 8, 4, 14, 18),
    (13, 9, 3, 14, 16),
    (13, 10, 5, 17, 18),
    (13, 1, 3, 18, 15),
    (13, 2, 2, 21, 13),
    (13, 3, 3, 13, 15),
    (13, 4, 3, 12, 16),
    (13, 5, 5, 19, 14),
    (14, 21, 2, 11, 14),
    (14, 22, 4, 13, 13),
    (14, 23, 2, 11, 15),
    (14, 24, 3, 11, 14),
    (14, 25, 4, 11, 13),
    (14, 16, 3, 12, 11),
    (14, 17, 4, 13, 13),
    (14, 18, 3, 15, 9),
    (14, 19, 4, 14, 10),
    (14, 20, 3, 15, 14),
    (15, 21, 3, 13, 11),
    (15, 22, 4, 13, 13),
    (15, 23, 3, 11, 13),
    (15, 24, 3, 13, 12),
    (15, 25, 3, 11, 16),
    (15, 16, 2, 12, 14),
    (15, 17, 3, 17, 12),
    (15, 18, 3, 13, 13),
    (15, 19, 3, 12, 11),
    (15, 20, 4, 11, 11),
    (16, 1, 2, 11, 13),
    (16, 2, 2, 11, 15),
    (16, 3, 4, 12, 16),
    (16, 4, 3, 8, 13),
    (16, 5, 2, 14, 13),
    (16, 16, 3, 10, 11),
    (16, 17, 3, 17, 14),
    (16, 18, 4, 17, 10),
    (16, 19, 4, 11, 11),
    (16, 20, 3, 15, 10),
    (17, 1, 4, 13, 12),
    (17, 2, 3, 17, 11),
    (17, 3, 4, 12, 11),
    (17, 4, 4, 10, 12),
    (17, 5, 3, 11, 11),
    (17, 16, 3, 11, 13),
    (17, 17, 2, 9, 14),
    (17, 18, 4, 12, 13),
    (17, 19, 3, 12, 14),
    (17, 20, 3, 13, 9),
    (18, 1, 3, 15, 10),
    (18, 2, 4, 16, 13),
    (18, 3, 3, 13, 12),
    (18, 4, 2, 16, 15),
    (18, 5, 3, 13, 12),
    (18, 16, 3, 12, 14),
    (18, 17, 4, 11, 13),
    (18, 18, 3, 17, 13),
    (18, 19, 3, 9, 17),
    (18, 20, 4, 13, 16);

-- Close out each series with its real winner.
UPDATE playoff_series SET winner_id = 2 WHERE series_id = 1;
UPDATE playoff_series SET winner_id = 16 WHERE series_id = 2;
UPDATE playoff_series SET winner_id = 1 WHERE series_id = 3;
UPDATE playoff_series SET winner_id = 4 WHERE series_id = 4;
UPDATE playoff_series SET winner_id = 1 WHERE series_id = 5;
UPDATE playoff_series SET winner_id = 4 WHERE series_id = 6;
UPDATE playoff_series SET winner_id = 1 WHERE series_id = 7;

-- ---------------------------------------------------------------------
-- Roster changes announced 2025-07-08, between the two events:
--   * NAVI: jL steps away from competitive play  -> no team (NULL)
--   * Spirit: magixx moved to the inactive roster -> no team (NULL)
--   * makazze (NAVI) and zweih (Spirit) join their new teams
-- Their Austin stat lines above stay intact; history is not lost.
-- ---------------------------------------------------------------------
UPDATE players SET team_id = NULL WHERE player_id IN (37, 13);  -- jL, magixx

INSERT INTO players (player_id, team_id, first_name, last_name, ign, start_date) VALUES
    (41, 7, 'Drin', 'Shaqiri', 'makazze', '2025-07-08'),
    (42, 3, 'Ivan', 'Gogin', 'zweih', '2025-07-08');

-- =====================================================================
-- IEM Cologne 2025 playoffs
-- =====================================================================
-- 6. playoff_series: winner_id is NULL here and set at the end of the
--    event, the way a live bracket fills in.
INSERT INTO playoff_series (series_id, winner_id, tournament_id, team1_id, team2_id,
                            creation_date, best_of, schedule_date, playoff_round) VALUES
    (8, NULL, 3, 2, 9, '2025-07-30', 3, '2025-08-01', 'Quarterfinal'),
    (9, NULL, 3, 4, 7, '2025-07-30', 3, '2025-08-01', 'Quarterfinal'),
    (10, NULL, 3, 1, 2, '2025-08-01', 3, '2025-08-02', 'Semifinal'),
    (11, NULL, 3, 3, 7, '2025-08-01', 3, '2025-08-02', 'Semifinal'),
    (12, NULL, 3, 2, 3, '2025-08-02', 5, '2025-08-03', 'Grand Final');

-- 7. matches: one row per map played, with the real map pick and winner.
INSERT INTO matches (match_id, series_id, match_number, map_id, winner_id, creation_date) VALUES
    (19, 8, 1, 11, 2, '2025-08-01'),  -- Quarterfinal: Train 19-16
    (20, 8, 2, 5, 9, '2025-08-01'),  -- Quarterfinal: Mirage 10-13
    (21, 8, 3, 4, 2, '2025-08-01'),  -- Quarterfinal: Inferno 13-11
    (22, 9, 1, 4, 7, '2025-08-01'),  -- Quarterfinal: Inferno 18-22
    (23, 9, 2, 1, 7, '2025-08-01'),  -- Quarterfinal: Ancient 6-13
    (24, 10, 1, 5, 2, '2025-08-02'),  -- Semifinal: Mirage 9-13
    (25, 10, 2, 11, 2, '2025-08-02'),  -- Semifinal: Train 8-13
    (26, 11, 1, 5, 3, '2025-08-02'),  -- Semifinal: Mirage 13-11
    (27, 11, 2, 6, 7, '2025-08-02'),  -- Semifinal: Nuke 9-13
    (28, 11, 3, 1, 3, '2025-08-02'),  -- Semifinal: Ancient 13-6
    (29, 12, 1, 5, 3, '2025-08-03'),  -- Grand Final: Mirage 7-13
    (30, 12, 2, 1, 3, '2025-08-03'),  -- Grand Final: Ancient 11-13
    (31, 12, 3, 6, 3, '2025-08-03');  -- Grand Final: Nuke 6-13

-- 8. player_match_stats: 10 lines per map (5 per team).
--    Kills/deaths/assists are GENERATED sample values scaled to each
--    map's real round count (team deaths = opponent's kills); they are
--    not the official scoreboards.
INSERT INTO player_match_stats (match_id, player_id, assists, kills, deaths) VALUES
    (19, 6, 4, 27, 21),
    (19, 7, 8, 33, 22),
    (19, 8, 5, 24, 20),
    (19, 9, 8, 22, 24),
    (19, 10, 8, 27, 25),
    (19, 26, 6, 22, 22),
    (19, 27, 8, 22, 25),
    (19, 28, 6, 25, 31),
    (19, 29, 5, 22, 30),
    (19, 30, 7, 21, 25),
    (20, 6, 5, 16, 16),
    (20, 7, 6, 18, 19),
    (20, 8, 3, 14, 15),
    (20, 9, 3, 14, 16),
    (20, 10, 2, 15, 18),
    (20, 26, 5, 14, 13),
    (20, 27, 3, 17, 17),
    (20, 28, 3, 15, 16),
    (20, 29, 5, 18, 18),
    (20, 30, 4, 20, 13),
    (21, 6, 4, 16, 16),
    (21, 7, 3, 16, 13),
    (21, 8, 5, 22, 16),
    (21, 9, 6, 15, 16),
    (21, 10, 4, 22, 15),
    (21, 26, 4, 16, 16),
    (21, 27, 5, 14, 19),
    (21, 28, 5, 12, 21),
    (21, 29, 5, 15, 18),
    (21, 30, 4, 19, 17),
    (22, 16, 9, 26, 27),
    (22, 17, 5, 26, 27),
    (22, 18, 8, 30, 34),
    (22, 19, 5, 29, 35),
    (22, 20, 5, 24, 31),
    (22, 36, 5, 23, 28),
    (22, 41, 8, 34, 23),
    (22, 38, 6, 34, 28),
    (22, 39, 8, 26, 28),
    (22, 40, 6, 37, 28),
    (23, 16, 4, 13, 12),
    (23, 17, 3, 15, 12),
    (23, 18, 2, 15, 14),
    (23, 19, 3, 11, 15),
    (23, 20, 3, 10, 16),
    (23, 36, 3, 14, 13),
    (23, 41, 3, 12, 13),
    (23, 38, 3, 15, 13),
    (23, 39, 2, 11, 13),
    (23, 40, 2, 17, 12),
    (24, 1, 5, 11, 18),
    (24, 2, 4, 16, 15),
    (24, 3, 4, 13, 14),
    (24, 4, 4, 13, 18),
    (24, 5, 3, 15, 20),
    (24, 6, 3, 15, 15),
    (24, 7, 3, 17, 13),
    (24, 8, 4, 20, 14),
    (24, 9, 5, 14, 12),
    (24, 10, 4, 19, 14),
    (25, 1, 5, 12, 16),
    (25, 2, 3, 18, 18),
    (25, 3, 4, 10, 14),
    (25, 4, 4, 13, 17),
    (25, 5, 4, 14, 17),
    (25, 6, 3, 15, 12),
    (25, 7, 3, 18, 13),
    (25, 8, 2, 20, 12),
    (25, 9, 3, 15, 16),
    (25, 10, 5, 14, 14),
    (26, 11, 4, 15, 14),
    (26, 12, 6, 18, 14),
    (26, 42, 5, 13, 17),
    (26, 14, 5, 20, 15),
    (26, 15, 5, 27, 16),
    (26, 36, 4, 13, 17),
    (26, 41, 6, 19, 18),
    (26, 38, 4, 16, 20),
    (26, 39, 3, 16, 18),
    (26, 40, 6, 12, 20),
    (27, 11, 4, 14, 16),
    (27, 12, 2, 13, 18),
    (27, 42, 4, 12, 17),
    (27, 14, 4, 12, 13),
    (27, 15, 3, 20, 18),
    (27, 36, 2, 12, 12),
    (27, 41, 3, 22, 16),
    (27, 38, 3, 16, 13),
    (27, 39, 4, 19, 13),
    (27, 40, 5, 13, 17),
    (28, 11, 3, 11, 13),
    (28, 12, 4, 14, 14),
    (28, 42, 3, 12, 14),
    (28, 14, 4, 11, 11),
    (28, 15, 3, 22, 10),
    (28, 36, 2, 11, 15),
    (28, 41, 4, 14, 12),
    (28, 38, 2, 11, 13),
    (28, 39, 3, 11, 14),
    (28, 40, 5, 15, 16),
    (29, 6, 2, 10, 16),
    (29, 7, 4, 13, 13),
    (29, 8, 4, 15, 17),
    (29, 9, 5, 10, 15),
    (29, 10, 4, 15, 12),
    (29, 11, 3, 12, 15),
    (29, 12, 3, 17, 11),
    (29, 42, 3, 12, 12),
    (29, 14, 4, 12, 14),
    (29, 15, 3, 20, 11),
    (30, 6, 5, 17, 19),
    (30, 7, 3, 12, 17),
    (30, 8, 5, 15, 17),
    (30, 9, 4, 14, 16),
    (30, 10, 6, 18, 18),
    (30, 11, 3, 16, 16),
    (30, 12, 3, 18, 14),
    (30, 42, 5, 15, 14),
    (30, 14, 6, 17, 18),
    (30, 15, 3, 21, 14),
    (31, 6, 4, 14, 13),
    (31, 7, 3, 11, 13),
    (31, 8, 4, 11, 14),
    (31, 9, 3, 10, 16),
    (31, 10, 2, 15, 18),
    (31, 11, 2, 12, 13),
    (31, 12, 4, 18, 13),
    (31, 42, 2, 12, 14),
    (31, 14, 4, 14, 11),
    (31, 15, 3, 18, 10);

-- Close out each series with its real winner.
UPDATE playoff_series SET winner_id = 2 WHERE series_id = 8;
UPDATE playoff_series SET winner_id = 7 WHERE series_id = 9;
UPDATE playoff_series SET winner_id = 2 WHERE series_id = 10;
UPDATE playoff_series SET winner_id = 3 WHERE series_id = 11;
UPDATE playoff_series SET winner_id = 3 WHERE series_id = 12;

-- =====================================================================
-- Row counts (quick sanity check after loading)
-- =====================================================================
SELECT 'teams' AS table_name, COUNT(*) AS row_count FROM teams
UNION ALL SELECT 'maps', COUNT(*) FROM maps
UNION ALL SELECT 'tournaments', COUNT(*) FROM tournaments
UNION ALL SELECT 'players', COUNT(*) FROM players
UNION ALL SELECT 'tournament_entrants', COUNT(*) FROM tournament_entrants
UNION ALL SELECT 'playoff_series', COUNT(*) FROM playoff_series
UNION ALL SELECT 'matches', COUNT(*) FROM matches
UNION ALL SELECT 'player_match_stats', COUNT(*) FROM player_match_stats
;
