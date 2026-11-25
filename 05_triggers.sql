-- =====================================================================
-- 05_triggers.sql
-- Competitive CS2 Database (Team Stardust)
-- Giovanni Castro, Jaxon Constanzo, Noah Garcia, David Rendon
--
-- Purpose: Demonstrates match validation, series results, and player
--          stat checks through five triggers.
--
-- Triggers Implemented:
--   * BEFORE INSERT on matches - Validates the match number and winner
--   * AFTER INSERT on matches  - Recalculates series results
--   * BEFORE INSERT on stats   - Validates team membership and stat limits
--   * AFTER UPDATE on matches  - Validates and recalculates series results
--   * BEFORE DELETE on matches - Protects matches with results or stats
--
-- Run after:
--   01_create_schema.sql
--   02_insert_data.sql
--
-- Match Workflow:
--   Insert scheduled matches with a NULL winner or completed matches
--   with a winner. UPDATE can record or correct an existing result.
--   Historical match results are loaded by 02_insert_data.sql.
-- =====================================================================

USE cs2_competitive;

DROP TRIGGER IF EXISTS trg_matches_before_insert;
DROP TRIGGER IF EXISTS trg_matches_after_insert;
DROP TRIGGER IF EXISTS trg_player_matches_before_insert;
DROP TRIGGER IF EXISTS trg_matches_after_update;
DROP TRIGGER IF EXISTS trg_matches_before_delete;

DELIMITER //

-- =====================================================================
-- Trigger Definitions
-- =====================================================================

