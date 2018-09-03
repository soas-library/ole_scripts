UPDATE 
	ole.ole_ds_holdings_t holdings
JOIN 
	ole.ole_ds_item_t item ON item.HOLDINGS_ID=holdings.HOLDINGS_ID
SET 
	item.LOCATION = holdings.LOCATION, item.LOCATION_LEVEL='Shelving Location'
WHERE
	-- holdings.LOCATION LIKE '%CLOSED%'
	IFNULL(item.LOCATION,'') = ''
;