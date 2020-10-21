#!/bin/bash

#SBATCH --account=nn2806k 
#SBATCH --job-name=mkmapdata
#SBATCH --mem-per-cpu=256G --partition=bigmem
#SBATCH --ntasks=1
#SBATCH --time=07:00:00

date="200605"         # Need to be the same as the running date

######### Domain have been set:
Hui Tang: Nordic: 0.05x0.05, 57.37525-71.32475 N, 4.625247-31.62475 E
Yeliz:
Marius:

plotlat=(69.341088)
plotlon=(25.293524)
plotname=(FINN)

creat_script="T"               # T or F, switch for creating script grid or not
creat_domain="T"               # T or F, switch for creating domain file
creat_mapping="T"              # T or F, switch for creating mapping file
creat_surfdat="T"              # T or F, switch for creating surface data file
run_case="F"                   # T or F, switch for running many clm experiments automatically. "T" can only be used when all the inputdata are ready!!!!  
run_case_first="F"             # T or F, swtich for creating, building and submitting short test runs
run_case_second="F"            # T or F, swtich for running long experiments

#0 1 2 3 4 5 6 7 8 9 10 11
for i in 0
do
 
######## Make script grids:
if [ ${creat_script} == "T" ]
then

   module purge
   module load NCL/6.6.2-intel-2019b
   cd ~/ctsm/tools/mkmapdata
   mkdir -p /cluster/shared/noresm/inputdata/share/scripgrids/fates_platform/${plotname[i]}

   echo $i
   echo ${plotlat[$i]} ${plotlon[$i]}
##### The following method does not work for regional case, as they assume land all over the place. We need a land-sea mask file for each regional setting. 
#   ./mknoocnmap.pl -centerpoint ${plotlat[i]},${plotlon[i]} -name ${plotname[i]} -dx 0.01 -dy 0.01
#   mv ~/ctsm/tools/mkmapgrids/*${plotname[i]}*.nc /cluster/shared/noresm/inputdata/share/scripgrids/fates_platform/${plotname[i]}/
##### Alternatively, the following scripts are provided, if you have domain setting and land-sea mask files as a netcdf file already, in tools folder.
prepare_scriptgrid_fenno.ncl
prepare_scriptgrid_fenno_ocean.ncl

fi

######## Make domain file:
if [ ${creat_domain} == "T" ]
then
   module purge
   cd ~/ctsm/cime/tools/mapping/gen_domain_files
   mkdir -p /cluster/shared/noresm/inputdata/share/domains/fates_platform/${plotname[i]}

   #### Compile (Only need to be run at the first time, better to run separately)
   #cd src/
   #../../../configure --macros-format Makefile --mpilib mpi-serial --machine saga
   #. ./.env_mach_specific.sh ; gmake

   #### For regional case, the mapping file between land and ocean needs to be created before gen_domain, for instance:
   /cluster/software/VERSIONS/esmf/6_3_0rp1/bin/binO/Linux.intel.64.openmpi.default/ESMF_RegridWeightGen --ignore_unmapped -s SCRIPgrid_Fenno_ocean_mask.nc -d SCRIPgrid_Fenno_nomask.nc -m conserve -w map_5x5_km_ocean_to_land_nomask_aave_da_c181115.nc --dst_regional --src_regional --src_type SCRIP --dst_type SCRIP

   #### Run
   . ./src/.env_mach_specific.sh
   ./gen_domain -m /cluster/shared/noresm/inputdata/share/scripgrids/fates_platform/${plotname[i]}/map_${plotname[i]}_noocean_to_${plotname[i]}_nomask_aave_da_${date}.nc -o ${plotname[i]} -l ${plotname[i]}



   #####Three domain files will be created, land domain file or land-ocean domain file should be used ? 
   mv domain.lnd.${plotname[i]}_${plotname[i]}.${date}.nc domain.lnd.${plotname[i]}.${date}.nc
   mv domain*${plotname[i]}*.nc /cluster/shared/noresm/inputdata/share/domains/fates_platform/${plotname[i]}/

fi

######## Make mapping file:
if [ ${creat_mapping} == "T" ]
then

   module purge
   cd ~/ctsm/tools/mkmapdata
   mkdir -p /cluster/shared/noresm/inputdata/lnd/clm2/mappingdata/maps/fates_platform/${plotname[i]}/
   #### Modify regridbatch.sh. This has been done in "fates_emerald_api".
   #### Run regridbatch.sh
   ./regridbatch.sh 1x1_${plotname[i]} /cluster/shared/noresm/inputdata/share/scripgrids/fates_platform/${plotname[i]}/SCRIPgrid_${plotname[i]}_nomask_c${date}.nc 
   mv map*${plotname[i]}*.nc /cluster/shared/noresm/inputdata/lnd/clm2/mappingdata/maps/fates_platform/${plotname[i]}/