-- INSERT: match winner must be team1 or team2 of the match's series.
CREATE TRIGGER trg_matches_before_insert
BEFORE INSERT ON matches
FOR EACH ROW
BEGIN
    DECLARE series_best_of INT;
    DECLARE series_team1 INT;
    DECLARE series_team2 INT;

    SELECT best_of, team1_id, team2_id
    INTO series_best_of, series_team1, series_team2
    FROM playoff_series
    WHERE series_id = NEW.series_id
    FOR SHARE;

    IF series_best_of IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Schedule the playoff series first.';
    END IF;

    IF NEW.match_number > series_best_of THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Match number exceeds the series best-of limit.';
    END IF;

    IF NEW.winner_id IS NOT NULL AND NEW.winner_id NOT IN (series_team1, series_team2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The winner must be either Team 1 or Team 2.';
    END IF;
END //

-- INSERT: Recalculates series results after a match is inserted.
CREATE TRIGGER trg_matches_after_insert
AFTER INSERT ON matches
FOR EACH ROW
BEGIN
    DECLARE series_team1 INT; 
    DECLARE series_team2 INT;
    DECLARE series_best_of INT;
    DECLARE event_id INT;
    DECLARE round_name VARCHAR(30);
    DECLARE old_series_winner INT;
    DECLARE new_series_winner INT DEFAULT NULL;
    DECLARE team1_wins INT;
    DECLARE team2_wins INT;
    DECLARE wins_needed INT;

    IF (NEW.winner_id IS NOT NULL) THEN

        SELECT team1_id, team2_id, best_of, tournament_id, playoff_round, winner_id
        INTO series_team1, series_team2, series_best_of, event_id, round_name, old_series_winner
        FROM playoff_series
        WHERE series_id = NEW.series_id
        FOR UPDATE;

        SET wins_needed = (series_best_of DIV 2) + 1;

        -- A locking read sees current results even in a transaction that
        -- already read an earlier snapshot of this series.
        SELECT COUNT(CASE WHEN winner_id = series_team1 THEN 1 END),
               COUNT(CASE WHEN winner_id = series_team2 THEN 1 END)
        INTO team1_wins, team2_wins
        FROM matches
        WHERE series_id = NEW.series_id
        FOR SHARE;

        IF team1_wins >= wins_needed THEN
            SET new_series_winner = series_team1;
        ELSEIF team2_wins >= wins_needed THEN
            SET new_series_winner = series_team2;
        END IF;

        IF NOT (new_series_winner <=> old_series_winner) THEN
            UPDATE playoff_series
            SET winner_id = new_series_winner
            WHERE series_id = NEW.series_id;

            IF round_name = 'Grand Final' THEN
                UPDATE tournament_entrants
                SET placement = CASE
                    WHEN new_series_winner IS NULL THEN NULL
                    WHEN team_id = new_series_winner THEN 1
                    ELSE 2
                END
                WHERE tournament_id = event_id
                  AND team_id IN (series_team1, series_team2);
            END IF;
        END IF;
    END IF;
END //

-- INSERT: player must be team1 or team2 of the match's series.
CREATE TRIGGER trg_player_matches_before_insert
BEFORE INSERT ON player_match_stats
FOR EACH ROW
BEGIN
    DECLARE series_team1 INT;
    DECLARE series_team2 INT;
    DECLARE player_team_id INT;

    DECLARE series_team_count INT;

    SELECT ps.team1_id, ps.team2_id
    INTO series_team1, series_team2
    FROM matches AS m
    JOIN playoff_series AS ps ON ps.series_id = m.series_id
    WHERE m.match_id = NEW.match_id
    FOR SHARE;

    SELECT p.team_id
    INTO player_team_id
    FROM players AS p
    WHERE p.player_id = NEW.player_id
    FOR SHARE;

    IF player_team_id IS NULL OR  player_team_id NOT IN (series_team1, series_team2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The player must belong to one of the two teams in the series.';
    END IF;

    SELECT COUNT(*)
    INTO series_team_count
    FROM player_match_stats AS stats
    JOIN players AS p ON p.player_id = stats.player_id
    WHERE stats.match_id = NEW.match_id AND p.team_id = player_team_id
    FOR SHARE;

    IF series_team_count >= 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This team already has five player stat lines for this match.';
    END IF;
END //

-- UPDATE: validate the match and recalculate its series winner when the
-- result changes. A Grand Final also sets the tournament entrants'
-- first and second places. Clearing a clinching result can reopen a series.
CREATE TRIGGER trg_matches_after_update
AFTER UPDATE ON matches
FOR EACH ROW
BEGIN
    DECLARE series_team1 INT;
    DECLARE series_team2 INT;
    DECLARE series_best_of INT;
    DECLARE event_id INT;
    DECLARE round_name VARCHAR(30);
    DECLARE old_series_winner INT;
    DECLARE new_series_winner INT DEFAULT NULL;
    DECLARE team1_wins INT;
    DECLARE team2_wins INT;
    DECLARE wins_needed INT;

    IF NEW.series_id <> OLD.series_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A match cannot be moved to another playoff series.';
    END IF;

    SELECT team1_id, team2_id, best_of, tournament_id, playoff_round, winner_id
    INTO series_team1, series_team2, series_best_of, event_id, round_name, old_series_winner
    FROM playoff_series
    WHERE series_id = NEW.series_id
    FOR UPDATE;

    IF NEW.match_number > series_best_of THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Match number exceeds the series best-of limit.';
    END IF;

    IF NEW.winner_id IS NOT NULL AND NEW.winner_id NOT IN (series_team1, series_team2) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The match winner must be a team in the playoff series.';
    END IF;

    IF NOT (NEW.winner_id <=> OLD.winner_id) THEN
        SET wins_needed = (series_best_of DIV 2) + 1;

        -- A locking read sees current results even in a transaction that
        -- already read an earlier snapshot of this series.
        SELECT COUNT(CASE WHEN winner_id = series_team1 THEN 1 END),
               COUNT(CASE WHEN winner_id = series_team2 THEN 1 END)
        INTO team1_wins, team2_wins
        FROM matches
        WHERE series_id = NEW.series_id
        FOR SHARE;

        IF team1_wins >= wins_needed THEN
            SET new_series_winner = series_team1;
        ELSEIF team2_wins >= wins_needed THEN
            SET new_series_winner = series_team2;
        END IF;

        IF NOT (new_series_winner <=> old_series_winner) THEN
            UPDATE playoff_series
            SET winner_id = new_series_winner
            WHERE series_id = NEW.series_id;

            IF round_name = 'Grand Final' THEN
                UPDATE tournament_entrants
                SET placement = CASE
                    WHEN new_series_winner IS NULL THEN NULL
                    WHEN team_id = new_series_winner THEN 1
                    ELSE 2
                END
                WHERE tournament_id = event_id
                  AND team_id IN (series_team1, series_team2);
            END IF;
        END IF;
    END IF;
END //

-- DELETE: allow unused scheduled match to be removed. Protect scored matches
-- and matches with player statistics from direct deletion. The demo and
-- normal match cleanup use DELETE on matches directly.
CREATE TRIGGER trg_matches_before_delete
BEFORE DELETE ON matches
FOR EACH ROW
BEGIN
    IF OLD.winner_id IS NOT NULL OR EXISTS (SELECT 1 FROM player_match_stats WHERE match_id = OLD.match_id
) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot delete a match with a result or player statistics.';
    END IF;
END //

DELIMITER ;

-- =====================================================================
-- Demonstration Statements
-- =====================================================================

-- Each demonstration rolls back its data changes.
-- Rejection statements are commented so the full script runs without
-- intentional errors. To test one, uncomment it and run through the error,
-- then execute the corresponding ROLLBACK in the same session.

-- 1. Schedule an unused match and then delete it.
START TRANSACTION;
INSERT INTO playoff_series
    (tournament_id, team1_id, team2_id, best_of, schedule_date, playoff_round)
VALUES (2, 1, 4, 1, CURRENT_DATE, 'Demo');
SET @demo_series_id = LAST_INSERT_ID();

INSERT INTO matches (series_id, match_number, map_id)
VALUES (@demo_series_id, 1, 5);
SET @demo_match_id = LAST_INSERT_ID();

-- Expected: match 1 has a NULL winner.
SELECT match_number, winner_id
FROM matches
WHERE match_id = @demo_match_id;

-- Uncomment to verify that a best-of-one rejects match 2.
-- INSERT INTO matches (series_id, match_number, map_id)
-- VALUES (@demo_series_id, 2, 3);

DELETE FROM matches WHERE match_id = @demo_match_id;
SELECT COUNT(*) AS remaining_demo_matches
FROM matches
WHERE match_id = @demo_match_id;
ROLLBACK;

-- 2. Insert completed matches into a temporary best-of-three final.
START TRANSACTION;
INSERT INTO playoff_series
    (tournament_id, team1_id, team2_id, best_of, schedule_date, playoff_round)
VALUES (2, 1, 4, 3, CURRENT_DATE, 'Grand Final');
SET @demo_series_id = LAST_INSERT_ID();

-- Uncomment to verify that an outside team cannot win a match.
-- INSERT INTO matches (series_id, match_number, map_id, winner_id)
-- VALUES (@demo_series_id, 1, 5, 3);

INSERT INTO matches (series_id, match_number, map_id, winner_id)
VALUES (@demo_series_id, 1, 5, 4);
SET @demo_match_id = LAST_INSERT_ID();

-- Expected: the series is still undecided after one win.
SELECT winner_id AS winner_after_first_match
FROM playoff_series WHERE series_id = @demo_series_id;

INSERT INTO matches (series_id, match_number, map_id, winner_id)
VALUES (@demo_series_id, 2, 3, 4);

-- Expected: The MongolZ (4) clinch and take first place.
SELECT winner_id AS winner_after_second_match
FROM playoff_series WHERE series_id = @demo_series_id;

SELECT t.team_name, e.placement
FROM tournament_entrants AS e
JOIN teams AS t ON t.team_id = e.team_id
WHERE e.tournament_id = 2 AND e.team_id IN (1, 4)
ORDER BY e.placement;

-- 3. Enter five stat lines from Team Vitality for match 1.
INSERT INTO player_match_stats (match_id, player_id, kills, deaths, assists)
VALUES (@demo_match_id, 1, 18, 16, 4),
       (@demo_match_id, 2, 21, 15, 5),
       (@demo_match_id, 3, 15, 17, 3),
       (@demo_match_id, 4, 13, 18, 6),
       (@demo_match_id, 5, 17, 16, 4);

-- Expected: one row for team 1 with five stat lines.
SELECT p.team_id, COUNT(*) AS stat_lines
FROM player_match_stats AS stats
JOIN players AS p ON p.player_id = stats.player_id
WHERE stats.match_id = @demo_match_id
GROUP BY p.team_id;

-- Uncomment to reject stats for player 6, who belongs to an outside team.
-- INSERT INTO player_match_stats (match_id, player_id) VALUES (@demo_match_id, 6);

-- Uncomment both statements to test a sixth player from Team Vitality.
-- INSERT INTO players (team_id, first_name, last_name, ign, start_date)
-- VALUES (1, 'Demo', 'Reserve', 'demo_reserve', CURRENT_DATE);
-- INSERT INTO player_match_stats (match_id, player_id)
-- VALUES (@demo_match_id, LAST_INSERT_ID());

-- Uncomment to test protection against deletion of a scored match.
-- DELETE FROM matches WHERE match_id = @demo_match_id;
ROLLBACK;

-- 4. Correct the deciding match of the seeded Austin Major final.
-- Expected: The MongolZ (4) move to first, Team Vitality (1) to second.
START TRANSACTION;
UPDATE matches SET winner_id = 4 WHERE match_id = 18;
SELECT series_id, winner_id FROM playoff_series WHERE series_id = 7;
SELECT t.team_name, e.placement
FROM tournament_entrants AS e
JOIN teams AS t ON t.team_id = e.team_id
WHERE e.tournament_id = 2 AND e.team_id IN (1, 4)
ORDER BY e.placement;
ROLLBACK;

