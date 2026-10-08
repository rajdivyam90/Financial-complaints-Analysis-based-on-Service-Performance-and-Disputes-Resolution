
--Q: Combining Complaints and State into one table

SELECT C.*,S.State_Name INTO COMPLAINTS_FINAL
FROM Consumer_Complaints AS C
INNER JOIN State_Code_Name AS S
ON C.State=S.Code

--Q: Identify the top 3 drivers for complaints across the products.

WITH ISSUE_RANK AS (
                    SELECT Product,Issue,COUNT([Complaint ID]) AS TOTAL_COUNT,
                    DENSE_RANK() OVER (PARTITION BY PRODUCT ORDER BY COUNT([Complaint ID]) DESC) AS RANKS
                    FROM Complaints
                    GROUP BY Product,Issue
                                           )
SELECT PRODUCT,ISSUE,TOTAL_COUNT
FROM ISSUE_RANK
WHERE RANKS<=3

--Q: Evaluate company response speed across different channels and measure whether a timely response was provided or not?

SELECT [Submitted via] AS CHANNEL,
COUNT([Complaint ID]) AS TOTAL_COMPLAINTS,
100.0*COUNT([Complaint ID])/(SELECT COUNT([Complaint ID]) FROM COMPLAINTS_FINAL) AS COMPLAINT_PERC,
ROUND(AVG(DATEDIFF(DAY,[Date received],[Date resolved])),2) AS AVG_RESOLUTION_DAYS,
ROUND(CAST((100.0*SUM(CASE
                      WHEN [TIMELY RESPONSE?]='No' THEN 1
                      ELSE 0
                      END)/COUNT([COMPLAINT ID])) AS FLOAT),3) AS RESPONSE_PERC
FROM COMPLAINTS_FINAL
GROUP BY [Submitted via]
ORDER BY COMPLAINT_PERC DESC

--Q: Rank company by their consumer dispute rate and highlight high risk companies.

SELECT Company,
COUNT([COMPLAINT ID]) AS TOT_COMPLAINTS,
SUM(CASE 
    WHEN [CONSUMER DISPUTED?]='Yes'
    THEN 1 ELSE 0
    END) AS DISPUTED_COMPLAINTS,
ROUND((100.0*SUM(CASE 
    WHEN [CONSUMER DISPUTED?]='Yes'
    THEN 1 ELSE 0
    END)/COUNT([COMPLAINT ID])),2) AS DISPUTE_RATE
FROM COMPLAINTS_FINAL
GROUP BY Company
HAVING COUNT([COMPLAINT ID])>=10
ORDER BY DISPUTE_RATE DESC;

--Q: Show complaint volume shift across fiscal quarters and see if there are any seasonal spikes.

SELECT YEAR,
CONCAT('Q',QUARTER) AS QUARTERS,
CURRENT_COMPLAINTS_PER_QTR,
LAG(CURRENT_COMPLAINTS_PER_QTR,1) OVER (ORDER BY YEAR, QUARTER) AS PREVIOUS_COMPLAINT_PER_QTR,
(100*(CURRENT_COMPLAINTS_PER_QTR- LAG(CURRENT_COMPLAINTS_PER_QTR,1) OVER (ORDER BY YEAR, QUARTER)))
/LAG(CURRENT_COMPLAINTS_PER_QTR,1) OVER (ORDER BY YEAR, QUARTER) AS QoQ_GROWTH_RATE
FROM (
      SELECT YEAR([DATE RECEIVED]) AS YEAR,
      DATEPART(QUARTER,[Date received]) AS QUARTER,
      COUNT([COMPLAINT ID]) AS CURRENT_COMPLAINTS_PER_QTR
      FROM COMPLAINTS_FINAL
      GROUP BY YEAR([DATE RECEIVED]),DATEPART(QUARTER,[Date received])
) AS X
ORDER BY YEAR,QUARTER

