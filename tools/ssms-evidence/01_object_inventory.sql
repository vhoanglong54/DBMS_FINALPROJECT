USE [GymManagementDemo];
GO

SET NOCOUNT ON;

SELECT
    [LoaiDoiTuong] = v.ObjectType,
    [SoLuong] = v.ObjectCount
FROM
(
    SELECT N'Bảng nghiệp vụ', COUNT_BIG(*) FROM sys.tables WHERE is_ms_shipped = 0
    UNION ALL SELECT N'Khóa ngoại', COUNT_BIG(*) FROM sys.foreign_keys
    UNION ALL SELECT N'CHECK constraint tin cậy', COUNT_BIG(*) FROM sys.check_constraints WHERE is_not_trusted = 0
    UNION ALL SELECT N'Trigger', COUNT_BIG(*) FROM sys.triggers WHERE parent_class = 1
    UNION ALL SELECT N'View', COUNT_BIG(*) FROM sys.views WHERE is_ms_shipped = 0
    UNION ALL SELECT N'Index không phải PK', COUNT_BIG(*) FROM sys.indexes
        WHERE index_id > 0 AND is_primary_key = 0
          AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1
    UNION ALL SELECT N'Stored procedure', COUNT_BIG(*) FROM sys.procedures WHERE is_ms_shipped = 0
    UNION ALL SELECT N'Function', COUNT_BIG(*) FROM sys.objects
        WHERE type IN ('FN', 'IF', 'TF') AND is_ms_shipped = 0
) AS v(ObjectType, ObjectCount);

SELECT
    [BangCon] = OBJECT_NAME(fkc.parent_object_id),
    [CotFK] = COL_NAME(fkc.parent_object_id, fkc.parent_column_id),
    [BangCha] = OBJECT_NAME(fkc.referenced_object_id),
    [CotPK] = COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id),
    [TenKhoaNgoai] = fk.name
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fkc.constraint_object_id = fk.object_id
ORDER BY [BangCon], [TenKhoaNgoai];
GO
