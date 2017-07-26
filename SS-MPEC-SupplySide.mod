param N_KV=2;
set K_V = 0..N_KV;
###Supply side
#var MC {(j,t) in OBS} >=.00000001,:=price[j,t]-(unit[j,t]/marketsize[j,t])/(init_AlphaP*(1-unit[j,t]/marketsize[j,t]));
var MC {(j,t) in OBS} >=.00000001,:= price[j,t]*.1;
var Lambda {(j,t) in OBS} <=price[j,t],:=init_Lambda[j,t];
var MCnoLam{(j,t) in OBS} :=price[j,t]*.1 - init_Lambda[j,t];
###Supply parameter
var AlphaCostPhys;
var AlphaCostFee{(j,t) in OBS};
var AlphaCost0<=50;#,:=5.;
#var AlphaCostPubHom {PUBLISHER,HOMING}<=50,:=0.;
var AlphaCostPub {PUBLISHER}<=50,:=0.;
var AlphaCostHome {HOMING}<=50,:=0.;
var AlphaCostHome_num {MULTIHOMING}<=50,:=0.;
var AlphaCostGenre {GENRE}<=50,:=0;
var AlphaCostAlpha0;
var AlphaCostAlpha0Sq;
var AlphaCostTU;
var AlphaCostProd {PROD};
#var AlphaCostTime<=50,:=0;
###Value function approximation
var dDdp {(j,t) in OBS};#:=marketsize[j,t]*(init_AlphaP)*(unit[j,t]/marketsize[j,t])*(1-(unit[j,t]/marketsize[j,t])) ;
var dDdp_i {i in CONS, (j,t) in OBS};#:=marketsize[j,t]*(init_AlphaP)*(unit[j,t]/marketsize[j,t])*(1-(unit[j,t]/marketsize[j,t]));
var dEVnextdp {(j,t) in OBS}:=init_dEVnextdp[j,t] ;
var dEWnextdp_i {i in CONS, (j,t) in OBS}:=init_dEVnextdp[j,t];
#var Gamma_dVdp{k_M in K_V, k_a0 in K_V, k_t in K_V, m in MONTH:k_M+k_a0+k_t<=2}; #no lambda
var Gamma_dVdp{k_M in K_V, k_delta in K_V, k_cost in K_V, m in MONTH, i in CONS:k_M+k_delta+k_cost<=2}; #no lambda
#var Gamma_dVdp{k_M in K_V, k_delta in K_V, k_cost in K_V, i in CONS:k_M+k_delta+k_cost<=2}; #no lambda, no month
##EL variables
var Rho_s {(j,t) in OBS:t>=2}>=1e-10,<=.999999,:=( 1/abs(init_Lambda[j,t]) ) /(  sum {(jj,tt) in OBS:tt>=2}( 1/abs(init_Lambda[jj,tt]) )  );


maximize EL_obj_s:
sum {(j,t) in OBS:t>=2} (log(Rho_s[j,t]));

#fix AlphaCostGenre[genre1]:=0;
#fix AlphaCostPubHom[publisher1, homing1]:=0;
#fix AlphaCostPub[publisher1]:=0;
#fix AlphaCostHome[homing1]:=0;
#------Supply Constraints----------------------------
#s.t. FOC {(j,t) in OBS}: Demand_scaled[j,t]+(price[j,t]-MC[j,t])*dDdp[j,t]/scale_M+beta*dEVnextdp[j,t]/scale_M = 0;
s.t. FOC {(j,t) in OBS}: unit[j,t]/scale_M+(price[j,t]-MC[j,t])*dDdp[j,t]/scale_M+beta*dEVnextdp[j,t]/scale_M = 0;
#s.t. FOC_RatioFee {(j,t) in OBS}: unit[j,t]/scale_M*(1-AlphaCostFee[j,t])+(price[j,t]*(1-AlphaCostFee[j,t])-AlphaCostPhys)*dDdp[j,t]/scale_M+beta*dEVnextdp[j,t]/scale_M = 0;
s.t. Derivative_EW_PolyVersion {i in CONS, (j,t) in OBS}: dEWnextdp_i[i,j,t] = ( sum{k in K_EW} ( k*Gamma_EW[i,k]*EDelta_next_i[i,j,t]^(k-1) ) )*(AlphaP_i[i])*Coeff_AR1_price_price;
s.t. Derivative_Demand_i {i in CONS,(j,t) in OBS}: dDdp_i[i,j,t]/scale_M = M_i_scaled[i,j,t]  * Share_i[i,j,t]*(1-Share_i[i,j,t])*(AlphaP_i[i]-beta*dEWnextdp_i[i,j,t]);
s.t. Derivative_Demand {(j,t) in OBS}: dDdp[j,t] = sum{i in CONS}(dDdp_i[i,j,t]);
#s.t. Derivative_EV_iidLam_i_DeltaCost {(j,t) in OBS}: dEVnextdp[j,t] = sum{k_M in K_V, k_delta in K_V, k_cost in K_V, i in CONS:k_M+k_delta+k_cost<=2}( Gamma_dVdp[k_M,k_delta,k_cost,month[j,t],i]*(M_i_scaled[i,j,t]**k_M)*(Delta_i[i,j,t]**k_delta)*((MCnoLam[j,t])**k_cost) );
#s.t. Derivative_EV_iidLam_i_EDeltaCost {(j,t) in OBS}: dEVnextdp[j,t] = sum{k_M in K_V, k_delta in K_V, k_cost in K_V, i in CONS:k_M+k_delta+k_cost<=2}( Gamma_dVdp[k_M,k_delta,k_cost,month[j,t],i]*(M_i_scaled[i,j,t]**k_M)*(EDelta_next_i[i,j,t]**k_delta)*((MCnoLam[j,t])**k_cost) );
s.t. Derivative_EV_iidLam_i_EDeltaCost {(j,t) in OBS}: dEVnextdp[j,t] = sum{k_M in K_V, k_delta in K_V, k_cost in K_V, i in CONS:k_M+k_delta+k_cost<=2}( Gamma_dVdp[k_M,k_delta,k_cost,month[j,t],i]*(M_i_scaled[i,j,t]**k_M)*(EDelta_next_i[i,j,t]**k_delta)*((AlphaCostFee[j,t])**k_cost) );

