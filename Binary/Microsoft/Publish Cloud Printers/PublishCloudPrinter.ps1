Publish-CloudPrinter -Printer "Secure Printer" `
-Manufacturer Ricoh `
-Model "Secure Printer" `
-OrgLocation '{"attrs": [{"category":"country", "vs":"USA", "depth":0}, {"category":"organization", "vs":"Livonia Public Schools", "depth":1}, {"category":"site", "vs":"Livonia, Michigan", "depth":2}, {"category":"building", "vs":"BOE", "depth":3}, {"category":"floor_name", "vs":1, "depth":4}, {"category":"room_name", "vs":"0101", "depth":5}]}' `
-Sddl "O:BAG:SYD:(A;;LCSWSDRCWDWO;;;S-1-5-21-1417001333-73586283-725345543-235664)(A;OIIO;RPWPSDRCWDWO;;;S-1-5-21-1417001333-73586283-725345543-235664)(A;OIIO;GA;;;CO)(A;OIIO;GA;;;AC)(A;;SWRC;;;WD)(A;CIIO;GX;;;WD)(A;;SWRC;;;AC)(A;CIIO;GX;;;AC)(A;;LCSWDTSDRCWDWO;;;BA)(A;OICIIO;GA;;;BA)" `
-DiscoveryEndpoint "https://cloudprintdiscovery.livoniapublicschools.org/mcs/" `
-PrintServerEndpoint "https://cloudprint.livoniapublicschools.org/ECP/" `
-AzureClientId "6af63105-32e4-425a-8f5b-2b1b5754feaf" `
-AzureTenantGuid "50e641ef-23c3-4dab-a87f-ceeab762647e" `
-DiscoveryResourceId "https://cloudprintdiscovery.livoniapublicschools.org/mcs/"
