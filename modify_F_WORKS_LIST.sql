
IF OBJECT_ID('dbo.F_WORKS_LIST') IS NOT NULL
    DROP FUNCTION dbo.F_WORKS_LIST
GO

CREATE FUNCTION [dbo].[F_WORKS_LIST] (
)
RETURNS @RESULT TABLE
(
    ID_WORK INT,
    CREATE_Date DATETIME,
    MaterialNumber DECIMAL(8,2),
    IS_Complit BIT,
    FIO VARCHAR(255),
    D_DATE varchar(10),
    WorkItemsNotComplit int,
    WorkItemsComplit int,
    FULL_NAME VARCHAR(101),
    StatusId smallint,
    StatusName VARCHAR(255),
    Is_Print bit
)
AS
BEGIN
    -- CTE для подсчета WorkItems
    WITH WorkItemsCounts AS (
        SELECT 
            wi.Id_Work,
            SUM(CASE WHEN wi.Is_Complit = 0 AND a.Is_Group = 0 THEN 1 ELSE 0 END) AS WorkItemsNotComplit,
            SUM(CASE WHEN wi.Is_Complit = 1 AND a.Is_Group = 0 THEN 1 ELSE 0 END) AS WorkItemsComplit
        FROM 
            WorkItem wi
        INNER JOIN Analiz a ON wi.Id_Analiz = a.Id_Analiz
        GROUP BY 
            wi.Id_Work
    ),
    
    -- CTE для получения полных имен сотрудников
    EmployeeFullNames AS (
        SELECT 
            e.Id_Employee,
            ISNULL(RTRIM(e.Surname + ' ' + UPPER(SUBSTRING(e.Name, 1, 1)) + '. ' + 
                   UPPER(SUBSTRING(e.Patronymic, 1, 1)) + '.'), 
                   e.Login_Name) AS FULL_NAME
        FROM 
            Employee e
    )

    INSERT INTO @RESULT
    SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        ISNULL(w.FIO, '') AS FIO,
        CONVERT(VARCHAR(10), w.CREATE_Date, 104) AS D_DATE,
        ISNULL(wic.WorkItemsNotComplit, 0) AS WorkItemsNotComplit,
        ISNULL(wic.WorkItemsComplit, 0) AS WorkItemsComplit,
        ISNULL(efn.FULL_NAME, '') AS FULL_NAME,
        w.StatusId,
        ISNULL(ws.StatusName, '') AS StatusName,
        CASE
            WHEN w.Print_Date IS NOT NULL OR
                w.SendToClientDate IS NOT NULL OR
                w.SendToDoctorDate IS NOT NULL OR
                w.SendToOrgDate IS NOT NULL OR
                w.SendToFax IS NOT NULL
            THEN 1
            ELSE 0
        END AS Is_Print
    FROM
        Works w
    LEFT OUTER JOIN WorkItemsCounts wic ON w.Id_Work = wic.Id_Work
    LEFT OUTER JOIN WorkStatus ws ON w.StatusId = ws.StatusID
    LEFT OUTER JOIN EmployeeFullNames efn ON w.Id_Employee = efn.Id_Employee
    WHERE
        w.IS_DEL <> 1
    ORDER BY 
        w.Id_Work DESC
    
    RETURN
END
GO