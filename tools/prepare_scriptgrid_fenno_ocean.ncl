load "/cluster/software/VERSIONS/ncl-6.5.0/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/cluster/software/VERSIONS/ncl-6.5.0/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/cluster/software/VERSIONS/ncl-6.5.0/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/cluster/software/VERSIONS/ncl-6.5.0/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/cluster/software/VERSIONS/ncl-6.5.0/lib/ncarg/nclscripts/csm/popRemap.ncl"
load "/cluster/software/VERSIONS/ncl-6.5.0/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

  indir_prefix="/usit/abel/u1/huit/prepare_clm_input/ryan_albedo"
;  source("module load ncl/6.5.0")


  wks_type                         ="pdf"
  wks_type@wkPaperSize             ="A4"
;  wks_type@wkOrientation          ="landscape"
  wks                              = gsn_open_wks(wks_type, "test2")
    gsn_define_colormap(wks,"hotcolr_19lev")         ; choose color map
    i = NhlNewColor(wks,0.8,0.8,0.8)                   ; add gray to colormap


;**********
;draw figures
;**********
   f1           = addfile(indir_prefix+"/Surface_data_UiO.nc","r")
   f2           = addfile(indir_prefix+"/Fenno_ocean_mask_UiO.nc","r")

   lat          = f1->Latitude(::-1)
   lon          = f1->Longitude(:)
   landsea      = f2->Fennoscandic_Mask(:,::-1)
   printVarSummary(lat)
   printVarSummary(lon)
   printVarSummary(landsea)


   Opt1                = True
   Opt1@ForceOverwrite = True
   Opt1@PrintTimings    = True
   Opt1@Title           = "Fenno Grid"
   Opt1@GridMask        = landsea(x|:,y|:)

;    Opt1@GridMask         = (/1/)
;    Opt1@GridCornerLat  = (/yfloor,yfloor,yceil,yceil/)
;    Opt1@GridCornerLon  = (/xfloor,xceil,xceil,xfloor/)

   rectilinear_to_SCRIP(indir_prefix+"/SCRIPgrid_Fenno_ocean_mask.nc",lat,lon,Opt1)
    
end 
