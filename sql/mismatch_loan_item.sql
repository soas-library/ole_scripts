SELECT 
	item.ITEM_ID,
	item.BARCODE,
	item.DUE_DATE_TIME,
	loan.CURR_DUE_DT_TIME,
	item.CURRENT_BORROWER,
	status.ITEM_AVAIL_STAT_ID,
	status.ITEM_AVAIL_STAT_NM,
	item.ITEM_STATUS_DATE_UPDATED 
FROM 
	OLE.OLE_DS_ITEM_T item
LEFT JOIN 
	ole_dlvr_item_avail_stat_t status on item.ITEM_STATUS_ID = status.ITEM_AVAIL_STAT_ID
LEFT JOIN
	ole.ole_dlvr_loan_t loan on item.BARCODE = loan.ITM_ID
WHERE 
	(item.ITEM_STATUS_ID = 17
	AND
		item.BARCODE 
		NOT IN 
			(SELECT 
				ITM_ID 
			FROM 
				OLE.OLE_DLVR_LOAN_T)
	)
	OR
		((item.ITEM_STATUS_ID = 17 OR item.ITEM_STATUS_ID = 1) AND item.DUE_DATE_TIME <> loan.CURR_DUE_DT_TIME)
	OR
		((item.ITEM_STATUS_ID = 17 OR item.ITEM_STATUS_ID = 1) AND item.DUE_DATE_TIME IS NULL AND loan.CURR_DUE_DT_TIME IS NOT NULL)
	OR
		((item.ITEM_STATUS_ID = 17 OR item.ITEM_STATUS_ID = 1) AND item.DUE_DATE_TIME IS NOT NULL AND loan.CURR_DUE_DT_TIME IS NULL)
;