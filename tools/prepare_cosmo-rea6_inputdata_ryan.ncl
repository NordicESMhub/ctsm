;#############  
;####namelist_definition_datm.xml; datm_comp_mod.F90  (done)

;############# Other work to do

;#### create domain files: domain.lnd.COSMOREA6.nc,domain.lnd.NORA10.nc (done)
;      
;#### download missing longwave variables for nora and cosmo (done)
;#### check the used of the input atmospheric forcings, optimized it in the source code (This is managed in: datm_comp_mod.F90)
;#### wind and tbot is required for CLMNCEP mode
;#### Precip total is required for CLMNCEP mode: Need to be improved
;#### longwave radiation is read directly to the model? Need to make sure

;############ work to be done in this file

;#### shift of time axis (done): precipitation is in fact 1 hr behind the expected time. So in "namelist_definition_datm.xml", the offset should be positive +1800, instead of -1800
;#### pick up missing values in COSMO REA (done): See "problem_cosmo_dataset"
;#### remove the leap year 29.02 data from COSMO REA, because CLM run with noleap years
;#### three files separately (done)



load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "/projects/NS2806K/huit/reanalysis/cosmo_6km/unrot_lonlat.ncl"

begin


  clim_input    =  "/projects/NS2806K/huit/reanalysis/cosmo_6km"
    
  mon = ispan(0,11,1)
  mon@units  = "month"
  month =cd_string(mon,"%N")   
  print(month)

  da = ispan(0,30,1)
  da@units  = "day"
  day =cd_string(da,"%D")   
  print(day)

  fcon=addfile(clim_input+"/COSMO_REA6_CONST_withOUTsponge.nc","r")      
  hsurf=fcon->HSURF(:,:)            ; unit: m
  lon2d=fcon->RLON(:,:)
  lat2d=fcon->RLAT(:,:)
  printVarSummary(lon2d)
  printVarSummary(lat2d)

  frsds_gswp=addfile("/projects/NS2806K/huit/reanalysis/GSWP3.0v1/clmforc.GSWP3.c2011.0.5x0.5.Solr.1995-01.nc","r")
  fprec_gswp=addfile("/projects/NS2806K/huit/reanalysis/GSWP3.0v1/clmforc.GSWP3.c2011.0.5x0.5.Prec.1995-01.nc","r")
  ftphw_gswp=addfile("/projects/NS2806K/huit/reanalysis/GSWP3.0v1/clmforc.GSWP3.c2011.0.5x0.5.TPQWL.1995-01.nc","r")
      
  rsds_gswp=frsds_gswp->FSDS(:,:,:)             ; w/m2
  prec_gswp=fprec_gswp->PRECTmms(:,:,:)         ; mm/s
  psrf_gswp=ftphw_gswp->PSRF(:,:,:)             ; Pa
  tbot_gswp=ftphw_gswp->TBOT(:,:,:)             ; K
  wind_gswp=ftphw_gswp->WIND(:,:,:)             ; m/s
  qbot_gswp=ftphw_gswp->QBOT(:,:,:)             ; kg/kg
  flds_gswp=ftphw_gswp->FLDS(:,:,:)             ; w/m2
  
      
  time_gswp=frsds_gswp->time(:)
  edgew   =frsds_gswp->EDGEW
  edgee   =frsds_gswp->EDGEE
  edges   =frsds_gswp->EDGES
  edgen   =frsds_gswp->EDGEN
  longxy  =frsds_gswp->LONGXY
  latxy   =frsds_gswp->LATIXY

  do year=2007,2007,1 
    year@calendar="standard"
    do m=7,7,1
      frsds1=addfile(clim_input+"/SWDIRS_RAD/SWDIRS_RAD.2D."+year+month(m)+".nc","r")      
      frsds2=addfile(clim_input+"/SWDIFDS_RAD/SWDIFDS_RAD.2D."+year+month(m)+".nc","r") 
      fprec1=addfile(clim_input+"/RAIN_GSP/RAIN_GSP.2D."+year+month(m)+".nc","r")
      fprec2=addfile(clim_input+"/RAIN_CON/RAIN_CON.2D."+year+month(m)+".nc","r")
      fprec3=addfile(clim_input+"/SNOW_GSP/SNOW_GSP.2D."+year+month(m)+".nc","r")
      fprec4=addfile(clim_input+"/SNOW_CON/SNOW_CON.2D."+year+month(m)+".nc","r")
      fpsrf=addfile(clim_input+"/PS/PS.2D."+year+month(m)+".nc","r")
      fflds=addfile(clim_input+"/THDS_RAD/THDS_RAD.2D."+year+month(m)+".nc","r")

      if ((m .eq. 1).and.(isleapyear(year))) then
        rsds1=frsds1->var22(0:223,:,:)   ; W/m2
        rsds2=frsds2->var23(0:223,:,:)   ; W/m2                 
        rain_gsp=(fprec1->var102(0:223,:,:))/3600
        rain_con=(fprec2->var113(0:223,:,:))/3600
        snow_gsp=(fprec3->var79(0:223,:,:))/3600
        snow_con=(fprec4->var78(0:223,:,:))/3600 ; kg/m3/hour to mm/s
        prec=rain_gsp+rain_con+snow_gsp+snow_con ; kg/m3/s
        psrf=fpsrf->var1(0:223,:,:)  ;Pa
        flds=fflds->var25(0:223,:,:)  ; W/m2
        time=frsds1->time(0:223)
      else
        rsds1=frsds1->var22(:,:,:)   ; W/m2
        rsds2=frsds2->var23(:,:,:)   ; W/m2                 
        rain_gsp=(fprec1->var102(:,:,:))/3600
        rain_con=(fprec2->var113(:,:,:))/3600
        snow_gsp=(fprec3->var79(:,:,:))/3600
        snow_con=(fprec4->var78(:,:,:))/3600 ; kg/m3/hour to mm/s
        prec=rain_gsp+rain_con+snow_gsp+snow_con ; kg/m3/s
        psrf=fpsrf->var1(:,:,:)  ;Pa
        flds=fflds->var25(:,:,:)  ; W/m2
        time=frsds1->time(:)
      end if

      time@calendar="noleap"
      year@calendar="noleap"
      nday=days_in_month(year,m+1)

      printVarSummary(time)
      printVarSummary(psrf)
      printVarSummary(rain_gsp)
      printVarSummary(rsds1)
      printVarSummary(rsds2)

      tbot=new(dimsizes(psrf),float)
      u=new(dimsizes(psrf),float)
      v=new(dimsizes(psrf),float)
      qbot=new(dimsizes(psrf),float) 

      print(nday)

      do d=0,nday-1,1
        
        ftemp=addfile(clim_input+"/T/"+year+"/T.3D."+year+month(m)+day(d)+".nc","r")       
        fhumi=addfile(clim_input+"/Q/"+year+"/Q.3D."+year+month(m)+day(d)+".nc","r")
        fwind1=addfile(clim_input+"/U/"+year+"/U.3D."+year+month(m)+day(d)+".nc","r")
        fwind2=addfile(clim_input+"/V/"+year+"/V.3D."+year+month(m)+day(d)+".nc","r")
      
