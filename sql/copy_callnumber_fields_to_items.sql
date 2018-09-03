UPDATE 
	ole.ole_ds_holdings_t holdings
JOIN 
	ole.ole_ds_item_t item ON item.HOLDINGS_ID=holdings.HOLDINGS_ID
SET 
	item.CALL_NUMBER = holdings.CALL_NUMBER, item.CALL_NUMBER_TYPE_ID='2'
WHERE
	-- holdings.LOCATION LIKE '%CLOSED%'
	IFNULL(item.CALL_NUMBER,'') = ''
;