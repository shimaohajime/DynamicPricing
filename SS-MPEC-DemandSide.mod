#------1.1 Define variables------
##Hyper parameter
param N_CONS_MAX=30;
param N_CONS=10;
param beta=.9;
### Polynomial version
param N_KW=2;
##Set
set PROD;
param age_max {PROD};
param age_max_all = max({j in PROD} age_max[j]);
set AGE=0..age_max_all;
set OBS within {PROD,AGE};
param year {OBS};
param year_min = min({(j,t) in OBS} year[j,t]);
param year_max = max({(j,t) in OBS} year[j,t]);
set YEAR= year_min..year_max;
param time {OBS};
param time_min = min({(j,t) in OBS} time[j,t]);
param time_max = max({(j,t) in OBS} time[j,t]);
set TIME=time_min..time_max+1;

set MONTH=1..12;
set GENRE=1..14;
set MULTIHOMING=1..3;
set HOMING=1..7;
set PLATFORM=1..3;
set PUBLISHER;
set CONS_MAX = 1..N_CONS_MAX;
set CONS within{CONS_MAX} =1..N_CONS;
### Polynomial version
set K_EW = 0..N_KW;
##Values for initial guess and scaling
param init_AlphaP = -5;
param init_AlphaAge = -5;
param init_Alpha0 {PROD};
param init_Xi {OBS};
param init_Lambda {OBS};
param init_M {OBS};
param init_Delta {(j,t) in OBS};
param init_dEVnextdp {(j,t) in OBS};
param scale_M = 100.;
##Hyper Parameters
param n_obs=card(OBS);
param n_obs_tgeq2=card( {(j,t) in OBS:t>=2} );
param n_prod=card(PROD);
param n_age=card(AGE);
##Parameters-Data
###Product level data
param first_party {PROD};
param publisher {PROD};
param genre {PROD};
param publisher1 = min({j in PROD} publisher[j]);
param genre1 = min({j in PROD} genre[j]);
param homing {PROD};
param homing1 = min({j in PROD} homing[j]);
param homing_num {PROD};
param platform {PROD};
param total_unit {PROD};
###Dynamic data
param age {OBS};
param price {OBS};
param unit {OBS};
param hwsales {OBS}; 
param marketsize {OBS};
param month {OBS};
param phat_next {OBS};
##Consumer Draw
param draw_a0_max {CONS_MAX};
param draw_ap_max {CONS_MAX};
param draw_a0 {i in CONS} = draw_a0_max[i];
param draw_ap {i in CONS} = draw_ap_max[i];
#----------------Variables-----------------------------------
##Model variables
###Demand side
var Share_i {i in CONS, (j,t) in OBS} >=.00000001,<=.999999,:=unit[j,t]/marketsize[j,t];
var Share {(j,t) in OBS} >=.00000001,<=.999999,:=unit[j,t]/marketsize[j,t];
#var Demand_scaled {(j,t) in OBS} >=.00000001,:=unit[j,t]/scale_M;
var Delta_i {i in CONS, (j,t) in OBS} >=.00000001,<=50,:=init_Delta[j,t];
var Delta {(j,t) in OBS} >=.000001,<=50,:=init_Delta[j,t];
var EDelta_next_i {i in CONS, (j,t) in OBS}>=.00000001, <=50;

/*Marketsize:Standard*/
var M_i_scaled {i in CONS, (j,t) in OBS} >=.00000001,<=marketsize[j,t]/(scale_M),:=init_M[j,t]/(N_CONS*scale_M);
var M_scaled{(j,t) in OBS}>=.00000001,<=marketsize[j,t],:=init_M[j,t]/scale_M;

/*Marketsize: hwsales from Previous month
var M_i_scaled {i in CONS, (j,t) in OBS} >=.00000001,<=(marketsize[j,t]-hwsales[j,t])/(scale_M),:=(init_M[j,t]-hwsales[j,t])/(N_CONS*scale_M);
var M_scaled{(j,t) in OBS}>=.00000001,<=(marketsize[j,t]-hwsales[j,t]),:=(init_M[j,t]-hwsales[j,t])/scale_M;
*/
var Xi {(j,t) in OBS} <=50,:=init_Xi[j,t];
##Model estimates
###Demand parameter
var AlphaP:=init_AlphaP;
var AlphaP_i {CONS}:=init_AlphaP;
var Alpha0 {j in PROD}<=50,:=init_Alpha0[j]/10;
var Alpha0_ij {CONS,PROD};

