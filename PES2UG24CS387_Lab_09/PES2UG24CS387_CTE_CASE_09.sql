-- Q1: Resident Payment Leaders

WITH CurrentResidents AS (
SELECT A.Hostel_ID, A.Student_ID,
CONCAT(S.First_Name, ' ', S.Last_Name) AS Student_Name
FROM ALLOCATE A
JOIN STUDENT S ON S.Student_ID = A.Student_ID
WHERE A.Check_in_Date IS NOT NULL
AND A.Check_out_Date IS NULL
),
ResidentTotals AS (
SELECT CR.Hostel_ID, CR.Student_ID, CR.Student_Name,
COALESCE(SUM(P.Amount), 0) AS Resident_Total
FROM CurrentResidents CR
LEFT JOIN PAYMENT P ON P.Student_ID = CR.Student_ID
GROUP BY CR.Hostel_ID, CR.Student_ID, CR.Student_Name
),
HostelAverages AS (
SELECT H.Hostel_ID, H.Hostel_Name,
COALESCE(AVG(RT.Resident_Total), 0) AS Hostel_Avg
FROM HOSTEL H
LEFT JOIN ResidentTotals RT ON RT.Hostel_ID = H.Hostel_ID
GROUP BY H.Hostel_ID, H.Hostel_Name
),
CampusBenchmark AS (
SELECT COALESCE(AVG(Resident_Total), 0) AS Benchmark
FROM ResidentTotals
),
LargestPayers AS (
SELECT Hostel_ID, MAX(Resident_Total) AS Max_Resident_Total
FROM ResidentTotals
GROUP BY Hostel_ID
)
SELECT HA.Hostel_ID, HA.Hostel_Name,
ROUND(HA.Hostel_Avg, 2) AS Hostel_Avg,
ROUND(CB.Benchmark, 2) AS Benchmark,
RT.Student_ID, RT.Student_Name,
ROUND(RT.Resident_Total, 2) AS Resident_Total
FROM HostelAverages HA
CROSS JOIN CampusBenchmark CB
JOIN ResidentTotals RT ON RT.Hostel_ID = HA.Hostel_ID
JOIN LargestPayers LP
ON LP.Hostel_ID = RT.Hostel_ID
AND LP.Max_Resident_Total = RT.Resident_Total
WHERE HA.Hostel_Avg > CB.Benchmark
ORDER BY HA.Hostel_ID, RT.Student_ID;

-- Q2: Superior Salary Inversions

WITH RECURSIVE StaffAncestors AS (
SELECT S.Staff_ID, S.Supervisor_ID AS Ancestor_ID,
CAST(CONCAT('/', S.Staff_ID, '/', S.Supervisor_ID, '/')
AS CHAR(2000)) AS Path
FROM STAFF S
WHERE S.Supervisor_ID IS NOT NULL

UNION ALL

SELECT SA.Staff_ID, Supervisor.Supervisor_ID AS Ancestor_ID,
       CONCAT(SA.Path, Supervisor.Supervisor_ID, '/') AS Path
FROM StaffAncestors SA
JOIN STAFF Supervisor ON Supervisor.Staff_ID = SA.Ancestor_ID
WHERE Supervisor.Supervisor_ID IS NOT NULL
  AND LOCATE(CONCAT('/', Supervisor.Supervisor_ID, '/'),
             SA.Path) = 0

),
InversionSummary AS (
SELECT S.Staff_ID, S.Name, S.Salary,
SUM(CASE WHEN S.Salary > A.Salary THEN 1 ELSE 0 END)
AS Inversion_Count,
MAX(CASE WHEN S.Salary > A.Salary
THEN S.Salary - A.Salary
ELSE NULL END) AS Max_Gap
FROM STAFF S
JOIN StaffAncestors SA ON SA.Staff_ID = S.Staff_ID
JOIN STAFF A ON A.Staff_ID = SA.Ancestor_ID
GROUP BY S.Staff_ID, S.Name, S.Salary
)
SELECT Staff_ID, Name, Salary, Inversion_Count,
ROUND(Max_Gap, 2) AS Max_Gap
FROM InversionSummary
WHERE Inversion_Count > 0
ORDER BY Inversion_Count DESC, Staff_ID;

-- Q3: Room Occupancy Reconciliation

