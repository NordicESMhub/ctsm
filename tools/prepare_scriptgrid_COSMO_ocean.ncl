load "/cluster/software/NCL/6.6.2-intel-2019b/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/cluster/software/NCL/6.6.2-intel-2019b/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/cluster/software/NCL/6.6.2-intel-2019b/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/cluster/software/NCL/6.6.2-intel-2019b/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/cluster/software/NCL/6.6.2-intel-2019b/lib/ncarg/nclscripts/csm/popRemap.ncl"
load "/cluster/software/NCL/6.6.2-intel-2019b/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

  indir_prefix="/cluster/projects/nn2806k/huit/abel_backup/prepare_clm_input/ryan_albedo"

  wks_type                         ="pdf"
  wks_type@wkPaperSize             ="A4"
;  wks_type@wkOrientation          ="landscape"
  wks                              = gsn_open_wks(wks_type, "test2")
    gsn_define_colormap(wks,"hotcolr_19lev")         ; choose color map
    i = NhlNewColor(wks,0.8,0.8,0.8)                   ; add gray to colormap


;**********
;draw figures
;**********
   f1           = addfile(indir_prefix+"/COSMO_REA6_CONST_withOUTsponge.nc","r")

   lat          = f1->RLAT(645:814,435:565)
   lon          = f1->RLON(645:814,435:565)
   landsea      = tointeger(f1->FR_LAND(645:814,435:565))     ; for more accurate land-sea mask using cosmo data, >0.5 should be used for defining land.
   landsea      = 1


   printVarSummary(lat)
   printVarSummary(lon)
   printVarSummary(landsea)


   Opt1                = True
   Opt1@ForceOverwrite = True
   Opt1@PrintTimings    = True
   Opt1@Title           = "COSMO-REA6 Grid"
   Opt1@GridMask        = landsea

;    Opt1@GridMask         = (/1/)
;    Opt1@GridCornerLat  = (/yfloor,yfloor,yceil,yceil/)
;    Opt1@GridCornerLon  = (/xfloor,xceil,xceil,xfloor/)

   curvilinear_to_SCRIP(indir_prefix+"/SCRIPgrid_COSMOREA6_nomask1_ocean_sub.nc",lat,lon,Opt1)
    
end 
