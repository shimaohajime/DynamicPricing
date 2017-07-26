
cd $folder
/*****************DATA********************/
/*1. Create PROD-AGE list, dynamic data*/
sort PROD AGE
/*Logit Model for Initial Value*/
/**Demand Side**/
gen Delta = log( unit/marketsize ) - log( 1-unit/marketsize )
gen AlphaP = -3.
gen temp = Delta - AlphaP*price
//reg temp AGE i.PROD i.month
bys PROD:egen temp_meanByPROD = mean(temp)
gen temp_demean = temp - temp_meanByPROD
reg temp_demean AGE i.month
_predict Xi, residual
matrix b = e(b)
matrix list b
matrix c = b'
svmat double c, name(beta_d)
gen beta_d_cons=_b[_cons]
gen beta_d_age = _b[AGE]
replace beta_d1=. if abs(beta_d1-beta_d_cons)<.0001|abs(beta_d1-beta_d_age)<.0001
/**Supply Side**/
gen MC = price+1/(AlphaP*(1-(unit/marketsize)))
reg MC i.publisherid i.MH
_predict Lambda, residual
matrix b = e(b)
matrix list b
matrix c = b'
svmat double c, name(beta_s)
gen beta_s_cons=_b[_cons]
replace beta_s1=. if abs(beta_s1-beta_s_cons)<.0001|abs(beta_s1-beta_s_cons)<.0001
xtset PROD AGE
gen profit = unit*price
gen dEVnextdp = marketsize*AlphaP*(unit/marketsize)*(1-(unit/marketsize))*F.price
replace dEVnextdp=0 if dEVnextdp==.

bys PROD: gen cumunit = sum(unit)
xtset PROD AGE
gen M = marketsize-L.cumunit
replace M=marketsize if AGE==0

/*predicted price*/
/*coefficient for each product
gen pricesq = price*price
reg price c.L.price##i.PROD c.L.AGE##i.PROD i.L.month
//reg price c.L.price##i.PROD
//reg price c.L.price c.L.price#i.PROD,nocons
predict phat_each
gen phat_next_each = F.phat_each
replace phat_each=-999 if phat_each==.
//replace phat_next_each=-999 if phat_next_each==.
drop if phat_next_each==.
*/

/*pooled regression for all the products*/
reg price c.L.price c.L.AGE i.L.month
//reg price c.L.price
//reg price c.L.price,nocons
predict phat_all
gen phat_next_all = F.phat_all
replace phat_all=-999 if phat_all==.
//replace phat_next_all=-999 if phat_next_all==.
drop if phat_next_all==.

export excel PROD AGE Xi Lambda Delta dEVnextdp M unit price phat_next_all hwsales marketsize month year t prodage using "BaseData.xls", sheetreplace firstrow(variables)
//export excel PROD AGE Xi Lambda Delta dEVnextdp M unit price phat_next_each phat_next_all hwsales marketsize month year t prodage using "BaseData.xls", sheetreplace firstrow(variables)
//export excel PROD AGE using "ID_List.xls", sheetreplace firstrow(variables)
//export excel beta_d1 beta_d_cons beta_d_age beta_s1 beta_s_cons using "LogitEst.xls", sheetreplace firstrow(variables)

/*Adjust name*/
replace NPD_Title = subinstr(NPD_Title," ","",.)
replace NPD_Title = subinstr(NPD_Title,"/","",.) 
replace NPD_Title = subinstr(NPD_Title,".","",.) 
replace NPD_Title = subinstr(NPD_Title,"(","",.)
replace NPD_Title = subinstr(NPD_Title,")","",.) 
replace publisher = subinstr(publisher," ","",.) 
replace publisher = subinstr(publisher,"/","",.) 
replace publisher = subinstr(publisher,".","",.) 
replace publisher = subinstr(publisher,"(","",.)
replace publisher = subinstr(publisher,")","",.) 
replace publisher = subinstr(publisher,"2","Two",.) 
replace platform = subinstr(platform," ","",.) 

/*2. Create PROD list, product level data*/
preserve
rename temp_meanByPROD Alpha0
egen age_max = max(AGE),by(PROD)
collapse (first)NPD_Title (first)supergenre (first)supergenreid (first)platform (first)platformid (first)publisher (first)publisherid (first)MH (first)MH_index (first)age_max (first)first_party (first)TotalUnit (first)Alpha0, by(PROD)
sort PROD
export excel PROD NPD_Title age_max first_party MH MH_index platform platformid supergenre supergenreid publisher publisherid TotalUnit Alpha0 using "ProdList.xls", sheetreplace firstrow(variables)
restore

/*3. Create AGE list
preserve
collapse PROD ,by(AGE)
sort AGE
export excel AGE using "AgeList.xls", sheetreplace firstrow(variables)
restore
*/

/*4. Create Publisher list*/
preserve
collapse PROD (first)publisher ,by(publisherid)
sort publisherid
export excel publisherid publisher using "PublisherList.xls", sheetreplace firstrow(variables) nolabel
restore

/*5. Coefficients*/



*Come back to parent folder
cd ..
