--- Difference Between 2021-2022 and 2022-2023 NBA Season Stat-Based Queries---

--- Defensive/Misc Stats---

--- Initial View 2021-2022 NBA Season---
CREATE VIEW nba_2021_2022_szn AS (
	SELECT team, game_dates, win_losses, minute, point, fgms, fgas, tpms, tpas, ftms, ftas, 
	orebs, drebs, rebs, asts, stls, blocks, turnover, foul, plus_minuses
	FROM all_star_break_2022
	
	UNION
	
	SELECT team_2022, game_date_2022, win_loss_2022, min_2022, pts_2022, fgm_2022, fga_2022, tpm_2022, tpa_2022, ftm_2022, fta_2022, 
	oreb_2022, dreb_2022, reb_2022, ast_2022, stl_2022, blk_2022, tov_2022, pf_2022, plus_minus_2022
	FROM post_all_star_break_2022

)

--- Initial View 2022-2023 NBA Season---
CREATE VIEW nba_2022_2023_szns AS(
	
	SELECT teams_post_23, game_dates_post_23, win_loss_post_23, min_post_23, points_post_23, fgm_post_23, fga_post_23, tpm_post_23, tpa_post_23, ftm_post_23, fta_post_23, 
	oreb_post_23, dreb_post_23, reb_post_23, ast_post_23, stl_post_23, blk_post_23, tov_post_23, pf_post_23, plus_minus_post_23
	FROM post_all_star_break_2023
	
	UNION
	
	SELECT team, game_date, win_loss, minutes, points, fgm, fga, tpm, tpa, ftm, fta, 
	oreb, dreb, reb, ast, stl, block, turnovers, fouls, plus_minus
	FROM all_star_break_2023
)

--- Initial Query---
SELECT n.*, b.* 
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
LIMIT 5;

--- The Team's W/L Record For Each Season And Their Win Differential ---
WITH t1 AS(
SELECT n.teams_post_23 teams, CONCAT(COUNT(CASE WHEN n.win_loss_post_23 = 'W' THEN 1  END), '-', 
							   COUNT(CASE WHEN n.win_loss_post_23 = 'L' THEN 1 END)) nba_2022_2023_record, COUNT(CASE WHEN n.win_loss_post_23 = 'W' THEN 1  END) wins_2023
FROM nba_2022_2023_szns AS n
GROUP BY 1),

t2 AS(
SELECT b.team team, CONCAT(COUNT(CASE WHEN b.win_losses = 'W' THEN 1  END), '-', 
							   COUNT(CASE WHEN b.win_losses = 'L' THEN 1 END)) nba_2021_2022_record, COUNT(CASE WHEN b.win_losses = 'W' THEN 1 END) wins_2022
FROM nba_2021_2022_szn AS b
GROUP BY 1)

SELECT teams, nba_2022_2023_record, nba_2021_2022_record, (wins_2023- wins_2022) win_differential
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY win_differential DESC;

--- Running Count of The Wins For Each Team---
WITH t1 AS(
SELECT n.teams_post_23 teams, CONCAT(COUNT(CASE WHEN n.win_loss_post_23 = 'W' THEN 1  END), '-', 
							   COUNT(CASE WHEN n.win_loss_post_23 = 'L' THEN 1 END)) nba_2022_2023_record, COUNT(CASE WHEN n.win_loss_post_23 = 'W' THEN 1  END) wins_2023
FROM nba_2022_2023_szns AS n
GROUP BY 1),

t2 AS(
SELECT b.team team, CONCAT(COUNT(CASE WHEN b.win_losses = 'W' THEN 1  END), '-', 
							   COUNT(CASE WHEN b.win_losses = 'L' THEN 1 END)) nba_2021_2022_record, COUNT(CASE WHEN b.win_losses = 'W' THEN 1 END) wins_2022
FROM nba_2021_2022_szn AS b
GROUP BY 1)

SELECT teams, wins_2022, (SUM(wins_2022) OVER (PARTITION BY teams Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)) rolling_wins_tot_22,
wins_2023, (SUM(wins_2023) OVER (PARTITION BY teams Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)) rolling_wins_tot_22
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY win_differential DESC;

--- Team With The Most Possessions and Their Possession Differential---
SELECT n.teams_post_23, (.96*((SUM(b.fgas) + SUM(b.turnover) + (.44*(SUM(b.ftas)))) - SUM(b.orebs))) possessions_2021_2022, 
(.96*((SUM(n.fga_post_23) + SUM(n.tov_post_23) + (.44*(SUM(n.fta_post_23)))) - SUM(n.oreb_post_23))) possessions_2022_2023,
((.96*((SUM(n.fga_post_23) + SUM(n.tov_post_23) + (.44*(SUM(n.fta_post_23)))) - SUM(n.oreb_post_23))) - (.96*((SUM(b.fgas) + SUM(b.turnover) + (.44*(SUM(b.ftas)))) - SUM(b.orebs)))) possession_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most Rebounds Per Game And Their Reb Differential---
SELECT n.teams_post_23, ROUND(AVG(b.rebs),1) reb_22, ROUND(AVG(n.reb_post_23),1) reb_23
(ROUND(AVG(n.reb_post_23),1) - ROUND(AVG(b.rebs),1)) reb_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY reb_diff DESC;

--- Team With The Most Defensive Rebounds Per Game And Their Oreb Differential---
SELECT n.teams_post_23, ROUND(AVG(b.drebs),1) dreb_22, ROUND(AVG(n.dreb_post_23),1) dreb_23,
(ROUND(AVG(n.dreb_post_23),1) - ROUND(AVG(b.drebs),1)) dreb_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY dreb_diff DESC;

