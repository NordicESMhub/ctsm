#!/bin/bash

#######################
# Setup begin
#######################

date="200927"         # DATE when the domain files were created.

plotname=(LYG BUO HAV SKO)    # Plot name
#SeedClim Sites: ALP1 ALP2 ALP3 ALP4 SUB1 SUB2 SUB3 SUB4 BOR1 BOR2 BOR3 BOR4
#Landpress Sites: LYG BUO HAV SKO
#Three-D Sites: VIKE JOAS LIAH
#Finnmark Site: FINN

site_num="0 1 2 3"      #0 1 2 3 4 5 6 7 8 9 10 11

atm_forc="GSWP3v1"    #GSWP3v1, COSMO6km (not ready yet), ERA5land (not ready yet)

input_dir="/cluster/shared/noresm/inputdata_fates_platform"  # input directory where the input data are kept. 
temp_dir=$HOME/inputdata_fates_platform                      # temporary directory for keeping the re-organized input data. 

#######################
# Setup end
#######################

mkdir -p ${temp_dir}
cd ${temp_dir}

for i in ${site_num}
do

   mkdir -p inputdata
   mkdir -p inputdata/atm/cam/chem/trop_mozart_aero/aero/${plotname[i]}
   cp ${input_dir}/atm/cam/chem/trop_mozart_aero/aero/aerosoldep_WACCM.ensmean_monthly_hist_1849-2015_0.9x1.25_CMIP6_c180926_${plotname[i]}.nc ./inputdata/atm/cam/chem/trop_mozart_aero/aero/${plotname[i]}/
   
   mkdir -p inputdata/atm/datm7/topo_forcing/${plotname[i]}
   cp ${input_dir}/atm/datm7/topo_forcing/topodata_${plotname[i]}.nc ./inputdata/atm/datm7/topo_forcing/${plotname[i]}/
   
   mkdir -p inputdata/atm/datm7/${atm_forc}/${plotname[i]}
   cp ${input_dir}/atm/datm7/${atm_forc}/${plotname[i]}/*.nc ./inputdata/atm/datm7/${atm_forc}/${plotname[i]}/
    
   mkdir -p inputdata/share/domains/${plotname[i]}
   cp ${input_dir}/share/domains/${plotname[i]}/domain.lnd.${plotname[i]}.${date}.nc ./inputdata/share/domains/${plotname[i]}/
      
   mkdir -p inputdata/lnd/clm2/surfdata_map/${plotname[i]}
   cp ${input_dir}/lnd/clm2/surfdata_map/${plotname[i]}/surfdata_${plotname[i]}_simyr2000.nc ./inputdata/lnd/clm2/surfdata_map/${plotname[i]}/
   
   mkdir -p inputdata/lnd/clm2/urbandata/${plotname[i]}
   cp ${input_dir}/lnd/clm2/urbandata/CLM50_tbuildmax_Oleson_2016_0.9x1.25_simyr1849-2106_c160923_${plotname[i]}.nc ./inputdata/lnd/clm2/urbandata/${plotname[i]}/       
   
   mkdir -p inputdata/lnd/clm2/snicardata
   cp ${input_dir}/lnd/clm2/snicardata/*.nc ./inputdata/lnd/clm2/snicardata

   mkdir -p inputdata/lnd/clm2/paramdata
   cp ${input_dir}/lnd/clm2/paramdata/*.nc ./inputdata/lnd/clm2/paramdata/ 

   tar -cvf inputdata_version1.0.0_${plotname[i]}.tar inputdata
   mv inputdata_version1.0.0_${plotname[i]}.tar ${input_dir}/

   rm -r inputdata

done

