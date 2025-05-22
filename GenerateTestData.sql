-- Создание временных таблиц для генерации данных
CREATE TABLE #Names (Name VARCHAR(50));
INSERT INTO #Names VALUES ('Иван'), ('Пётр'), ('Сергей'), ('Алексей'), ('Дмитрий');

CREATE TABLE #Surnames (Surname VARCHAR(50));
INSERT INTO #Surnames VALUES ('Иванов'), ('Петров'), ('Сидоров'), ('Кузнецов'), ('Смирнов');

CREATE TABLE #Patronymics (Patronymic VARCHAR(50));
INSERT INTO #Patronymics VALUES ('Иванович'), ('Петрович'), ('Сергеевич'), ('Алексеевич'), ('Дмитриевич');

-- Генерация 100 сотрудников с уникальными логинами
INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, Archived, IS_Role, Role)
SELECT 
    LOWER(s.Surname + '_' + LEFT(n.Name,1) + LEFT(p.Patronymic,1) + '_' + CAST(nums.rn AS VARCHAR)) AS Login_Name,
    n.Name,
    p.Patronymic,
    s.Surname,
    LOWER(s.Surname + '.' + n.Name + '@example.com') AS Email,
    'Лаборант' AS Post,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 730), GETDATE()) AS CreateDate,
    0 AS Archived,
    0 AS IS_Role,
    0 AS Role
FROM 
    (SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn FROM master..spt_values) AS nums
CROSS APPLY 
    (SELECT TOP 1 Name FROM #Names ORDER BY NEWID()) AS n
CROSS APPLY 
    (SELECT TOP 1 Surname FROM #Surnames ORDER BY NEWID()) AS s
CROSS APPLY 
    (SELECT TOP 1 Patronymic FROM #Patronymics ORDER BY NEWID()) AS p;

-- Генерация 200 анализов
INSERT INTO Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, ID_ILL, Text_Norm, Price)
SELECT 
    0 AS IS_GROUP,
    ABS(CHECKSUM(NEWID()) % 5) + 1 AS MATERIAL_TYPE,
    'A' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR) AS CODE_NAME,
    'Анализ №' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR) AS FULL_NAME,
    ABS(CHECKSUM(NEWID()) % 10) + 1 AS ID_ILL,
    'Норма' AS Text_Norm,
    ROUND(100 + (RAND(CHECKSUM(NEWID())) * 900), 2) AS Price
FROM 
    (SELECT TOP 200 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn FROM master..spt_values) AS nums;

-- Генерация ФИО клиентов во временной таблице
CREATE TABLE #ClientFIO (FIO VARCHAR(255));
INSERT INTO #ClientFIO
SELECT s.Surname + ' ' + n.Name + ' ' + p.Patronymic
FROM 
    (SELECT TOP 1000 Surname FROM #Surnames ORDER BY NEWID()) AS s
CROSS APPLY 
    (SELECT TOP 1 Name FROM #Names ORDER BY NEWID()) AS n
CROSS APPLY 
    (SELECT TOP 1 Patronymic FROM #Patronymics ORDER BY NEWID()) AS p;

-- Генерация 50 000 заказов
INSERT INTO Works (IS_Complit, CREATE_Date, Id_Employee, FIO, MaterialNumber, Material_Get_Date, Material_Reg_Date, Is_Del, Price, StatusId)
SELECT 
    ABS(CHECKSUM(NEWID()) % 2) AS IS_Complit,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 730), GETDATE()) AS CREATE_Date,
    (SELECT TOP 1 Id_Employee FROM Employee ORDER BY NEWID()) AS Id_Employee,
    (SELECT TOP 1 FIO FROM #ClientFIO ORDER BY NEWID()) AS FIO,
    CAST(ABS(CHECKSUM(NEWID()) % 100000) AS DECIMAL(8,2)) AS MaterialNumber,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 730), GETDATE()) AS Material_Get_Date,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID()) % 730), GETDATE()) AS Material_Reg_Date,
    0 AS Is_Del,
    ROUND(100 + (RAND(CHECKSUM(NEWID())) * 900), 2) AS Price,
    ABS(CHECKSUM(NEWID()) % 3) + 1 AS StatusId
FROM 
    (SELECT TOP 50000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn FROM master..spt_values a CROSS JOIN master..spt_values b) AS nums;

-- Установка Close_Date для завершённых заказов
UPDATE Works
SET Close_Date = DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 30), CREATE_Date)
WHERE IS_Complit = 1;

-- Генерация элементов заказов (WorkItems)
DECLARE @WorkId INT, @ItemsCount INT;

DECLARE work_cursor CURSOR FOR 
SELECT Id_Work FROM Works;

OPEN work_cursor;
FETCH NEXT FROM work_cursor INTO @WorkId;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @ItemsCount = 1 + ABS(CHECKSUM(NEWID()) % 5);
    
    INSERT INTO WorkItem (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, Price)
    SELECT 
        DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 10), w.CREATE_Date) AS CREATE_DATE,
        w.IS_Complit AS Is_Complit,
        (SELECT TOP 1 Id_Employee FROM Employee ORDER BY NEWID()) AS Id_Employee,
        a.ID_ANALIZ,
        @WorkId AS Id_Work,
        a.Price
    FROM 
        (SELECT TOP (@ItemsCount) ID_ANALIZ, Price FROM Analiz ORDER BY NEWID()) AS a
    CROSS JOIN 
        Works w
    WHERE 
        w.Id_Work = @WorkId;
    
    FETCH NEXT FROM work_cursor INTO @WorkId;
END

CLOSE work_cursor;
DEALLOCATE work_cursor;

-- Установка Close_Date для завершённых элементов
UPDATE WorkItem
SET Close_Date = DATEADD(DAY, ABS(CHECKSUM(NEWID()) % 30), CREATE_DATE)
WHERE Is_Complit = 1;

-- Удаление временных таблиц
DROP TABLE #Names;
DROP TABLE #Surnames;
DROP TABLE #Patronymics;
DROP TABLE #ClientFIO;