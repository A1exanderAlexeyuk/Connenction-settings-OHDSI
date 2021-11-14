copy regimen_stats_schema.rst2( person_id,
    drug_era_id ,
	ingredient ,
	ingredient_start_date,
	ingredient_end_date ,
    regimen ,
    regimen_start_date ,
	regimen_end_date) FROM 
	'c:/Users/Public/rst.csv' DELIMITER ',' CSV ENCODING 'UTF8' QUOTE '"' ESCAPE '''' ;
