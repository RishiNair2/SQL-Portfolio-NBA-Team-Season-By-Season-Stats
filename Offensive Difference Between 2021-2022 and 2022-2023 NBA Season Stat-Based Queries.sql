--- Difference Between 2021-2022 and 2022-2023 NBA Season Stat-Based Queries---

--- Offensive Stats---

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

SELECT teams, nba_2021_2022_record, nba_2022_2023_record, (wins_2023- wins_2022) win_differential
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
SELECT n.teams_post_23, (.96*((SUM(b.fgas) + SUM(b.turnover) + (.44*(SUM(b.ftas)))) - SUM(b.orebs))) possessions_22 ,
(.96*((SUM(n.fga_post_23) + SUM(n.tov_post_23) + (.44*(SUM(n.fta_post_23)))) - SUM(n.oreb_post_23))) possessions_23,
(.96*((SUM(n.fga_post_23) + SUM(n.tov_post_23) + (.44*(SUM(n.fta_post_23)))) - SUM(n.oreb_post_23))) - (.96*((SUM(b.fgas) + SUM(b.turnover) + (.44*(SUM(b.ftas)))) - SUM(b.orebs))) poss_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Highest Points Per Possessions and Their PPP Differential---
WITH t1 AS(
SELECT n.teams_post_23 teams, SUM(points_post_23) tot_points_23, (.96*((SUM(fga_post_23) + SUM(tov_post_23) + (.44*(SUM(fta_post_23)))) - SUM(oreb_post_23))) possessions_23
FROM nba_2022_2023_szns AS n
GROUP BY 1),

t2 AS(
SELECT b.team team, SUM(point) tot_points_22, (.96*((SUM(b.fgas) + SUM(b.turnover) + (.44*(SUM(b.ftas)))) - SUM(b.orebs))) possessions_22
FROM nba_2021_2022_szn AS b
GROUP BY 1)

SELECT teams, (tot_points_22 * 100/possessions_22) ppp_22, (tot_points_23 * 100/possessions_23) ppp_23, 
(tot_points_23 * 100/possessions_23) - (tot_points_22 * 100/possessions_22) ppp_diff
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY 4 DESC;

--- Team With The Most Points Per Game and Their Point Differential---
SELECT n.teams_post_23, ROUND(AVG(b.point),1) nba_2021_2022_ppg , ROUND(AVG(n.points_post_23),1) nba_2022_2023_ppg,
(AVG(n.points_post_23) - AVG(b.point)) ppg_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Running Averages of The Points Per Game For Each Team---
SELECT n.teams_post_23, n.points_post_23, AVG(n.points_post_23) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row),
b.point, AVG(b.point) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most 3PA Per Game and Their 3PA Differential---
SELECT n.teams_post_23, ROUND(AVG(b.tpas),1) nba_2021_2022_tpa , ROUND(AVG(n.tpa_post_23),1) nba_2022_2023_tpa,
(AVG(n.tpa_post_23) - AVG(b.tpas)) tpa_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Running Averages of The 3 Point Attempts For Each Team---
SELECT n.teams_post_23, n.tpa_post_23, AVG(n.tpa_post_23) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row),
b.turnover, AVG(b.turnover) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most 2PA Per Game and Their 2PA Differential---
SELECT n.teams_post_23, ROUND(AVG(b.fgas) - AVG(b.tpas),1) nba_2021_2022_two_pa , ROUND(AVG(n.fga_post_23) - AVG(n.tpa_post_23),1) nba_2022_2023_two_pa,
ROUND((AVG(b.fgas) - AVG(b.tpas)) - (AVG(n.fga_post_23) - AVG(n.tpa_post_23)),1)  two_pa_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most FTA Per Game and Their FTA Differential---
SELECT n.teams_post_23, ROUND(AVG(b.ftas),1) nba_2021_2022_fta , ROUND(AVG(n.fta_post_23),1) nba_2022_2023_fta,
(AVG(n.fta_post_23) - AVG(b.ftas)) fta_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Running Averages of The Free Throw Attempts For Each Team---
SELECT n.teams_post_23, n.fta_post_23, AVG(n.fta_post_23) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row),
b.ftas, AVG(b.ftas) OVER (PARTITION BY n.teams_post_23 Rows BETWEEN UNBOUNDED PRECEDING AND Current Row)
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Most AST Per Game and Their AST Differential---
SELECT n.teams_post_23, ROUND(AVG(b.asts),1) nba_2021_2022_ast , ROUND(AVG(n.ast_post_23),1) nba_2022_2023_ast,
(AVG(n.ast_post_23) - AVG(b.asts)) ast_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Highest FG % Per Game and Their FG % Differential---
SELECT n.teams_post_23, (SUM(b.fgms)*100/SUM(b.fgas)) nba_2021_2022_fg_pct , (SUM(n.fgm_post_23)*100/SUM(n.fga_post_23)) nba_2022_2023_fg_pct,
(SUM(b.fgms)/SUM(b.fgas) - SUM(n.fgm_post_23)/SUM(n.fga_post_23)) fg_pct_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Highest 3FG % Per Game and Their 3FG % Differential---
SELECT n.teams_post_23, (SUM(b.tpms)*100/SUM(b.tpas)) nba_2021_2022_tp_pct , (SUM(n.tpm_post_23)*100/SUM(n.tpa_post_23)) nba_2022_2023_tp_pct,
(SUM(b.tpms)/SUM(b.tpas) - SUM(n.tpm_post_23)/SUM(n.tpa_post_23)) tp_pct_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- Team With The Highest 2FG % Per Game and Their 2FG % Differential---
SELECT n.teams_post_23, ((SUM(b.fgms) - SUM(b.tpms))/(SUM(b.fgas) - SUM(b.tpas)))*100 nba_2021_2022_2fg_pct , (SUM(n.fgm_post_23) - SUM(n.tpm_post_23))/(SUM(n.fga_post_23) - SUM(n.tpa_post_23))*100 nba_2022_2023_2fg_pct,
(SUM(n.fgm_post_23) - SUM(n.tpm_post_23))/(SUM(n.fga_post_23) - SUM(n.tpa_post_23)) - ((SUM(b.fgms) - SUM(b.tpms))/(SUM(b.fgas) - SUM(b.tpas))) *10  two_fg_pct_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;


