/* Statements written by Giri Sankar from HTC */

DELETE 
FROM 
	ole_ptrn_nte_t 
WHERE 
	OLE_PTRN_ID = 'ole_patron_id';

DELETE 
FROM 
	ole_ptrn_lost_bar_t 
WHERE 
	OLE_PTRN_ID = 'ole_patron_id';

DELETE 
FROM 
	ole_ptrn_local_id_t 
WHERE 
	OLE_PTRN_ID = 'ole_patron_id';

DELETE 
FROM 
	krim_entity_email_t 
WHERE 
	ENTITY_ID = 'ole_patron_id';

DELETE 
FROM 
	krim_entity_addr_t 
WHERE 
	ENTITY_ID = 'ole_patron_id';

DELETE 
FROM 
	krim_entity_ent_typ_t 
WHERE 
	ENTITY_ID = 'ole_patron_id';

DELETE 
FROM 
	krim_entity_t 
WHERE 
	ENTITY_ID = 'ole_patron_id';

/* The following two statements were written by Simon Barron from SOAS CSBS but need to need occur above ole_ptrn_t for foreign key constraints */

DELETE
FROM
ole.ole_dlvr_temp_circ_record
WHERE
OLE_PTRN_ID = 'ole_patron_id'
;


DELETE
FROM
ole.ole_dlvr_circ_record
WHERE
OLE_PTRN_ID = 'ole_patron_id'
;

/* Statements written by Giri Sankar from HTC */

DELETE 
FROM 
	ole_ptrn_t 
WHERE 
	OLE_PTRN_ID = 'ole_patron_id';

DELETE 
FROM 
	ole_dlvr_ptrn_bill_pay_t 
WHERE 
	ITM_LINE_ID IN 
	(SELECT ID 
	FROM 
		ole_dlvr_ptrn_bill_fee_typ_t 
	WHERE 
		ptrn_bill_id in 
		(SELECT PTRN_BILL_ID 
		FROM 
			ole_dlvr_ptrn_bill_t 
		WHERE 
			OLE_PTRN_ID = 'ole_patron_id'));
			
DELETE 
FROM 
	ole_dlvr_ptrn_bill_fee_typ_t 
WHERE ptrn_bill_id in 
	(SELECT PTRN_BILL_ID 
	FROM 
		ole_dlvr_ptrn_bill_t 
	WHERE 
		OLE_PTRN_ID = 'ole_patron_id');

DELETE 
FROM 
	ole_dlvr_ptrn_bill_t 
WHERE 
	OLE_PTRN_ID = 'ole_patron_id';
	
/* Statements added by Simon Barron from SOAS CSBS */

DELETE
FROM
ole.krim_entity_nm_t
WHERE
ENTITY_ID = 'ole_patron_id'
;

DELETE
FROM
ole.ole_dlvr_add_t
WHERE
OLE_PTRN_ID = 'ole_patron_id'
;

DELETE
FROM
ole.ole_dlvr_email_t
WHERE
OLE_PTRN_ID = 'ole_patron_id'
;

DELETE
FROM
ole.krim_entity_phone_t
WHERE
ENTITY_ID = 'ole_patron_id'
;

DELETE
FROM
ole.ole_dlvr_phone_t
WHERE
OLE_PTRN_ID = 'ole_patron_id'
;

DELETE
FROM
ole.ole_dlvr_loan_notice_hstry_t
WHERE
PTRN_ID = 'ole_patron_id'
;

DELETE
FROM
ole.ole_dlvr_rqst_hstry_rec_t
WHERE
OLE_PTRN_ID = 'ole_patron_id'
;