#s.t. Derivative_EV_iidLam_i_EDeltaCostNoMonth {(j,t) in OBS}: dEVnextdp[j,t] = sum{k_M in K_V, k_delta in K_V, k_cost in K_V, i in CONS:k_M+k_delta+k_cost<=2}( Gamma_dVdp[k_M,k_delta,k_cost,i]*(M_i_scaled[i,j,t]**k_M)*(EDelta_next_i[i,j,t]**k_delta)*((MCnoLam[j,t])**k_cost) );
#s.t. Derivative_EV_withLam_PolyVersion {(j,t) in OBS}: dEVnextdp[j,t] = sum{k_M in K_V, k_a0 in K_V, k_t in K_V, k_Lam in K_V:k_M+k_a0+k_t+k_Lam<=2}( Gamma_dVdp[k_M,k_a0,k_t,k_Lam,month[j,t]]*(M_scaled[j,t]**k_M)*(Alpha0[j]**k_a0)*(t**k_t)*(Lambda[j,t]**k_Lam) );
#s.t. CostReg_Pub_Home {(j,t) in OBS}: MC[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostPub[publisher[j]] + AlphaCostHome[homing[j]] + AlphaCostGenre[genre[j]] )+Lambda[j,t];
#s.t. CostReg_Pub_Home_Time {(j,t) in OBS}: MC[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostPub[publisher[j]] + AlphaCostHome[homing[j]] + AlphaCostGenre[genre[j]] +AlphaCostTime*(time[j,t]-time_min) )+Lambda[j,t];
#s.t. CostReg_Pub_Homenum {(j,t) in OBS}: MC[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostPub[publisher[j]] + AlphaCostHome_num[homing_num[j]] + AlphaCostGenre[genre[j]] )+Lambda[j,t];
s.t. CostReg_Prod {(j,t) in OBS}: MC[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostProd[j] )+Lambda[j,t];
#s.t. CostReg_Pub_Homenum_Alpha0 {(j,t) in OBS}: MC[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostPub[publisher[j]] + AlphaCostHome_num[homing_num[j]] + AlphaCostGenre[genre[j]]+AlphaCostAlpha0*Alpha0[j]+AlphaCostTU*total_unit[j] )+Lambda[j,t];
#s.t. CostReg_ratio {(j,t) in OBS}: AlphaCostFee[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostPub[publisher[j]] + AlphaCostHome_num[homing_num[j]] + AlphaCostGenre[genre[j]] )+Lambda[j,t];
#s.t. CostReg_NoGenre {(j,t) in OBS}: MC[j,t] = AlphaCost0 + (1-first_party[j]) *(  AlphaCostPubHom[publisher[j],homing[j]] )+Lambda[j,t];
#s.t. CostNoLam {(j,t) in OBS}: MCnoLam[j,t] = MC[j,t] - Lambda[j,t];
#GMM on Lambda directly
s.t. SumGMMexog_priceL1_Lam: sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*price[j,t-1]) = 0; 
s.t. SumGMMexog_priceL2_Lam: sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*price[j,t-2]) = 0; 
s.t. SumGMMexog_OtherPrice_Lam:sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*sum{(jj,tt) in OBS:jj!=j and tt=t}(price[jj,tt]/n_obs)  )= 0;
s.t. SumGMMexog_Age_Lam: sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*age[j,t]) = 0; 
s.t. SumGMMexog_AgeSq_Lam: sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*(age[j,t]**2)) = 0; 
s.t. SumGMMexog_Month_Lam {m in MONTH}: sum {(j,t) in OBS:t>=2 and month[j,t]=m}(Rho_s[j,t]*Lambda[j,t]) = 0; 
s.t. SumGMMexog_Genre_Lam {g in GENRE}: sum {(j,t) in OBS:t>=2 and genre[j]=g}(Rho_s[j,t]*Lambda[j,t]) = 0; 
#s.t. SumGMMendg_Lam_XiL1 : sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*Xi[j,t-1]) = 0; 
#s.t. SumGMMendg_Lam_XiL2 : sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*Xi[j,t-2]) = 0; 
#s.t. SumGMMendg_Lam_LamL1 : sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*Lambda[j,t-1]) = 0; 
#s.t. SumGMMendg_Lam_LamL2 : sum {(j,t) in OBS:t>=2}(Rho_s[j,t]*Lambda[j,t]*Lambda[j,t-2]) = 0; 

#EL constraint
s.t. SumRho_s: sum {(j,t) in OBS:t>=2} (Rho_s[j,t]) = 1;