--- Team With The Highest FT % Per Game and Their FT% Differential---
SELECT n.teams_post_23, (SUM(b.ftms)*100/SUM(b.ftas)) nba_2021_2022_ft_pct , (SUM(n.ftm_post_23)*100/SUM(n.fta_post_23)) nba_2022_2023_ft_pct,
(SUM(b.ftms)/SUM(b.ftas) - SUM(n.ftm_post_23)/SUM(n.fta_post_23))*100 ft_pct_differential
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- The Percentage of Free Throw Baskets That Contribute To The Overall Teams Points and Their Differential---
SELECT n.teams_post_23, (SUM(b.ftms))*100/SUM(b.point) free_throw_points_scored_22  ,(SUM(n.ftm_post_23))*100/SUM(n.points_post_23) free_throw_points_scored_23,
(SUM(n.ftm_post_23))*100/SUM(n.points_post_23) - (SUM(b.ftms))*100/SUM(b.point) ft_contribution_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- The Percentage of 3PT Baskets That Contribute To The Overall Teams Points and Their Differential---
SELECT n.teams_post_23, (SUM(b.tpms))*100/SUM(b.point) three_points_scored_22  ,(SUM(n.tpm_post_23))*100/SUM(n.points_post_23) three_points_scored_23,
(SUM(n.tpm_post_23))*100/SUM(n.points_post_23) - (SUM(b.tpms))*100/SUM(b.point) three_point_contribution_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;

--- The Percentage of 2PT Baskets That Contribute To The Overall Teams Points and Their Differential---
WITH t1 AS(
SELECT t23.teams_post_23 teams, AVG(t23.tot_two_pt_makes / t23.two_point_attempts)*100 two_point_percent_23
FROM(
SELECT teams_post_23, SUM(fgm_post_23) - SUM(tpm_post_23) tot_two_pt_makes , 
(SUM(fga_post_23) - SUM(tpa_post_23)) two_point_attempts
FROM post_all_star_break_2023
GROUP BY 1) t23
GROUP BY 1),

t2 AS(
SELECT t22.team team, AVG(t22.tot_two_pt_makes_22 / t22.two_point_attempts_22)*100 two_point_percent_22
FROM(
SELECT team, SUM(fgms) - SUM(tpms) tot_two_pt_makes_22 , 
(SUM(fgas) - SUM(tpas)) two_point_attempts_22
FROM all_star_break_2022
GROUP BY 1) t22
GROUP BY 1
)

SELECT teams, two_point_percent_22, two_point_percent_23, two_point_percent_23 - two_point_percent_22 two_pt_diff
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY 4 DESC;

--- Teams With Highest True Shooting Percentage And Their Differential
--- Pts / (2 * (FGA + .475 * FTA)) --- 
WITH t1 AS(
SELECT t23.teams_post_23 teams, AVG(ts_percentage) avg_ts_percentage_23
FROM(
SELECT teams_post_23, (points_post_23 *100/(2*(fga_post_23 + .475*fta_post_23))) ts_percentage 
FROM post_all_star_break_2023) t23
GROUP BY t23.teams_post_23),

t2 AS(
SELECT t22.team, AVG(ts_percentage) avg_ts_percentage_22
FROM(
SELECT team, (point *100/(2*(fgas + .475*ftas))) ts_percentage 
FROM all_star_break_2022) t22
GROUP BY 1
)

SELECT teams, avg_ts_percentage_22, avg_ts_percentage_23, avg_ts_percentage_23 - avg_ts_percentage_22 ts_diff
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY 4 DESC;

--- Teams With Highest Effective Field Goal Percentage And Their Differential
--- (FG + .5 * 3P) / FGA --- 
WITH t1 AS(
SELECT t23.teams_post_23 teams, AVG(t23.efg) * 100 avg_efg_23
FROM(
SELECT teams_post_23, ((fgm_post_23 + (.5*tpm_post_23))/(fga_post_23)) efg
FROM post_all_star_break_2023) t23
GROUP BY 1),

t2 AS(
SELECT t22.team, AVG(t22.efg) * 100 avg_efg_22
FROM(
SELECT team, ((fgms + (.5*tpms))/(fgas)) efg
FROM all_star_break_2022) t22
GROUP BY 1
)

SELECT teams, avg_efg_22, avg_efg_23, avg_efg_23 - avg_efg_22 efg_diff
FROM t1
JOIN t2
ON t1.teams = t2.team
ORDER BY 4 DESC;

--- Team With The Highest Ast/Tov Ratio and Their Differential---
SELECT n.teams_post_23, (SUM(b.asts)/SUM(b.turnover)) ast_tov_ratio_22 ,(SUM(n.ast_post_23)/SUM(n.tov_post_23)) ast_tov_ratio_23,
(SUM(n.ast_post_23)/SUM(n.tov_post_23)) - (SUM(b.asts)/SUM(b.turnover)) ast_tov_ratio_diff
FROM nba_2022_2023_szns AS n
JOIN nba_2021_2022_szn AS b
ON n.teams_post_23 = b.team
GROUP BY 1
ORDER BY 4 DESC;