;        printVarSummary(ftemp->var11(:,0,:,:))
        tbot(8*d:8*d+7,:,:)=ftemp->var11(:,0,:,:)        ;K
        u(8*d:8*d+7,:,:)=fwind1->var33(:,0,:,:)          ;m/s
        v(8*d:8*d+7,:,:)=fwind2->var34(:,0,:,:)
        qbot(8*d:8*d+7,:,:)=fhumi->var51(:,0,:,:)        ;kg/kg
        
      end do
      
      wind=wind_speed(u,v)
      printVarSummary(tbot)      

;#### write output:
 
      clim_output   = "/projects/NS2806K/huit/reanalysis/cosmo_6km/clm_atmforcing/"
      system("mkdir -p "+ clim_output)

;####clmforc.COSMOREA6.Solr.%ym.nc; clmforc.COSMOREA6.Prec.%ym.nc; clmforc.COSMOREA6.TPQWL.%ym.nc
;####clmforc.NORA10.Solr.%ym.nc; clmforc.NORA10.Prec.%ym.nc; clmforc.NORA10.TPQWL.%ym.nc
      ntim  = dimsizes(time)                 ; get dimension sizes                                                 
      nlat =dimsizes(lat2d(:,0))
      nlon =dimsizes(lon2d(0,:))
      nscalar = 1

      write_solr=False
      write_prec=False
      write_tpqwl=True

