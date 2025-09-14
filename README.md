# API_2_DB

# NBA Team Boxscore Sync

This repository provides Python scripts to fetch NBA team game data and boxscores using the [NBA API](https://github.com/swar/nba_api), normalize it, and upsert it into a PostgreSQL database.

## Features

- Fetch basic team-game stats for a given season
- Compute home/away, opponent points, and point difference
- Fetch detailed team boxscore stats
- Upsert data into PostgreSQL automatically
- Supports batch updates for the latest games

## Requirements

- Python 3.9+
- PostgreSQL
- Python packages in `requirements.txt`