---- Team With The Highest Defensive Rebound Percentage---
SELECT n.teams_post_23, (SUM(b.drebs)*100/SUM(b.rebs)) dreb_pct_22, SUM(n.dreb_post_23)*100/SUM(n.reb_post_23) dreb_pct_23,
SUM(n.dreb_post_23)*100/SUM(n.reb_post_23) - (SUM(b.drebs)*100/SUM(b.rebs)) dreb_pct_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Running Averages of The Defensive Rebounds For Each Team---
SELECT n.teams_post_23, n.dreb_post_23, AVG(n.teams_post_23) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row),
b.drebs, AVG(b.drebs) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most Offensive Rebounds Per Game And Their Oreb Differential---
SELECT n.teams_post_23, ROUND(AVG(b.orebs),1) oreb_22, ROUND(AVG(n.oreb_post_23),1) oreb_23
(ROUND(AVG(n.oreb_post_23),1) - ROUND(AVG(b.orebs),1)) oreb_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY oreb_diff DESC;

--- Running Averages of The Offensive Rebounds For Each Team---
SELECT n.teams_post_23, n.oreb_post_23, AVG(n.oreb_post_23) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row),
b.orebs, AVG(b.orebs) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

---- Team With The Highest Offensive Rebound Percentage---
SELECT n.teams_post_23, (SUM(b.orebs)*100/SUM(b.rebs)) oreb_pct_22, SUM(n.oreb_post_23)*100/SUM(n.reb_post_23) oreb_pct_23,
SUM(n.oreb_post_23)*100/SUM(n.reb_post_23) - (SUM(b.orebs)*100/SUM(b.rebs)) oreb_pct_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most Steals Per Game And Their Stl Differential---
SELECT n.teams_post_23, ROUND(AVG(b.stls),1) stl_22, ROUND(AVG(n.stl_post_23),1) stl_23,
(ROUND(AVG(n.stl_post_23),1) - ROUND(AVG(b.stls),1)) stl_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most Blocks Per Game And Their Blk Differential---
SELECT n.teams_post_23, ROUND(AVG(b.blocks),1) blk_22, ROUND(AVG(n.blk_post_23),1) blk_23,
(ROUND(AVG(n.blk_post_23),1) - ROUND(AVG(b.blocks),1)) blk_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most Turnovers Per Game And Their Tov Differential---
SELECT n.teams_post_23, ROUND(AVG(b.turnover),1) tov_22, ROUND(AVG(n.tov_post_23),1) tov_23,
(ROUND(AVG(n.tov_post_23),1) - ROUND(AVG(b.turnover),1)) tov_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Running Averages of The Turnovers For Each Team---
SELECT n.teams_post_23, n.turnover, AVG(n.turnover) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row),
b.tov_post_23, AVG(b.tov_post_23) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Highest Offensive Turnover Percentage---
--- The percentage of possessions that result in a turnover while a team is on offense---
WITH t1 AS(
SELECT n.teams_post_23 teams, (.96*((SUM(n.fga_post_23) + SUM(n.tov_post_23) + (.44*(SUM(n.fta_post_23)))) - SUM(n.oreb_post_23))) possessions_23,
	SUM(tov_post_23) tov_23
FROM nba_2022_2023_szns AS n
GROUP BY 1),

t2 AS(
SELECT b.team team, (.96*((SUM(b.fgas) + SUM(b.turnover) + (.44*(SUM(b.ftas)))) - SUM(b.orebs))) possessions_22, 
	SUM(turnover) tov_22
FROM nba_2021_2022_szn AS b	
GROUP BY 1)

SELECT teams, (tov_22*100/possessions_22) tov_pct_22, (tov_23*100/possessions_23) tov_pct_23, ((tov_23*100/possessions_23)- (tov_22*100/possessions_22)) tov_pct_differential
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY 4 DESC;

--- Team With The Highest Assist-to-Turnover Ratio And Their Ast/Tov Ratio Differential---
SELECT n.teams_post_23, (SUM(b.asts)/SUM(b.turnover)) ast_tov_ratio_22, (SUM(n.ast_post_23)/SUM(n.tov_post_23)) ast_tov_ratio_23,
(SUM(n.ast_post_23)/SUM(n.tov_post_23) - (SUM(b.asts)/SUM(b.turnover))) ast_tov_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;



--- Team With The Most Fouls Per Game And Their Fls Differential---
SELECT n.teams_post_23, ROUND(AVG(b.foul),1) fls_22, ROUND(AVG(n.pf_post_23),1) fls_23,
(ROUND(AVG(n.pf_post_23),1) - ROUND(AVG(b.foul),1)) fls_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most +/- Per Game And Their +/- Differential---
SELECT n.teams_post_23, ROUND(AVG(b.plus_minuses),1) plus_minus_22, ROUND(AVG(n.plus_minus_post_23),1) plus_minus_23,
(ROUND(AVG(n.plus_minus_post_23),1) - ROUND(AVG(b.plus_minuses),1)) plus_minus_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most Games Where They Had More Turnovers Than Assists---
WITH t1 AS(
SELECT n.teams_post_23 teams, COUNT(game_dates_post_23) games_23
FROM nba_2022_2023_szns AS n
WHERE tov_post_23 > ast_post_23	
GROUP BY 1),

t2 AS(
SELECT b.team team, COUNT(game_dates) games_22
FROM nba_2021_2022_szn AS b
WHERE turnover > asts	
GROUP BY 1)

SELECT teams, games_22, games_23, (games_23- games_22) gm_differential
FROM t1
LEFT JOIN t2
ON t1.teams = t2.team
ORDER BY 3 DESC;
