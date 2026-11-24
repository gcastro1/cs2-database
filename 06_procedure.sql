-- =====================================================================
-- 06_procedure.sql
-- Competitive CS2 Database (Team Stardust)
-- Giovanni Castro, Jaxon Constanzo, Noah Garcia, David Rendon
--
-- Purpose: Implements a stored procedure that calculates a players
--          total kills within the Competitive CS2 Database.
--          This procedure allows analysts to retrieve a player's total
--          kills across all recorded matches without repeatedly writing
--          aggregate queries.
--
-- Procedure Implemented:
--   * proc_get_total_kills
--
-- Procedure Purpose:
--   * Calculates the total number of kills recorded by a player
--   * Validates that the specified player exists
--   * Aggregates statistics across all recorded matches
--   * Provides a reusable method for player performance analysis
--
-- Input Parameters:
--   * in_ign - Player's in-game name (IGN)
--
-- Output:
--   * ign         - Player's in-game name
--   * total_kills - Total kills across all recorded matches
--
-- Demonstration Queries:
--   * Retrieve total kills for donk
--   * Retrieve total kills for ZywOo
--   * Retrieve total kills for apEX
--
-- Run after:
--   01_create_schema.sql
--   02_insert_data.sql
--
-- Expected Result:
--   The procedure returns a player's IGN and their aggregated kill
--   count across all recorded matches. If the specified player does
--   not exist, an error message is returned.
-- =====================================================================
DELIMITER //

CREATE PROCEDURE proc_get_total_kills (
    IN in_ign VARCHAR(30)
)
BEGIN
    IF (SELECT COUNT(*)
        FROM players
        WHERE ign = in_ign) = 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Player IGN not found.';
    END IF;

    SELECT
        p.ign,
        SUM(pms.kills) AS total_kills
    FROM players p
    JOIN player_match_stats pms
        ON p.player_id = pms.player_id
    WHERE p.ign = in_ign
    GROUP BY p.player_id, p.ign;

END//

DELIMITER ;

-- =====================================================================
-- Demonstration Queries
-- =====================================================================

-- Retrieve total kills for donk
CALL proc_get_total_kills('donk');

-- Retrieve total kills for ZywOo
CALL proc_get_total_kills('ZywOo');

-- Retrieve total kills for apEX
CALL proc_get_total_kills('apEX');