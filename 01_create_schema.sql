-- =====================================================================
-- 01_create_schema.sql
-- Competitive CS2 Database (Team Stardust)
-- Giovanni Castro, Jaxon Constanzo, Noah Garcia, David Rendon
--
-- Purpose: Creates the database and all eight tables from our schema
--          diagram, with primary keys, foreign keys, and the UNIQUE,
--          NOT NULL, DEFAULT, and CHECK constraints from our business
--          rules.
--
-- Tables are created parent-first so every foreign key points at a table
-- that already exists:
--   1. teams                 (no FKs)
--   2. maps                  (no FKs)
--   3. tournaments           (no FKs)
--   4. players               -> teams
--   5. tournament_entrants   -> tournaments, teams
--   6. playoff_series        -> tournaments, teams, tournament_entrants
--   7. matches               -> playoff_series, maps, teams
--   8. player_match_stats    -> matches, players
--
-- Rules that span more than one table (e.g., a match winner must be one
-- of its series' two teams) cannot be written as a CHECK in MySQL. They
-- are listed at the bottom of this file and are enforced by triggers in
-- 04_triggers_procedure_view.sql.
-- =====================================================================
DROP DATABASE IF EXISTS cs2_competitive;
CREATE DATABASE cs2_competitive;
USE cs2_competitive;


-- ---------------------------------------------------------------------
-- 1. teams
-- A professional CS2 organization. A team can exist before it has any
-- players or tournament entries.
--   * team_name is unique.
--   * valve_ranking is a positive whole number, may be NULL (unranked),
--     and no two teams can share a NOT NULL ranking.
-- ---------------------------------------------------------------------
CREATE TABLE teams (
    team_id          INT          NOT NULL AUTO_INCREMENT,
    team_name        VARCHAR(50)  NOT NULL,
    foundation_date  DATE         NOT NULL,
    valve_ranking    INT,

    CONSTRAINT pk_teams               PRIMARY KEY (team_id),
    CONSTRAINT uq_teams_name          UNIQUE (team_name),
    CONSTRAINT uq_teams_valve_ranking UNIQUE (valve_ranking),
    CONSTRAINT chk_teams_valve_ranking CHECK (valve_ranking IS NULL OR valve_ranking > 0)
);


-- ---------------------------------------------------------------------
-- 2. maps
-- A map in the CS2 map pool. A map can exist without ever being played.
--   * Map names are unique.
-- ---------------------------------------------------------------------
CREATE TABLE maps (
    map_id         INT          NOT NULL AUTO_INCREMENT,
    name           VARCHAR(30)  NOT NULL,
    creation_date  DATE         NOT NULL,

    CONSTRAINT pk_maps      PRIMARY KEY (map_id),
    CONSTRAINT uq_maps_name UNIQUE (name)
);


-- ---------------------------------------------------------------------
-- 3. tournaments
-- A CS2 event. Created before any teams, series, or matches are added.
--   * tournament_type comes from a fixed list: Major, Premier, Regional.
--   * prize_pool cannot be negative (defaults to 0 if not yet announced).
--   * The same event name cannot appear twice in the same year.
-- ---------------------------------------------------------------------
CREATE TABLE tournaments (
    tournament_id    INT           NOT NULL AUTO_INCREMENT,
    tournament_name  VARCHAR(100)  NOT NULL,
    tournament_year  INT           NOT NULL,
    tournament_type  VARCHAR(10)   NOT NULL,
    prize_pool       DOUBLE        NOT NULL DEFAULT 0,

    CONSTRAINT pk_tournaments           PRIMARY KEY (tournament_id),
    CONSTRAINT uq_tournaments_name_year UNIQUE (tournament_name, tournament_year),
    CONSTRAINT chk_tournaments_type     CHECK (tournament_type IN ('Major', 'Premier', 'Regional')),
    CONSTRAINT chk_tournaments_prize    CHECK (prize_pool >= 0)
);


-- ---------------------------------------------------------------------
-- 4. players
-- A professional player.
--   * team_id is NULL for a free agent; a player belongs to at most one
--     team at a time.
--   * IGNs and real names are NOT unique; player_id tells players apart.
--   * Career and per-tournament stats are NOT stored here; they are
--     calculated from player_match_stats.
--   * If a team is deleted its players become free agents (SET NULL).
-- ---------------------------------------------------------------------
CREATE TABLE players (
    player_id   INT          NOT NULL AUTO_INCREMENT,
    team_id     INT,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    ign         VARCHAR(30)  NOT NULL,
    start_date  DATE         NOT NULL,

    CONSTRAINT pk_players       PRIMARY KEY (player_id),
    CONSTRAINT fk_players_team  FOREIGN KEY (team_id)
        REFERENCES teams (team_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);


-- ---------------------------------------------------------------------
-- 5. tournament_entrants   (M:N  teams <-> tournaments)
-- Records that a team entered a tournament, plus its final placement.
--   * Composite PK: a team enters a given tournament only once.
--   * placement is NULL until the tournament ends, must be a positive
--     whole number, and may be shared (e.g., two teams tied for 3rd-4th).
-- ---------------------------------------------------------------------
CREATE TABLE tournament_entrants (
    tournament_id  INT  NOT NULL,
    team_id        INT  NOT NULL,
    placement      INT,

    CONSTRAINT pk_tournament_entrants PRIMARY KEY (tournament_id, team_id),
    CONSTRAINT fk_entrants_tournament FOREIGN KEY (tournament_id)
        REFERENCES tournaments (tournament_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_entrants_team FOREIGN KEY (team_id)
        REFERENCES teams (team_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT chk_entrants_placement CHECK (placement IS NULL OR placement > 0)
);


-- ---------------------------------------------------------------------
-- 6. playoff_series
-- A head-to-head series (Bo1 / Bo3 / Bo5) between two teams inside one
-- tournament. Created and scheduled before any of its maps are played.
--   * team1_id and team2_id are required and must be different.
--   * Both teams must be entrants of the series' tournament. This is
--     enforced with composite FKs into tournament_entrants.
--   * winner_id is NULL until the series ends and must be team1 or team2.
--   * best_of comes from a fixed list: 1, 3, 5.
--   * Team FKs use RESTRICT (no SET NULL/CASCADE) because MySQL does not
--     allow a CHECK constraint on a column that has a referential action.
-- ---------------------------------------------------------------------
CREATE TABLE playoff_series (
    series_id      INT          NOT NULL AUTO_INCREMENT,
    winner_id      INT,
    tournament_id  INT          NOT NULL,
    team1_id       INT          NOT NULL,
    team2_id       INT          NOT NULL,
    creation_date  DATE         NOT NULL DEFAULT (CURRENT_DATE),
    best_of        INT          NOT NULL DEFAULT 3,
    schedule_date  DATE         NOT NULL,
    playoff_round  VARCHAR(30)  NOT NULL,

    CONSTRAINT pk_playoff_series  PRIMARY KEY (series_id),

    CONSTRAINT fk_series_tournament FOREIGN KEY (tournament_id)
        REFERENCES tournaments (tournament_id),
    CONSTRAINT fk_series_team1  FOREIGN KEY (team1_id)  REFERENCES teams (team_id),
    CONSTRAINT fk_series_team2  FOREIGN KEY (team2_id)  REFERENCES teams (team_id),
    CONSTRAINT fk_series_winner FOREIGN KEY (winner_id) REFERENCES teams (team_id),

    -- Both teams must have entered this series' tournament.
    CONSTRAINT fk_series_team1_entrant FOREIGN KEY (tournament_id, team1_id)
        REFERENCES tournament_entrants (tournament_id, team_id),
    CONSTRAINT fk_series_team2_entrant FOREIGN KEY (tournament_id, team2_id)
        REFERENCES tournament_entrants (tournament_id, team_id),

    CONSTRAINT chk_series_diff_teams CHECK (team1_id <> team2_id),
    CONSTRAINT chk_series_winner     CHECK (winner_id IS NULL OR winner_id IN (team1_id, team2_id)),
    CONSTRAINT chk_series_best_of    CHECK (best_of IN (1, 3, 5)),
    CONSTRAINT chk_series_schedule   CHECK (schedule_date >= creation_date)
);


-- ---------------------------------------------------------------------
-- 7. matches
-- A single map played inside a playoff series.
--   * series_id: every match belongs to exactly one series. Deleting a
--     series deletes its matches.
--   * match_number: the map's position in the series (Map 1, Map 2, ...),
--     unique within a series.
--   * The same map cannot be played twice in the same series.
--   * winner_id is NULL until the match is played.
--   * The match's teams and tournament come from its series (not stored).
-- ---------------------------------------------------------------------
CREATE TABLE matches (
    match_id       INT   NOT NULL AUTO_INCREMENT,
    series_id      INT   NOT NULL,
    match_number   INT   NOT NULL,
    map_id         INT   NOT NULL,
    winner_id      INT,
    creation_date  DATE  NOT NULL DEFAULT (CURRENT_DATE),

    CONSTRAINT pk_matches PRIMARY KEY (match_id),
    CONSTRAINT fk_matches_series FOREIGN KEY (series_id)
        REFERENCES playoff_series (series_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_matches_map FOREIGN KEY (map_id)
        REFERENCES maps (map_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_matches_winner FOREIGN KEY (winner_id)
        REFERENCES teams (team_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_matches_series_number UNIQUE (series_id, match_number),
    CONSTRAINT uq_matches_series_map    UNIQUE (series_id, map_id),
    CONSTRAINT chk_matches_number       CHECK (match_number BETWEEN 1 AND 5)
);


-- ---------------------------------------------------------------------
-- 8. player_match_stats   (M:N  players <-> matches)
-- One player's kills / deaths / assists in one match.
--   * Composite PK: at most one stat record per player per match.
--   * Stat values cannot be negative.
--   * Deleting a match deletes its stat lines; a player with recorded
--     stats cannot be deleted (RESTRICT) so history is not lost.
-- ---------------------------------------------------------------------
CREATE TABLE player_match_stats (
    match_id   INT  NOT NULL,
    player_id  INT  NOT NULL,
    assists    INT  NOT NULL DEFAULT 0,
    kills      INT  NOT NULL DEFAULT 0,
    deaths     INT  NOT NULL DEFAULT 0,

    CONSTRAINT pk_player_match_stats PRIMARY KEY (match_id, player_id),
    CONSTRAINT fk_pms_match FOREIGN KEY (match_id)
        REFERENCES matches (match_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_pms_player FOREIGN KEY (player_id)
        REFERENCES players (player_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_pms_assists CHECK (assists >= 0),
    CONSTRAINT chk_pms_kills   CHECK (kills   >= 0),
    CONSTRAINT chk_pms_deaths  CHECK (deaths  >= 0)
);


-- =====================================================================
-- Cross-table business rules (enforced by triggers in file 05)
-- MySQL CHECK constraints can only see columns in the same row, so these
-- rules need triggers:
--   * A match winner must be team1 or team2 of the match's series.
--   * A series cannot have more matches than its best_of allows
--     (match_number <= best_of).
--   * A player in player_match_stats must belong to team1 or team2 of the
--     match's series; a match has at most 10 stat lines, 5 per team.
--   * A series winner must be the team that won the majority of its
--     matches.
-- =====================================================================
