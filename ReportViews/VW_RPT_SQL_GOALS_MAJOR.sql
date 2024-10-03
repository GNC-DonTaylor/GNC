CREATE OR ALTER VIEW [DBO].[VW_RPT_SQL_GOALS_MAJOR]
AS
--Major Goals
SELECT
G.REPORTGROUP, 
CAST(G.SALEYEAR AS INT) AS SALEYEAR, 
CAST(G.DIVISIONNUMBER AS VARCHAR(12)) AS WAREHOUSEID, 
G.DIVISIONNAME AS WAREHOUSENAME, 
CAST(G.GROUPNUMBER AS VARCHAR(12)) AS GROUPNUMBER,
CAST(TRIM(G.GROUPNAME) AS VARCHAR(50)) AS GROUPNAME,
--JOANNE ADDED DATA W/O NATIONALACCOUNT VALUES, I AM DEFAULTING THEM TO 'Y' FOR NOW.
--CAST(G.NATIONALACCOUNT AS VARCHAR(10)) AS NATIONALACCOUNT,
CAST(ISNULL(G.NATIONALACCOUNT,'Y') AS VARCHAR(10)) AS NATIONALACCOUNT,
G.AMOUNT
FROM GOALS_GROUP G (NOLOCK)