fi

####### Create mapping file between regional land domain and rof domain:
# need to load the ESMF module, and find the correct place of ESMF
# is "conserve" interpolation good for run off?
# need a high resolution runoff script grid, if you need accurate runoff simulation

/cluster/software/VERSIONS/esmf/6_3_0rp1/bin/binO/Linux.intel.64.openmpi.default/ESMF_RegridWeightGen --ignore_unmapped -s SCRIPgrid_0.5x0.5_nomask_c110308.nc -d SCRIPgrid_Fenno_nomask.nc -m conserve -w map_0.5x0.5_nomask_to_5x5_km_nomask_aave_da_c181115.nc --dst_regional --src_type SCRIP --dst_type SCRIP
#/cluster/software/VERSIONS/esmf/6_3_0rp1/bin/binO/Linux.intel.64.openmpi.default/ESMF_RegridWeightGen --ignore_unmapped -s SCRIPgrid_Fenno_nomask.nc -d SCRIPgrid_0.5x0.5_nomask_c110308.nc -m conserve -w map_5x5_km_nomask_to_0.5x0.5_nomask_aave_da_c181115.nc --src_regional --src_type SCRIP --dst_type SCRIP

# If you turn on run off, using MOSART with 8th degree, addition runoff mapping file is needed for routing data:

# Need to create addition script grid file for the routing data
# Then create mapping file from MOZART grid to the regional domain


######## Make surface data file:
if [ ${creat_surfdat} == "T" ]
then

   module purge
   module load netCDF-Fortran/4.5.2-iimpi-2019b
   cd ~/ctsm/tools/mksurfdata_map
   mkdir -p /cluster/shared/noresm/inputdata/lnd/clm2/surfdata_map/fates_platform/${plotname[i]}

   #### Compile (Only need to be run at the first time, better to run separately)
   #module load netCDF-Fortran/4.5.2-iimpi-2019b
   #Modify Makefile.common. This has been done in "fates_emerald_api".
   #gmake clean
   #gmake

   #### Run
   ./mksurfdata.pl -no-crop -res usrspec -usr_gname 1x1_${plotname[i]} -usr_gdate ${date} -usr_mapdir /cluster/shared/noresm/inputdata/lnd/clm2/mappingdata/maps/fates_platform/${plotname[i]} -dinlc /cluster/shared/noresm/inputdata -hirespft -years "2005" -allownofile
   mv surfdata_1x1_${plotname[i]}_hist_16pfts_Irrig_CMIP6_simyr2005_c${date}.nc surfdata_${plotname[i]}_simyr2000.nc
   mv surfdata*${plotname[i]}* /cluster/shared/noresm/inputdata/lnd/clm2/surfdata_map/fates_platform/${plotname[i]}

fi

######## Create a case
if [ ${run_case} == "T" ]
then
  
  module purge
  if [ ${run_case_first} == "T" ]
  then
    cd ~/ctsm/cime/scripts
    ./create_newcase --case ../../../ctsm_cases/2000FATES_seedclim_${plotname[i]} --compset 2000_DATM%1PTGSWP3_CLM50%FATES_SICE_SOCN_MOSART_SGLC_SWAV --res 1x1_${plotname[i]} --machine saga --run-unsupported --project nn2806k

######## Build the case and run the test
    cd ~/ctsm_cases/2000FATES_seedclim_${plotname[i]}
    ./case.setup
    ./case.build
    ./case.submit
  fi

######## Run the case for longer time
  if [ ${run_case_second} == "T" ]
  then
    cd ~/ctsm_cases/2000FATES_seedclim_${plotname[i]}
    ./xmlchange --file env_run.xml --id STOP_OPTION --val nyears                 # set up the time unit (e.g., nyears, nmonths, ndays).
    ./xmlchange --file env_run.xml --id STOP_N --val 200                         # set up the length of the simulation.
    #./xmlchange --file env_run.xml --id CONTINUE_RUN --val TRUE                 # if you want to continue your simulation from the restart file, set it to TRUE.
    ./xmlchange --file env_run.xml --id RESUBMIT --val 9                         # set up how many times you want to resubmit your simulation.
    ./xmlchange --file env_workflow.xml --id JOB_WALLCLOCK_TIME --val 08:00:00   # set up longer queue time for runing the simulation. 
    ./xmlchange --file env_workflow.xml --id JOB_QUEUE --val bigmem              # set up which queue to be used. Both "normal" and "bigmem" can be used depending on their availability.   
    ./case.submit
  fi

fi

done