#var AlphaRelease;
#var AlphaRelease2;


var AlphaAge<=50,:=init_AlphaAge;
var AlphaAgeSq<=50;
#var AlphaMonth {MONTH}<=50;
var AlphaHoming {HOMING}<=50;
var AlphaGenre {GENRE}<=50;
var AlphaTime {TIME}<=50.;
var AlphaNE :=0;
var Sigma_a0 :=1.;
var Sigma_ap :=1.;
###Value function approximation
####Polynomial version
var EWnext_i {i in CONS, (j,t) in OBS};
var Gamma_EW {CONS,K_EW}<=50;
#var Gamma_EW {CONS,K_EW,K_EW}<=50; #Price separate from delta
#var Gamma_EW {CONS,K_EW,MONTH}; #Month in the state space
##AR1 Process
#var Coeff_AR1_price:=.7;
#var Coeff_AR1_price {PROD}:=.7;
#var Error_AR1_price {(j,t) in OBS:t>=1}:=0;
##EL variables
var Rho_d {(j,t) in OBS:t>=2}>=.000001,<=.999999,:=( 1/abs(init_Xi[j,t]) ) /(sum {(jj,tt) in OBS:tt>=2}( 1/abs(init_Xi[jj,tt]) ) );
#var Rho_d {(j,t) in OBS:t>=2}>=.000001,<=.999999,:=(1/(abs(init_Xi[j,t]-init_Xi[j,t-1])+abs(init_Lambda[j,t]-init_Lambda[j,t-1])))/(sum {(jj,tt) in OBS:tt>=2} (1/(abs(init_Xi[jj,tt]-init_Xi[jj,tt-1])+abs(init_Lambda[jj,tt]-init_Lambda[jj,tt-1]))) );

#------1.2 Read Data------
table CONS_DRAWTable IN "tableproxy" "odbc" "CONS_DRAW.xls" "CONS_DRAWTable":
[CONS_MAX],draw_a0_max~draw_a0,draw_ap_max~draw_ap;
read table CONS_DRAWTable;

#option ampl_include "C:\Users\Hajime\Dropbox\Hajime\SS progress\10. MPEC estimation and data\10-3-Monopoly-Mutiple-PuPl\OneYear_U1K_1M-2M";
#cd "C:\Users\Hajime\Dropbox\Hajime\SS progress\10. MPEC estimation and data\10-3-Monopoly-Mutiple-PuPl\OneYear_U1K_1M-2M";

table ProdListTable IN "tableproxy" "odbc" "C:\Users\Hajime\Dropbox\Hajime\SS progress\10. MPEC estimation and data\10-3-Monopoly-Mutiple-PuPl\AboveTwoYear_U5K_All\ProdList.xls" "ProdListTable":
PROD<-[PROD],age_max,first_party,platform~platformid,homing~MH,homing_num~MH_index,genre~supergenreid,publisher~publisherid,total_unit~TotalUnit,init_Alpha0~Alpha0;
read table ProdListTable;

table BaseDataTable IN "tableproxy" "odbc" "C:\Users\Hajime\Dropbox\Hajime\SS progress\10. MPEC estimation and data\10-3-Monopoly-Mutiple-PuPl\AboveTwoYear_U5K_All\BaseData.xls" "BaseDataTable":
OBS<-[PROD,AGE],unit,price,phat_next~phat_next_all,hwsales,marketsize,month,year,time~t,age~prodage,init_Xi~Xi,init_Lambda~Lambda,init_M~M,init_Delta~Delta,init_dEVnextdp~dEVnextdp;
read table BaseDataTable;

table PublisherListTable IN "tableproxy" "odbc" "C:\Users\Hajime\Dropbox\Hajime\SS progress\10. MPEC estimation and data\10-3-Monopoly-Mutiple-PuPl\AboveTwoYear_U5K_All\PublisherList.xls" "PublisherListTable":
PUBLISHER<-[publisherid];
read table PublisherListTable;



