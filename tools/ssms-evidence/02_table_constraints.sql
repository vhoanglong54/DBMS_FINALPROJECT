USE [GymManagementDemo];
GO

SET NOCOUNT ON;

SELECT
    [Cot] = c.name,
    [KieuDuLieu] = TYPE_NAME(c.user_type_id)
        + CASE
            WHEN TYPE_NAME(c.user_type_id) IN ('varchar', 'nvarchar')
                THEN CONCAT('(', CASE WHEN c.max_length = -1 THEN 'MAX'
                    ELSE CONVERT(varchar(10), CASE WHEN TYPE_NAME(c.user_type_id) = 'nvarchar'
                        THEN c.max_length / 2 ELSE c.max_length END) END, ')')
            ELSE ''
          END,
    [ChoPhepNull] = IIF(c.is_nullable = 1, N'Có', N'Không'),
    [Identity] = IIF(c.is_identity = 1, N'Có', N'Không'),
    [KhoaChinh] = IIF(pk.column_id IS NULL, N'', N'PK')
FROM sys.columns AS c
LEFT JOIN
(
    SELECT ic.object_id, ic.column_id
    FROM sys.indexes AS i
    INNER JOIN sys.index_columns AS ic
        ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    WHERE i.is_primary_key = 1
) AS pk ON pk.object_id = c.object_id AND pk.column_id = c.column_id
WHERE c.object_id = OBJECT_ID(N'dbo.HoiVien')
ORDER BY c.column_id;

SELECT N'UNIQUE' AS [Loai], kc.name AS [TenRangBuoc],
       COL_NAME(ic.object_id, ic.column_id) AS [NoiDung]
FROM sys.key_constraints AS kc
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.HoiVien') AND kc.type = 'UQ'
UNION ALL
SELECT N'CHECK', cc.name, cc.definition
FROM sys.check_constraints AS cc
WHERE cc.parent_object_id = OBJECT_ID(N'dbo.HoiVien')
UNION ALL
SELECT N'INDEX', i.name, STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal)
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
INNER JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(N'dbo.HoiVien') AND i.is_primary_key = 0 AND i.is_unique_constraint = 0
GROUP BY i.name
ORDER BY [Loai], [TenRangBuoc];
GO
