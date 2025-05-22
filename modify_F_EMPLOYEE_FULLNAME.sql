IF OBJECT_ID('dbo.F_EMPLOYEE_FULLNAME') IS NOT NULL
    DROP FUNCTION dbo.F_EMPLOYEE_FULLNAME
GO

CREATE FUNCTION [dbo].[F_EMPLOYEE_FULLNAME] (@Id_Employee INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ISNULL(RTRIM(e.Surname + ' ' + UPPER(SUBSTRING(e.Name, 1, 1)) + '. ' + 
               UPPER(SUBSTRING(e.Patronymic, 1, 1)) + '.'), 
               e.Login_Name) AS FULL_NAME
    FROM 
        Employee e
    WHERE 
        e.Id_Employee = @Id_Employee
)
GO