#-----1.3 Model----------------------------------------------------------------
fix  {i in CONS,(j,t) in OBS: t=0}  M_i_scaled[i,j,t] := marketsize[j,t]/(N_CONS*scale_M);
#fix  {i in CONS,(j,t) in OBS: t=0}  M_i_scaled[i,j,t] := (marketsize[j,t]-hwsales[j,t])/(N_CONS*scale_M);
#fix  Coeff_AR1_price :=  (sum {(j,t) in OBS:t>=1}(price[j,t]*price[j,t-1])) / (sum {(j,t) in OBS:t>=1}(price[j,t-1]^2)) ;
#fix  {j in PROD} Coeff_AR1_price[j] :=  (sum {(jj,tt) in OBS:tt>=1 and jj=j}(price[jj,tt]*price[jj,tt-1])) / (sum {(jj,tt) in OBS:tt>=1 and jj=j}(price[jj,tt-1]^2)) ;
#fix {i in CONS,(j,t) in OBS:t=11} EDelta_next_i[i,j,t] := 0;
#fix AlphaMonth[1]:=0;
fix AlphaTime[time_min]:=0;
fix AlphaGenre[genre1]:=0;
fix AlphaHoming[homing1]:=0;

#fix Sigma_a0:=0;

maximize EL_obj_d:
sum {(j,t) in OBS:t>=2} (log(Rho_d[j,t]));
#--Demand Constraints------------------------------
s.t. AlphaP_i_each {i in CONS}: AlphaP_i[i] = AlphaP+draw_ap[i]*Sigma_ap;
s.t. Alpha0_ij_each {i in CONS,j in PROD}: Alpha0_ij[i,j] = Alpha0[j]+draw_ap[i]*Sigma_a0;

s.t. LogitShare_i {i in CONS, (j,t) in OBS}: Share_i[i,j,t] = exp(Delta_i[i,j,t])/( exp(Delta_i[i,j,t])+exp(beta*EWnext_i[i,j,t]) );
s.t. ShareToDemand {(j,t) in OBS}: unit[j,t]/scale_M = sum{i in CONS}( Share_i[i,j,t]*M_i_scaled[i,j,t] );
#s.t. ShareToDemand {(j,t) in OBS}: Demand_scaled[j,t] = sum{i in CONS}( Share_i[i,j,t]*M_i_scaled[i,j,t] );
#s.t. DemandMatchData {(j,t) in OBS}: Demand_scaled[j,t] = unit[j,t]/scale_M;

s.t. MarketSizeTrans_i {i in CONS,(j,t) in OBS: t>0}: M_i_scaled[i,j,t] = M_i_scaled[i,j,t-1]*(1.-Share_i[i,j,t-1])+hwsales[j,t]/(N_CONS*scale_M);
#s.t. MarketSizeTrans_i_hwPrevM {i in CONS,(j,t) in OBS: t>0}: M_i_scaled[i,j,t] = M_i_scaled[i,j,t-1]*(1.-Share_i[i,j,t-1])+hwsales[j,t-1]/(N_CONS*scale_M);

s.t. MarketSizeAggregate {(j,t) in OBS}: M_scaled[j,t] = sum{i in CONS} M_i_scaled[i,j,t];


#Demand Dynamic decision
##Version 4: polynomial based on EDelta_next
#s.t. priceAR1 {(j,t) in OBS:t>=1}: price[j,t] = Coeff_AR1_price*price[j,t-1] + Error_AR1_price[j,t];
#s.t. priceAR1Reg: Coeff_AR1_price =  (sum {(j,t) in OBS:t>=1}(price[j,t]*price[j,t-1])) / (sum {(j,t) in OBS:t>=1}(price[j,t-1]^2)) ;

