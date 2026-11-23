-- =====================================================================
-- 04_view.sql
-- Competitive CS2 Database (Team Stardust)
-- Giovanni Castro, Jaxon Constanzo, Noah Garcia, David Rendon
--
-- Purpose: Implements a database view that simplifies access to commonly
--          requested information within the Competitive CS2 Database.
--          This view provides a reusable report and hides the complexity
--          of multi-table joins and aggregate calculations.
--
-- View Implemented:
--   * v_player_general_stats
--
-- View Purpose:
--   * Provides a career summary for each professional player
--   * Combines player, team, and match statistics information
--   * Calculates total kills, deaths, and assists across all matches
--   * Allows analysts to compare player performance without writing
--     complex aggregate queries
--
-- Columns Displayed:
--   * player_name   - Player's full real name
--   * ign           - Player's in-game name
--   * team_name     - Player's current team
--   * total_kills   - Total kills across all recorded matches
--   * total_deaths  - Total deaths across all recorded matches
--   * total_assists - Total assists across all recorded matches
--
-- Demonstration Queries:
--   * Display all player career statistics
--   * Rank players by total kills
--   * Filter statistics for an individual player
--
-- Run after:
--   01_create_schema.sql
--   02_insert_data.sql
--
-- Expected Result:
--   The view returns one row per player containing aggregated
--   performance statistics, enabling efficient esports analytics
--   and player comparison reporting.
-- =====================================================================

CREATE VIEW v_player_general_stats AS
SELECT
    CONCAT(p.first_name, ' ', p.last_name) AS player_name,
    p.ign,
    t.team_name,
    SUM(pms.kills) AS total_kills,
    SUM(pms.deaths) AS total_deaths,
    SUM(pms.assists) AS total_assists
FROM players p
JOIN player_match_stats pms
    ON p.player_id = pms.player_id
LEFT JOIN teams t
    ON p.team_id = t.team_id
GROUP BY
    p.player_id,
    p.first_name,
    p.last_name,
    p.ign,
    t.team_name;
    
    
-- =====================================================================
-- Demonstration Queries
-- =====================================================================

-- Display all player career statistics
SELECT *
FROM v_player_general_stats;

-- Rank players by total kills
SELECT *
FROM v_player_general_stats
ORDER BY total_kills DESC;

-- Display statistics for a specific player using ign (username)
SELECT *
FROM v_player_general_stats
WHERE ign = 'apEX';

