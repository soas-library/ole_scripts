# ole_scripts
Various scripts to maintain SOAS Library's OLE integrated library system including scripts to pick up patron records, to backup the MySQL database, and to perform general housekeeping.

Drools ([https://www.drools.org/](https://www.drools.org/)) is a Business Rules Management System largely used in Java applications. For OLE, Drools is used to define the circulation rules for the library. 

Soas's Drools rules are backed up on Subversion and on GitHub ([https://github.com/soas-library/ole_rules](https://github.com/soas-library/ole_rules)).

OLE's technical documentation for Drools is in [http://site.kuali.org/ole/2.0-r25025/reference/pdfs/DroolsTechnicalDocument.pdf](http://site.kuali.org/ole/2.0-r25025/reference/pdfs/DroolsTechnicalDocument.pdf)

# Reading the rules:

The Drools rules are kept on the OLE servers at /usr/local/2ndhome/kuali/main/prd/olefs-webapp/rules/

Go to this location and download a copy of all the directories in that location. The Drools rules will be present as .drl files.

# Updating the rules:

To update the Drools rules, edit the .drl files to reflect your new rules. 

Then, in OLE, go to Admin > Circulation Policy Ingester. Select the rules directory for your new file. Select the new .drl file you want to ingest and upload it. 

Then, go to Admin > Parameter. Search for the parameter 'LOAD_CIRC_POLICIES_IND'. Click 'edit' to edit the parameter. Change the parameter value from 'N' to 'Y'. This will force the system to re-evaluate the Drools files the next time they are invoked. After that, it will automatically be reset to 'N'. Click Submit.
