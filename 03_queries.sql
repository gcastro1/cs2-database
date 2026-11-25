-- =====================================================================
-- 03_queries.sql
-- Competitive CS2 Database (Team Stardust)
-- Giovanni Castro, Jaxon Constanzo, Noah Garcia, David Rendon
--
-- Purpose: Demonstrates database functionality through a collection of
--          SQL queries based on the Competitive CS2
--          Database. These queries showcase common SQL operations and
--          answer realistic questions about teams, players, tournaments,
--          matches, and player performance.
--
-- Features Demonstrated:
--   * JOIN operations across multiple related tables
--   * Aggregate functions (COUNT, SUM, MIN, MAX)
--   * String concatenation using CONCAT()
--   * DISTINCT selection
--   * Subqueries
--   * GROUP BY and aggregate reporting
--   * ORDER BY result sorting
--
-- Query Topics:
--   * Team rosters 
--   * Team sizes
--   * Team participation
--   * Total team kills
--   * Tournament winners
--   * Highest Ranked team
--   * Each players total kills
--   * Best single match performance
--
-- Run after:
--   01_create_schema.sql
--   02_insert_data.sql
--
-- Expected Result:
--   Each query returns meaningful information that demonstrates the
--   database's ability to support esports analytics, tournament
--   reporting, roster management, and performance analysis.
-- =====================================================================

/*
Query 1
Displays Current Team Rosters
Question: What players are currently on each team?
*/
SELECT
    t.team_name,
    CONCAT(p.first_name, ' ', p.last_name) AS player_name,
    p.ign
FROM players p
JOIN teams t
    ON p.team_id = t.team_id
ORDER BY t.team_name, p.ign;


/*
Query 2
Displays Number of Players Per Team
Question: Which teams currently have the largest rosters?
*/
SELECT
    t.team_name,
    COUNT(p.player_id) AS roster_size
FROM teams t
LEFT JOIN players p
    ON t.team_id = p.team_id
GROUP BY t.team_id, t.team_name
ORDER BY roster_size DESC, t.team_name;


/*
Query 3
Displays All Teams With Players
Question: Which teams currently have players on their roster?
*/
SELECT DISTINCT
    t.team_name
FROM teams t
JOIN players p
    ON t.team_id = p.team_id
ORDER BY t.team_name;

/*
Query 4
Displays Total Kills By Team
Question: Which team accumulated the most kills across all recorded matches?
*/
SELECT
    t.team_name,
    SUM(pms.kills) AS total_kills
FROM player_match_stats pms
JOIN players p
    ON pms.player_id = p.player_id
JOIN teams t
    ON p.team_id = t.team_id
GROUP BY t.team_id, t.team_name
ORDER BY total_kills DESC;


/*
Query 5
Displays Tournament Winners
Question: Who won each tournament?
*/
SELECT
    tr.tournament_name,
    tr.tournament_year,
    t.team_name AS champion
FROM tournament_entrants te
JOIN tournaments tr
    ON te.tournament_id = tr.tournament_id
JOIN teams t
    ON te.team_id = t.team_id
WHERE te.placement = 1
ORDER BY tr.tournament_year, tr.tournament_name;


/*
Query 6
Displays Highest Ranked Team
Question: Which team has the best Valve ranking?
*/
SELECT
    team_name,
    valve_ranking
FROM teams
WHERE valve_ranking =
(
    SELECT MIN(valve_ranking)
    FROM teams
    WHERE valve_ranking IS NOT NULL
);

/*
Query 7
Displays Total kills for each player
Question: How many kills does each player have?
*/
SELECT
    p.ign,
    CONCAT(p.first_name, ' ', p.last_name) AS player_name,
    SUM(pms.kills) AS total_kills
FROM player_match_stats pms
JOIN players p
    ON pms.player_id = p.player_id
GROUP BY p.player_id, p.ign, p.first_name, p.last_name
ORDER BY total_kills DESC;


/*
Query 8
Displays Highest Kill Match Performance
Question: What is the highest number of kills recorded by a player in a single match?
*/
SELECT
    p.ign,
    pms.kills,
    ma.match_id
FROM player_match_stats pms
JOIN players p
    ON pms.player_id = p.player_id
JOIN matches ma
    ON pms.match_id = ma.match_id
WHERE pms.kills =
(
    SELECT MAX(kills)
    FROM player_match_stats
);


/*
Query 9
Displays each player's stats for each map in the selected playoff series
Question: How did each player perform on each map during a selected playoff series?
*/
SELECT t.tournament_name,
       CONCAT(a.team_name, ' vs. ', b.team_name) AS matchup,
       m.match_number AS map_number,
       mp.name AS map_name,
       p.ign,
       s.kills,
       s.deaths,
       s.assists
FROM player_match_stats AS s
JOIN players AS p        ON p.player_id = s.player_id
JOIN matches AS m        ON m.match_id = s.match_id
JOIN maps AS mp          ON mp.map_id = m.map_id
JOIN playoff_series AS ps ON ps.series_id = m.series_id
JOIN tournaments AS t    ON t.tournament_id = ps.tournament_id
JOIN teams AS a          ON a.team_id = ps.team1_id
JOIN teams AS b          ON b.team_id = ps.team2_id
WHERE ps.series_id = 1
ORDER BY m.match_number, s.kills DESC, p.ign;
