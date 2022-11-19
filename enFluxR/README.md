# enFlux

# Code Overview
## Functions
We need functions for:  

-	Database:  
	-	Connecting to Database  
		-	`connect_to_pg.R  
	-	Inserting into Database  
		-	`insert_into_pg.R  
		-	 base off connection object?  
	-	Selecting from Database  
		-	Check for data in DB  
			-	`check_status_pg.R  
		-	API for web app and quick plotting  
			-	`collect_data.R  
-	Extraction wrappers  
	-	Checking for data on portal  
		-	`portal_availability.R`  
	-	Downloading data from portal  
		-	`download_ec.R` 
	-	Extracting zips  
		-	`extract_ec_zip`  
	-	Extracting zips  
		-	`extract_ec_zip_p`  
	-	Extracting relevant data  
		-	`extract_ec_data`  