WITH BedCounts AS (
SELECT Hostel_ID, Room_Number, COUNT() AS Total_Beds,
SUM(CASE WHEN Availability = 'N' THEN 1 ELSE 0 END) AS Flags
FROM BED
GROUP BY Hostel_ID, Room_Number
),
ResidentCounts AS (
SELECT Hostel_ID, Room_Number, COUNT() AS Residents
FROM ALLOCATE
WHERE Check_in_Date IS NOT NULL
AND Check_out_Date IS NULL
GROUP BY Hostel_ID, Room_Number
),
RoomReconciliation AS (
SELECT R.Hostel_ID, R.Room_Number,
COALESCE(B.Total_Beds, 0) AS Total_Beds,
COALESCE(B.Flags, 0) AS Flags,
COALESCE(RC.Residents, 0) AS Residents,
CASE
WHEN COALESCE(B.Total_Beds, 0) = 0 THEN 'NO_BEDS'
WHEN COALESCE(B.Flags, 0) = COALESCE(RC.Residents, 0)
THEN 'MATCH'
WHEN COALESCE(B.Flags, 0) > COALESCE(RC.Residents, 0)
THEN 'FLAGS_EXCEED'
ELSE 'RESIDENTS_EXCEED'
END AS Reconciliation_Status,
COALESCE(RC.Residents, 0) - COALESCE(B.Flags, 0)
AS Correction
FROM ROOM R
LEFT JOIN BedCounts B
ON B.Hostel_ID = R.Hostel_ID
AND B.Room_Number = R.Room_Number
LEFT JOIN ResidentCounts RC
ON RC.Hostel_ID = R.Hostel_ID
AND RC.Room_Number = R.Room_Number
)
SELECT H.Hostel_ID, H.Hostel_Name,
SUM(CASE WHEN RR.Reconciliation_Status = 'NO_BEDS'
THEN 1 ELSE 0 END) AS No_Beds_Rooms,
SUM(CASE WHEN RR.Reconciliation_Status = 'MATCH'
THEN 1 ELSE 0 END) AS Match_Rooms,
SUM(CASE WHEN RR.Reconciliation_Status = 'FLAGS_EXCEED'
THEN 1 ELSE 0 END) AS Flags_Exceed_Rooms,
SUM(CASE WHEN RR.Reconciliation_Status = 'RESIDENTS_EXCEED'
THEN 1 ELSE 0 END) AS Residents_Exceed_Rooms,
SUM(RR.Correction) AS Net_Correction
FROM HOSTEL H
LEFT JOIN RoomReconciliation RR ON RR.Hostel_ID = H.Hostel_ID
GROUP BY H.Hostel_ID, H.Hostel_Name
ORDER BY H.Hostel_ID;

-- Q4: Staff Salary Revision

WITH RECURSIVE RaisedSalaries AS (
SELECT Staff_ID, Name, Salary, Hostel_ID, Supervisor_ID,
CASE
WHEN Salary < 25000 THEN ROUND(Salary * 1.12, 2)
WHEN Salary < 35000 THEN ROUND(Salary * 1.08, 2)
ELSE ROUND(Salary * 1.05, 2)
END AS Raised_Salary
FROM STAFF
),
RevisedStaff AS (
SELECT RS.Staff_ID, RS.Name, RS.Salary, RS.Hostel_ID,
RS.Supervisor_ID, RS.Raised_Salary,
RS.Raised_Salary AS Revised_Salary
FROM RaisedSalaries RS
WHERE RS.Supervisor_ID IS NULL

UNION ALL

SELECT Child.Staff_ID, Child.Name, Child.Salary, Child.Hostel_ID,
       Child.Supervisor_ID, Child.Raised_Salary,
       ROUND(LEAST(Child.Raised_Salary, Parent.Revised_Salary), 2)
           AS Revised_Salary
FROM RaisedSalaries Child
JOIN RevisedStaff Parent ON Child.Supervisor_ID = Parent.Staff_ID

),
HostelPayroll AS (
SELECT H.Hostel_ID, H.Hostel_Name,
SUM(RS.Salary) AS Current_Payroll,
SUM(RS.Revised_Salary) AS Revised_Payroll
FROM HOSTEL H
LEFT JOIN RevisedStaff RS ON RS.Hostel_ID = H.Hostel_ID
GROUP BY H.Hostel_ID, H.Hostel_Name
)
SELECT Hostel_ID, Hostel_Name,
ROUND(COALESCE(Current_Payroll, 0), 2) AS Current_Payroll,
ROUND(COALESCE(Revised_Payroll, 0), 2) AS Revised_Payroll,
ROUND(COALESCE(Revised_Payroll, 0)
- COALESCE(Current_Payroll, 0), 2) AS Increase
FROM HostelPayroll
ORDER BY Hostel_ID;

-- Q5: Facility Engagement Profile

WITH CurrentResidents AS (
SELECT Hostel_ID, Student_ID
FROM ALLOCATE
WHERE Check_in_Date IS NOT NULL
AND Check_out_Date IS NULL
),
ResidentEngagement AS (
SELECT CR.Hostel_ID, CR.Student_ID,
COUNT(DISTINCT F.Facility_ID) AS Home_Facility_Count
FROM CurrentResidents CR
LEFT JOIN USES U ON U.Student_ID = CR.Student_ID
LEFT JOIN FACILITY F
ON F.Facility_ID = U.Facility_ID
AND F.Hostel_ID = CR.Hostel_ID
GROUP BY CR.Hostel_ID, CR.Student_ID
),
ClassifiedResidents AS (
SELECT Hostel_ID, Student_ID,
CASE
WHEN Home_Facility_Count = 0 THEN 'Inactive'
WHEN Home_Facility_Count = 1 THEN 'Low'
WHEN Home_Facility_Count = 2 THEN 'Medium'
ELSE 'High'
END AS Engagement_Class
FROM ResidentEngagement
),
ClassCounts AS (
SELECT Hostel_ID, Engagement_Class, COUNT(*) AS Resident_Count
FROM ClassifiedResidents
GROUP BY Hostel_ID, Engagement_Class
)
SELECT CC.Hostel_ID, CC.Engagement_Class, CC.Resident_Count
FROM ClassCounts CC
WHERE CC.Resident_Count = (
SELECT MAX(CC2.Resident_Count)
FROM ClassCounts CC2
WHERE CC2.Hostel_ID = CC.Hostel_ID
)
ORDER BY CC.Hostel_ID, CC.Engagement_Class;

