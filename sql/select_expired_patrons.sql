SELECT
	OLE_PTRN_ID
FROM 
	ole.ole_ptrn_t
WHERE 
	(NOT EXISTS
	(SELECT * 
	FROM ole.ole_dlvr_loan_t
	WHERE ole.ole_ptrn_t.OLE_PTRN_ID=ole.ole_dlvr_loan_t.OLE_PTRN_ID))
AND
	(NOT EXISTS
	(SELECT * 
	FROM ole.ole_dlvr_ptrn_bill_t
	WHERE ole.ole_ptrn_t.OLE_PTRN_ID=ole.ole_dlvr_ptrn_bill_t.OLE_PTRN_ID))
AND
	ole_ptrn_t.EXPIRATION_DATE < 'expiration_date'
;