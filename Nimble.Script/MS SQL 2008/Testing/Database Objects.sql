SELECT * FROM [sys].[objects] SO 
WHERE SO.[type] IN
( 
	'C',
	--'D',
	--'F',
	'FN',
	'IF',
	'P',
	--'PK',
	'U',
	'UQ',
	'V'
)
ORDER BY 
	SO.[type],
	SO.[name];