;##################################

      if (write_solr) then

        system("rm -f "+clim_output+"clmforc.COSMOREA6.Solr."+year+"-"+month(m)+".nc")    ; remove if exists
        fsolr  = addfile(clim_output+"clmforc.COSMOREA6.Solr."+year+"-"+month(m)+".nc","c")
        setfileoption(fsolr,"DefineMode",True)

        fAtt               = True            ; assign file attributes
        fAtt@case_title    = "COSMO REA6: Solr "  
        fAtt@conventions   = "CF-1.0" 
        fAtt@title         = "CLM forcing based on COSMO REA6"  
        fAtt@history       = "Original data from COSMO REA6 data"
        fAtt@creation_date = systemfunc ("date")        
        fileattdef( fsolr, fAtt )            ; copy file attributes  

        dimNames = (/"scalar","lon","lat","time"/)  
        dimSizes = (/ nscalar, nlon, nlat, -1 /) 
        dimUnlim = (/ False, False, False, True/)   
        filedimdef(fsolr,dimNames,dimSizes,dimUnlim)

        filevardef(fsolr, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
        filevardef(fsolr, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
        filevardef(fsolr, "EDGES"  ,typeof(edges),getvardims(edges))                          
        filevardef(fsolr, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
        filevardef(fsolr, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
        filevardef(fsolr, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))
        filevardef(fsolr, "time",typeof(time),getvardims(time))   
        filevardef(fsolr, "SWDIFDS_RAD",typeof(rsds_gswp),getvardims(rsds_gswp))
        filevardef(fsolr, "SWDIRS_RAD",typeof(rsds_gswp),getvardims(rsds_gswp))

        filevarattdef(fsolr,"EDGEW",edgew)                           
        filevarattdef(fsolr,"EDGEE",edgee)                   
        filevarattdef(fsolr,"EDGES",edges)                    
        filevarattdef(fsolr,"EDGEN",edgen)                    
        filevarattdef(fsolr,"LONGXY",longxy)                     
        filevarattdef(fsolr,"LATIXY",latxy)
        filevarattdef(fsolr,"time",time)                        
        filevarattdef(fsolr,"SWDIFDS_RAD",rsds_gswp)
        filevarattdef(fsolr,"SWDIRS_RAD",rsds_gswp)

        setfileoption(fsolr,"DefineMode",False)

        fsolr->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
        fsolr->EDGEW  = -44.6701
        fsolr->EDGEE  = 65.05841
        fsolr->EDGES  = 21.95256 
        fsolr->EDGEN  = 72.61272

        fsolr->LONGXY = (/lon2d(:,:)/)
        fsolr->LATIXY  = (/lat2d(:,:)/)
        fsolr->SWDIFDS_RAD   = (/rsds2(:,:,:)/) 
        fsolr->SWDIRS_RAD   = (/rsds1(:,:,:)/)       

      end if
;#######################

      if (write_prec) then

        system("rm -f "+clim_output+"clmforc.COSMOREA6.Prec."+year+"-"+month(m)+".nc")    ; remove if exists
        fprec  = addfile(clim_output+"clmforc.COSMOREA6.Prec."+year+"-"+month(m)+".nc","c")

        setfileoption(fprec,"DefineMode",True)

        fAtt               = True            ; assign file attributes
        fAtt@case_title    = "COSMO REA6: Precipitation "  
        fAtt@conventions   = "CF-1.0" 
        fAtt@title         = "CLM forcing based on COSMO REA6"  
        fAtt@history       = "Original data from COSMO REA6 data"
        fAtt@creation_date = systemfunc ("date")        
        fileattdef( fprec, fAtt )            ; copy file attributes  

        dimNames = (/"scalar","lon","lat","time"/)  
        dimSizes = (/ nscalar, nlon, nlat, -1 /) 
        dimUnlim = (/ False, False, False, True/)   
        filedimdef(fprec,dimNames,dimSizes,dimUnlim)

        filevardef(fprec, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
        filevardef(fprec, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
        filevardef(fprec, "EDGES"  ,typeof(edges),getvardims(edges))                          
        filevardef(fprec, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
        filevardef(fprec, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
        filevardef(fprec, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))
        filevardef(fprec, "time",typeof(time),getvardims(time))   
        filevardef(fprec, "RAIN_CON",typeof(prec_gswp),getvardims(prec_gswp))
        filevardef(fprec, "RAIN_GSP",typeof(prec_gswp),getvardims(prec_gswp))
        filevardef(fprec, "SNOW_GSP",typeof(prec_gswp),getvardims(prec_gswp))
        filevardef(fprec, "SNOW_CON",typeof(prec_gswp),getvardims(prec_gswp))
        filevardef(fprec, "PRECIPmms",typeof(prec_gswp),getvardims(prec_gswp))

        filevarattdef(fprec,"EDGEW",edgew)                           
        filevarattdef(fprec,"EDGEE",edgee)                   
        filevarattdef(fprec,"EDGES",edges)                    
        filevarattdef(fprec,"EDGEN",edgen)                    
        filevarattdef(fprec,"LONGXY",longxy)                     
        filevarattdef(fprec,"LATIXY",latxy)
        filevarattdef(fprec,"time",time)
        filevarattdef(fprec,"RAIN_CON",prec_gswp)  
        filevarattdef(fprec,"RAIN_GSP",prec_gswp)  
        filevarattdef(fprec,"SNOW_CON",prec_gswp)  
        filevarattdef(fprec,"SNOW_GSP",prec_gswp)    
        filevarattdef(fprec,"PRECIPmms",prec_gswp)    

        fprec->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
        fprec->EDGEW  = -44.6701
        fprec->EDGEE  = 65.05841
        fprec->EDGES  = 21.95256 
        fprec->EDGEN  = 72.61272
        fprec->LONGXY = (/lon2d(:,:)/)
        fprec->LATIXY  = (/lat2d(:,:)/)
        fprec->RAIN_CON   = (/rain_con(:,:,:)/)         ; !!!! time variable can be modified in the attributes of the variable is also copied. make sure to use (/ /) to only copy data.
        fprec->RAIN_GSP   = (/rain_gsp(:,:,:)/)
        fprec->SNOW_CON   = (/snow_con(:,:,:)/)
        fprec->SNOW_GSP   = (/snow_gsp(:,:,:)/)
        fprec->PRECIPmms  = (/prec(:,:,:)/)

      end if

;#######################

      if (write_tpqwl) then

        system("rm -f "+clim_output+"clmforc.COSMOREA6.TPQWL."+year+"-"+month(m)+".nc")   ; remove if exists
        ftpqwl = addfile(clim_output+"clmforc.COSMOREA6.TPQWL."+year+"-"+month(m)+".nc","c")

        setfileoption(ftpqwl,"DefineMode",True)

        fAtt               = True            ; assign file attributes
        fAtt@case_title    = "COSMO REA6: Solr "  
        fAtt@conventions   = "CF-1.0" 
        fAtt@title         = "CLM forcing based on COSMO REA6"  
        fAtt@history       = "Original data from COSMO REA6 data"
        fAtt@creation_date = systemfunc ("date")        
        fileattdef( ftpqwl, fAtt )            ; copy file attributes  

        dimNames = (/"scalar","lon","lat","time"/)  
        dimSizes = (/ nscalar, nlon, nlat, -1 /) 
        dimUnlim = (/ False, False, False, True/)   
        filedimdef(ftpqwl,dimNames,dimSizes,dimUnlim)

        filevardef(ftpqwl, "EDGEW" ,typeof(edgew),getvardims(edgew)) 
        filevardef(ftpqwl, "EDGEE"  ,typeof(edgee),getvardims(edgee))                           
        filevardef(ftpqwl, "EDGES"  ,typeof(edges),getvardims(edges))                          
        filevardef(ftpqwl, "EDGEN"  ,typeof(edgen),getvardims(edgen))                          
        filevardef(ftpqwl, "LONGXY" ,typeof(longxy)  ,getvardims(longxy))    
        filevardef(ftpqwl, "LATIXY"  ,typeof(latxy) ,getvardims(latxy))
        filevardef(ftpqwl, "time",typeof(time),getvardims(time)) 
        filevardef(ftpqwl, "T",typeof(tbot_gswp),getvardims(tbot_gswp))
        filevardef(ftpqwl, "U",typeof(wind_gswp),getvardims(wind_gswp))
        filevardef(ftpqwl, "V",typeof(wind_gswp),getvardims(wind_gswp))
        filevardef(ftpqwl, "WIND",typeof(wind_gswp),getvardims(wind_gswp))
        filevardef(ftpqwl, "PS",typeof(psrf_gswp),getvardims(psrf_gswp))
        filevardef(ftpqwl, "Q",typeof(qbot_gswp),getvardims(qbot_gswp)) 
        filevardef(ftpqwl, "FLDS",typeof(flds_gswp),getvardims(flds_gswp))

        filevarattdef(ftpqwl,"EDGEW",edgew)                           
        filevarattdef(ftpqwl,"EDGEE",edgee)                   
        filevarattdef(ftpqwl,"EDGES",edges)                    
        filevarattdef(ftpqwl,"EDGEN",edgen)                    
        filevarattdef(ftpqwl,"LONGXY",longxy)                     
        filevarattdef(ftpqwl,"LATIXY",latxy)
        filevarattdef(ftpqwl,"time",time)
        filevarattdef(ftpqwl,"T",tbot_gswp)    
        filevarattdef(ftpqwl,"U",wind_gswp)    
        filevarattdef(ftpqwl,"V",wind_gswp)    
        filevarattdef(ftpqwl,"WIND",wind_gswp) 
        filevarattdef(ftpqwl,"PS",psrf_gswp)    
        filevarattdef(ftpqwl,"Q",qbot_gswp)    
        filevarattdef(ftpqwl,"FLDS",flds_gswp)    

        ftpqwl->time   = (/time/)        ; "(/", "/)" syntax tells NCL to only output the data values to the predefined locations on the file.
        ftpqwl->EDGEW  = -44.6701
        ftpqwl->EDGEE  = 65.05841
        ftpqwl->EDGES  = 21.95256 
        ftpqwl->EDGEN  = 72.61272
        ftpqwl->LONGXY = (/lon2d(:,:)/)
        ftpqwl->LATIXY  = (/lat2d(:,:)/)
        ftpqwl->T   = (/tbot(:,:,:)/)
        ftpqwl->U   = (/u(:,:,:)/)
        ftpqwl->V   = (/v(:,:,:)/)
        ftpqwl->WIND   = (/wind(:,:,:)/)
        ftpqwl->PS   = (/psrf(:,:,:)/)
        ftpqwl->Q   = (/qbot(:,:,:)/)
        ftpqwl->FLDS   = (/flds(:,:,:)/)

      end if

      delete(rsds1)
      delete(rsds2)
      delete(time)
      delete(tbot)
      delete(qbot)
      delete(u)
      delete(v)
      delete(wind)
      delete(psrf)
      delete(flds)
      delete(rain_gsp)
      delete(rain_con)
      delete(snow_gsp)
      delete(snow_con)
      delete(prec)
      
   end do

 end do

;#############
;      <value  stream="COSMOREA6.Solar">
;        SWDIFDS_RAD swdndf
;        SWDIRS_RAD swdndr
;      </value>
;      <value  stream="COSMOREA6.Precip">
;        RAIN_CON rainc
;        RAIN_GSP rainl
;        SNOW_CON snowc
;        SNOW_GSP snowl
;      </value>
;      <value  stream="COSMOREA6.TPQW">
;        T     tbot
;        Q     shum
;        PS    pbot
;        U     u
;        V     v
;        FLDS     lwdn
;      </value>
;      <value  stream="NORA10.Solar">
;       rss swdn     #### NORA10 only have net shortwave radiation, divided by albedo (albedo).
;      </value>
;      <value  stream="NORA10.Precip">
;        pr precn
;      </value>
;      <value  stream="NORA10.TPQW">
;        ta_10m   tbot
;        windspeed_10m   wind
;        td_10m   tdew
;        ps     pbot
;        rls    lwdn   #### Nora10 only have net longwave radiation, can not derive downward longwave radiation.
;      </value>
;#############

end
