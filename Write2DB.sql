-- =========================================
-- 1️⃣ Create teams_plays table
-- This table stores basic game information for each team
-- Each row represents a team's performance in a single game
CREATE TABLE nba.teams_plays (
    game_id numeric NOT NULL,               -- Unique game identifier
    game_date date NOT NULL,                -- Date of the game (no time)
    team_id numeric NOT NULL,               -- Unique ID of the team
    team_abbreviation varchar NOT NULL,     -- Team abbreviation (e.g., ATL)
    team_name varchar NULL,                 -- Full team name (e.g., Atlanta Hawks)
    matchup varchar NULL,                   -- Matchup description (e.g., ATL vs BOS)
    wl varchar NULL,                        -- Win/Loss indicator (W or L)
    pts numeric NULL,                       -- Points scored by the team
    home_away varchar NULL,                 -- "HOME" or "AWAY"
    pts_opp numeric NULL,                   -- Points scored by the opponent
    point_diff numeric NULL,                -- Point difference (pts - pts_opp)
    CONSTRAINT teams_plays_pk PRIMARY KEY (game_id, team_id)  -- Composite primary key
);

-- =========================================
-- 2️⃣ Create team_games_boxscore table
-- This table stores detailed boxscore statistics for each team in each game
CREATE TABLE nba.team_games_boxscore (
    game_id numeric NOT NULL,                    -- Unique game identifier
    game_date timestamp NULL,                    -- Date and time of the game
    team_id int8 NOT NULL,                       -- Unique ID of the team
    team_abbreviation text NULL,                 -- Team abbreviation (e.g., ATL)
    team_name text NULL,                         -- Full team name (e.g., Atlanta Hawks)
    matchup text NULL,                           -- Matchup description
    wl text NULL,                                -- Win/Loss indicator
    pts int8 NULL,                               -- Points scored by the team
    home_away text NULL,                          -- "HOME" or "AWAY"
    pts_opp int8 NULL,                            -- Points scored by the opponent
    point_diff int8 NULL,                         -- Point difference
    team_abbreviation_teamstat text NULL,         -- Abbreviation from another stat source
    pts_teamstat int8 NULL,                       -- Points from another stat source
    reb int8 NULL,                                -- Total rebounds
    ast int8 NULL,                                -- Total assists
    blk int8 NULL,                                -- Total blocks
    fgm int8 NULL,                                -- Field goals made
    fga int8 NULL,                                -- Field goals attempted
    fg_pct numeric NULL,                          -- Field goal percentage
    fg3m int8 NULL,                               -- Three-pointers made
    fg3a int8 NULL,                               -- Three-pointers attempted
    fg3_pct numeric NULL,                         -- Three-point percentage
    ftm int8 NULL,                                -- Free throws made
    fta int8 NULL,                                -- Free throws attempted
    ft_pct numeric NULL,                          -- Free throw percentage
    CONSTRAINT team_games_boxscore_pkey PRIMARY KEY (game_id, team_id)  -- Composite primary key
);

-- =========================================
-- Notes:
-- 1. teams_plays: stores basic team performance per game; good for summary queries.
-- 2. team_games_boxscore: stores full boxscore stats; useful for advanced analysis.
-- 3. Both tables use a composite primary key (game_id + team_id) to ensure uniqueness per team per game.
-- 4. Column types differ slightly: numeric, int8, varchar, text; choose according to your analysis needs.
-- 5. game_date in teams_plays is just DATE; in team_games_boxscore it includes TIME (timestamp).


-- =========================================
-- 1️⃣ Create permanent team table
-- This table will store NBA teams in a distinct list
-- team_id is the primary key, team_abbreviation is required, team_name is optional
CREATE TABLE IF NOT EXISTS nba.teams (
  team_id numeric PRIMARY KEY,        -- Unique ID of the team
  team_abbreviation varchar NOT NULL, -- Team abbreviation (e.g., ATL)
  team_name varchar                   -- Full team name (e.g., Atlanta Hawks)
);

-- Check if the table was created
SELECT * FROM nba.teams;

-- =========================================
-- 2️⃣ SP: Synchronize data from teams_plays to teams table
-- This procedure selects distinct teams from teams_plays
-- and inserts or updates them into nba.teams (upsert)
CREATE OR REPLACE PROCEDURE nba.sync_teams_from_teams_plays()
LANGUAGE plpgsql
AS $$
BEGIN
  -- Select distinct teams to avoid duplicates
  INSERT INTO nba.teams (team_id, team_abbreviation, team_name)
  SELECT DISTINCT team_id, team_abbreviation, team_name
  FROM nba.teams_plays
  -- If the same team_id exists, update the record (upsert)
  ON CONFLICT (team_id) DO UPDATE
    SET team_abbreviation = EXCLUDED.team_abbreviation, -- Update abbreviation
        team_name = COALESCE(EXCLUDED.team_name, nba.teams.team_name); -- Keep old name if NULL
END;
$$;

-- Manually call the procedure to test
CALL nba.sync_teams_from_teams_plays();

-- View the results
SELECT * FROM nba.teams ORDER BY team_abbreviation;

-- =========================================
-- 3️⃣ Trigger Function
-- This function is called by the trigger and executes the SP
CREATE OR REPLACE FUNCTION nba.trigger_sync_teams()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Automatically runs after insert or update on teams_plays table
  CALL nba.sync_teams_from_teams_plays();
  RETURN NULL; -- RETURN NULL is sufficient for AFTER statement trigger
END;
$$;

-- =========================================
-- 4️⃣ Create Trigger
-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trg_sync_teams ON nba.teams_plays;

-- Trigger definition
CREATE TRIGGER trg_sync_teams
AFTER INSERT OR UPDATE ON nba.teams_plays  -- Fires after insert or update
FOR EACH STATEMENT                             -- Statement-level: SP runs only once per statement, even for bulk inserts
EXECUTE FUNCTION nba.trigger_sync_teams();    -- Calls the trigger function defined above

-- =========================================
-- Now, whenever data is inserted into teams_plays, nba.teams will be updated automatically
-- Example usage:
-- INSERT INTO nba.teams_plays (...)
-- VALUES (...);
-- The trigger will fire and update the nba.teams table