-- Q6: Daily Fee Ledger

WITH RECURSIVE
CurrentResidents AS (
SELECT Student_ID, Hostel_ID, Room_Number, Check_in_Date
FROM ALLOCATE
WHERE Check_in_Date IS NOT NULL
AND Check_out_Date IS NULL
AND Check_in_Date <= '2025-08-20'
),
PaymentByDay AS (
SELECT Student_ID, Payment_Date, SUM(Amount) AS Payment_Amount
FROM PAYMENT
WHERE Payment_Date <= '2025-08-20'
GROUP BY Student_ID, Payment_Date
),
InitialPayments AS (
SELECT CR.Student_ID, COALESCE(SUM(P.Amount), 0) AS Total_Payments
FROM CurrentResidents CR
LEFT JOIN PAYMENT P
ON P.Student_ID = CR.Student_ID
AND P.Payment_Date <= CR.Check_in_Date
GROUP BY CR.Student_ID
),
Ledger (
Student_ID, Hostel_ID, Room_Number, Check_in_Date, Ledger_Date,
Days_Charged, Balance, Total_Late_Fees, Total_Payments_Applied
) AS (
SELECT CR.Student_ID, CR.Hostel_ID, CR.Room_Number,
CR.Check_in_Date, CR.Check_in_Date AS Ledger_Date,
1 AS Days_Charged,
CAST(
(100 - IP.Total_Payments)
+ CASE
WHEN 100 - IP.Total_Payments > 0
THEN ROUND((100 - IP.Total_Payments) * 0.02, 2)
ELSE 0
END
AS DECIMAL(14,2)
) AS Balance,
CAST(
CASE
WHEN 100 - IP.Total_Payments > 0
THEN ROUND((100 - IP.Total_Payments) * 0.02, 2)
ELSE 0
END AS DECIMAL(14,2)
) AS Total_Late_Fees,
CAST(IP.Total_Payments AS DECIMAL(14,2))
AS Total_Payments_Applied
FROM CurrentResidents CR
JOIN InitialPayments IP ON IP.Student_ID = CR.Student_ID

UNION ALL

SELECT L.Student_ID, L.Hostel_ID, L.Room_Number, L.Check_in_Date,
       DATE_ADD(L.Ledger_Date, INTERVAL 1 DAY),
       L.Days_Charged + 1,
       CAST(
           (L.Balance + 100 - COALESCE(P.Payment_Amount, 0))
           + CASE
                 WHEN L.Balance + 100
                      - COALESCE(P.Payment_Amount, 0) > 0
                     THEN ROUND(
                         (L.Balance + 100
                          - COALESCE(P.Payment_Amount, 0)) * 0.02, 2
                     )
                 ELSE 0
             END AS DECIMAL(14,2)
       ) AS Balance,
       CAST(
           L.Total_Late_Fees
           + CASE
                 WHEN L.Balance + 100
                      - COALESCE(P.Payment_Amount, 0) > 0
                     THEN ROUND(
                         (L.Balance + 100
                          - COALESCE(P.Payment_Amount, 0)) * 0.02, 2
                     )
                 ELSE 0
             END AS DECIMAL(14,2)
       ) AS Total_Late_Fees,
       CAST(
           L.Total_Payments_Applied + COALESCE(P.Payment_Amount, 0)
           AS DECIMAL(14,2)
       ) AS Total_Payments_Applied
FROM Ledger L
LEFT JOIN PaymentByDay P
    ON P.Student_ID = L.Student_ID
   AND P.Payment_Date = DATE_ADD(L.Ledger_Date, INTERVAL 1 DAY)
WHERE L.Ledger_Date < '2025-08-20'

)
SELECT Student_ID, Hostel_ID, Room_Number, Days_Charged,
Days_Charged * 100 AS Total_Daily_Fees,
ROUND(Total_Late_Fees, 2) AS Total_Late_Fees,
ROUND(Total_Payments_Applied, 2) AS Total_Payments_Applied,
ROUND(Balance, 2) AS Final_Balance
FROM Ledger
WHERE Ledger_Date = '2025-08-20'
AND Total_Late_Fees > 0
ORDER BY Student_ID;
ORDER BY Student_ID;