#s.t. UReg_AgeSq_NoHom_MonthFE_RC0p_i {i in CONS,(j,t) in OBS}: Delta_i[i,j,t]= (Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaMonth[month[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
s.t. UReg_AgeSq_NoHom_TimeFE_RC0p_i {i in CONS,(j,t) in OBS}: Delta_i[i,j,t]= (Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaTime[time[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
/*Network Effect
s.t. UReg_NE_AgeSq_NoHoming_RC0p_i_release {i in CONS,(j,t) in OBS:age[j,t]=0}: Delta_i[i,j,t]= (Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaTime[time[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
s.t. UReg_NE_AgeSq_NoHoming_RC0p_i_1 {i in CONS,(j,t) in OBS:age[j,t]=1}: Delta_i[i,j,t]= (Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaNE*unit[j,t-1]+AlphaTime[time[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
s.t. UReg_NE_AgeSq_NoHoming_RC0p_i {i in CONS,(j,t) in OBS:age[j,t]>1}: Delta_i[i,j,t]= (Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaNE*unit[j,t-1]+AlphaTime[time[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
*/

/*Standard*/
#s.t. CPred_EDelta_i_AgeSq_MonthFE_iidXiAR1p {i in CONS,(j,t) in OBS}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] - (  AlphaP_i[i]*price[j,t]*(1-Coeff_AR1_price)  ) + (  AlphaMonth[(month[j,t] mod 12)+1] - AlphaMonth[month[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
s.t. CPred_EDelta_i_AgeSq_TimeFE_iidXiAR1p {i in CONS,(j,t) in OBS}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] + (  AlphaP_i[i]*(phat_next[j,t]-price[j,t])  ) + (  AlphaTime[time[j,t]+1] - AlphaTime[time[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
/*Network Effect
s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_NE_0 {i in CONS,(j,t) in OBS:age[j,t]=0}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] + AlphaNE*(unit[j,t]  ) + (  AlphaP_i[i]*(phat_next[j,t]-price[j,t])  ) + (  AlphaTime[time[j,t]+1] - AlphaTime[time[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_NE {i in CONS,(j,t) in OBS:age[j,t]>0}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] + AlphaNE*(unit[j,t]-unit[j,t-1]  ) + (  AlphaP_i[i]*(phat_next[j,t]-price[j,t])  ) + (  AlphaTime[time[j,t]+1] - AlphaTime[time[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
*/
s.t. ConsPred_EW_EDelta_i_Poly {i in CONS,(j,t) in OBS}: EWnext_i[i,j,t]= sum{k in K_EW} Gamma_EW[i,k]*EDelta_next_i[i,j,t]^k;


/*EDelta without price, p_t as state space
s.t. ConsPred_EDelta_i_AgeSq_iidXi_NoPrice {i in CONS,(j,t) in OBS}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] -  AlphaP_i[i]*price[j,t] + (  AlphaMonth[(month[j,t] mod 12)+1] - AlphaMonth[month[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
s.t. ConsPred_EW_EDelta_i_Poly_Price {i in CONS,(j,t) in OBS}: EWnext_i[i,j,t]= sum{k_d in K_EW, k_p in K_EW:k_d+k_p<=2} Gamma_EW[i,k_d,k_p]*EDelta_next_i[i,j,t]^k_d*price[j,t]^k_p;
*/

/*Month as state variable
#s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_Month {i in CONS,(j,t) in OBS}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] - AlphaMonth[month[j,t]] - (  AlphaP_i[i]*price[j,t]*(1-Coeff_AR1_price)  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
#s.t. ConsPred_EW_i_Poly_Month {i in CONS,(j,t) in OBS}: EWnext_i[i,j,t]= sum{k in K_EW} Gamma_EW[i,k,month[j,t]]*EDelta_next_i[i,j,t]^k;
*/

#s.t. ConsPred_EW_DeltaIVS_i_Poly {i in CONS,(j,t) in OBS}: EWnext_i[i,j,t]= sum{k in K_EW} Gamma_EW[i,k]*Delta_i[i,j,t]^k;


#s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_last0 {i in CONS,(j,t) in OBS:t<=10}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] - (  AlphaP_i[i]*price[j,t]*(1-Coeff_AR1_price)  ) + (  AlphaMonth[(month[j,t] mod 12)+1] - AlphaMonth[month[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
#s.t. ConsPred_EW_PolyVersion {i in CONS,(j,t) in OBS:t<=10}: EWnext_i[i,j,t]= sum{k in K_EW} Gamma_EW[i,k]*EDelta_next_i[i,j,t]^k;
#s.t. ConsPred_EDelta_i_last0 {i in CONS,(j,t) in OBS:t=11}: EDelta_next_i[i,j,t] = 0;
#s.t. ConsPred_EW_last0 {i in CONS,(j,t) in OBS:t=11}: EWnext_i[i,j,t]= 0;


/*Release Month Dummy
s.t. UtilityReg_AgeSq_NoHoming_RC0p_i_FM {i in CONS,(j,t) in OBS:t<=0}: Delta_i[i,j,t]= AlphaRelease+(Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaMonth[month[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
#s.t. UtilityReg_AgeSq_NoHoming_RC0p_i_FM2 {i in CONS,(j,t) in OBS:t=1}: Delta_i[i,j,t]= AlphaRelease2+(Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaMonth[month[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
s.t. UtilityReg_AgeSq_NoHoming_RC0p_i_FMo {i in CONS,(j,t) in OBS:t>=1}: Delta_i[i,j,t]= (Alpha0_ij[i,j])+(AlphaP_i[i]*price[j,t])+AlphaMonth[month[j,t]]+AlphaAge*age[j,t]+AlphaAgeSq*(age[j,t]**2)+AlphaGenre[genre[j]]  +Xi[j,t];
s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_FM {i in CONS,(j,t) in OBS:t=0}: EDelta_next_i[i,j,t] = Delta_i[i,j,t]-AlphaRelease+AlphaRelease2 - (  AlphaP_i[i]*price[j,t]*(1-Coeff_AR1_price)  ) + (  AlphaMonth[(month[j,t] mod 12)+1] - AlphaMonth[month[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
#s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_F2 {i in CONS,(j,t) in OBS:t=1}: EDelta_next_i[i,j,t] = Delta_i[i,j,t]-AlphaRelease2 - (  AlphaP_i[i]*price[j,t]*(1-Coeff_AR1_price)  ) + (  AlphaMonth[(month[j,t] mod 12)+1] - AlphaMonth[month[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
s.t. ConsPred_EDelta_i_AgeSq_iidXiAR1price_FMo {i in CONS,(j,t) in OBS:t>=1}: EDelta_next_i[i,j,t] = Delta_i[i,j,t] - (  AlphaP_i[i]*price[j,t]*(1-Coeff_AR1_price)  ) + (  AlphaMonth[(month[j,t] mod 12)+1] - AlphaMonth[month[j,t]]  ) + AlphaAge + AlphaAgeSq*((age[j,t]+1)**2 - age[j,t]**2 );
*/

#-------GMM Objectives-------------------------------
#GMM on Xi, Lambda directly
s.t. SumGMMexog_priceL1_Xi: sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*price[j,t-1]) = 0; 
s.t. SumGMMexog_priceL2_Xi: sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*price[j,t-2]) = 0; 
s.t. SumGMMexog_OtherPrice_Xi:sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*sum{(jj,tt) in OBS:jj!=j and tt=t}(price[jj,tt]/n_obs)  )= 0;
s.t. SumGMMexog_Age_Xi: sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*age[j,t]) = 0; 
s.t. SumGMMexog_AgeSq_Xi: sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*(age[j,t]**2)) = 0; 
s.t. SumGMMexog_Month_Xi {m in MONTH}: sum {(j,t) in OBS:t>=2 and month[j,t]=m}(Rho_d[j,t]*Xi[j,t]) = 0; 
s.t. SumGMMexog_Genre_Xi {g in GENRE}: sum {(j,t) in OBS:t>=2 and genre[j]=g}(Rho_d[j,t]*Xi[j,t]) = 0; 
#s.t. SumGMMendg_Xi_XiL1 : sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*Xi[j,t-1]) = 0; 
#s.t. SumGMMendg_Xi_XiL2 : sum {(j,t) in OBS:t>=2}(Rho_d[j,t]*Xi[j,t]*Xi[j,t-2]) = 0; 

#EL constraint
s.t. SumRho_d: sum {(j,t) in OBS:t>=2} (Rho_d[j,t]) = 1;