--Q: Categorize complaints into service level agreement buckets to see which resolution buckets cause highest delays.

SELECT CASE
       WHEN DATEDIFF(DAY,[Date received],[Date resolved]) = 0
       THEN 'SAME DAY'
       WHEN DATEDIFF(DAY,[Date received],[Date resolved]) BETWEEN 1 AND 7
       THEN '1-7 DAYS'
       WHEN DATEDIFF(DAY,[Date received],[Date resolved]) BETWEEN 8 AND 30
       THEN '8-30 DAYS'
       ELSE '30+ DAYS'
       END AS RES_DAYS_BUCKET,
COUNT([COMPLAINT ID]) AS TOTAL_COMPLAINTS,
ROUND(100.0*COUNT([COMPLAINT ID])/SUM(COUNT([COMPLAINT ID])) OVER(),2) AS PERC_TOT_COMPLAINTS
FROM COMPLAINTS_FINAL
GROUP BY CASE
       WHEN DATEDIFF(DAY,[Date received],[Date resolved]) = 0
       THEN 'SAME DAY'
       WHEN DATEDIFF(DAY,[Date received],[Date resolved]) BETWEEN 1 AND 7
       THEN '1-7 DAYS'
       WHEN DATEDIFF(DAY,[Date received],[Date resolved]) BETWEEN 8 AND 30
       THEN '8-30 DAYS'
       ELSE '30+ DAYS'
       END
ORDER BY RES_DAYS_BUCKET


--Q: Show complaint density by state and determine which states contribute more to complaints volume.

SELECT State_Name,
COUNT([COMPLAINT ID]) AS COMPLAINT_COUNT,
100.0*COUNT([COMPLAINT ID])/SUM(COUNT([COMPLAINT ID])) OVER () AS PERC_VOLUME
FROM COMPLAINTS_FINAL
GROUP BY State_Name
ORDER BY COMPLAINT_COUNT DESC


--Q: Evaluate which products are prone to customer disputes

SELECT Product,
SUM(CASE 
    WHEN [CONSUMER DISPUTED?]='Yes'
    THEN 1 ELSE 0
    END) AS DISPUTED_COMPLAINTS
FROM COMPLAINTS_FINAL
GROUP BY Product
ORDER BY DISPUTED_COMPLAINTS DESC


--Q: Which channels receive major part of complaints and whats the percentage.

SELECT [Submitted via],
COUNT([COMPLAINT ID]) AS TOTAL_COMPLAINTS
FROM COMPLAINTS_FINAL
GROUP BY [Submitted via]
ORDER BY TOTAL_COMPLAINTS DESC


/*Q: What is the number of complaints and their percentage where timely response was not provided? show a company wise analysis to show best
performing companies*/


SELECT Company,
COUNT([COMPLAINT ID]) AS TOT_COMPLAINTS,
100*SUM(CASE
     WHEN [TIMELY RESPONSE?]='No' THEN 1
     ELSE 0
     END)/COUNT([COMPLAINT ID]) AS RESPONSE_PERC
FROM COMPLAINTS_FINAL
GROUP BY Company
ORDER BY RESPONSE_PERC


--Q: Show a product wise analysis of resolution days to determine which products are taking longer to resolve.

SELECT PRODUCT,
AVG(DATEDIFF(DAY,[Date received],[Date resolved])) AS RESOLUTION_DAYS
FROM COMPLAINTS_FINAL
GROUP BY Product
ORDER BY RESOLUTION_DAYS DESC


--Q: Calculate the dispute rate.

SELECT
100.0*(SUM(CASE 
    WHEN [CONSUMER DISPUTED?]='Yes'
    THEN 1 ELSE 0
    END))/(SELECT COUNT (*) FROM COMPLAINTS_FINAL) AS DISPUTED_COMPLAINTS
FROM COMPLAINTS_FINAL


SELECT *
FROM COMPLAINTS_FINAL
