####################################################################################
# Temporal Degrain v2.3.1 Updated by ErazorTT                                      #
#                                                                                  #
# Function v1.23 by Sagekilla, idea + original script created by Didee             #
#                                                                                  #
# Works as a simple temporal degraining function that'll remove                    #
# MOST or even ALL grain and noise from video sources,                             #
# including dancing grain, like the grain found on 300.                            #
# Also note, the parameters don't need to be tweaked much.                         #
#                                                                                  #
# Required plugins:                                                                #
# neo_fft3d: https://github.com/HomeOfAviSynthPlusEvolution/neo_FFT3D/releases     #
# MaskTools2: https://github.com/pinterf/masktools/releases                        #
# MVtools2 (mt_*): https://github.com/pinterf/mvtools/releases                     #
# rgTools (RemoveGrain,Repair): https://github.com/pinterf/RgTools/releases        #
#                                                                                  #
# Optional plugins:                                                                #
# Dither tools: http://avisynth.nl/index.php/Dither_tools                          #
# neo_dfttest: https://github.com/HomeOfAviSynthPlusEvolution/neo_DFTTest/releases #
# KNLMeansCL: https://github.com/pinterf/KNLMeansCL/releases                       #
# BM3D: https://github.com/WolframRhodium/VapourSynth-BM3DCUDA/issues/7            #
# FFT3DGPU: https://github.com/pinterf/FFT3dGPU/releases                           #
# HQdn3D: http://avisynth.nl/index.php/Hqdn3d                                      #
# old FFT3DFilter: https://github.com/pinterf/fft3dfilter/releases                 #
# old dfttest: https://github.com/pinterf/dfttest                                  #
####################################################################################

# recommendations to be followed for each new movie:
# 1. start with default settings
# 2. if less denoising is needed set grainLevel to 0, if you need more degraining start over reading at next paragraph
# 3. if you need even less denoising:
#    - EITHER: set outputStage to 1 or even 0
#    - OR: use the postMix setting and increase the value from 0 to as much as 100

# recommendations for strong degraining: 
# 1. start with default settings
# 2. search the noisiest* patch of the entire movie, enable grainLevelSetup (=true), zoom in as much as you can and prepare yourself for pixel peeping. (*it really MUST be the noisiest region where you want this filter to be effective)
# 3. compare the output on this noisy* patch of your movie with different settings of grainLevel (0,1,2) and use the setting where the noise level is lowest (irrespectable of whether you find this to be too much filtering).
#    If multiple grainLevel settings yield comparable results while grainLevelSetup=true and observing at maximal zoom be sure to use the lowest setting! If you're unsure leave it at the default (2), your result might no be optimal, but it will still be great.
# 4. disable grainLevelSetup (=false), or just remove this argument from the function call. Now revert the zoom and look from a normal distance at different scenes of the movie and decide if you like what you see.
# 5. if more denoising is needed try postFFT=1 with postSigma=1, then tune postSigma (obvious blocking and banding of regions in the sky are indications of a value which is at least a factor 2 too high)
# 6. if you would need a postSigma of more than 2, try first to increase degrainTR. The goal is to balance postSigma and degrainTR, some prefer more simga and others more TR, it's up to you. However, do not increase degrainTR above 1/8th of the fps (at 24fps up to 3).
# 7. if there are any issues with banding or you cranked up postSigma a lot try postFFT=3

# use only the following knobs (all other settings should already be where they need to be):
# - degrainTR (1), temporal radius of degrain, usefull range: min=default=1, max=fps/8. Higher values do clean the video more, but also increase probability of wrongly identified motion vectors which leads to washed out regions
# - grainLevel (2), if input noise level is relatively low set this to 0. The right setting must be found using grainLevelSetup=true while all other settings are at default. Set this setting such that the noise level is lowest.
# - grainLevelSetup (false), only to be used while finding the right setting for grainLevel. This will skip all your other settings!
# - postFFT (0), if you want to remove absolutely all remaining noise suggestion is to use 3 (dfttest) for its quality or 1 (ff3dfilter) is much faster but can introduce banding. 2 and 4 are GPU based versions.
# - postSigma (1), increase it to remove all the remaining noise you want removed, but do not increase too much since unnecessary high values have severe negative impact on either banding and/or sharpness
# - postDither (-1), positive values are used as parameter for dfttest (values above 2 can remove preexinsting banding), negative values indicate 16 bits FFT processing (to be used only with postFFT=1 or in case of strong paranoia regarding banding)
# - degrainPlane (4), if you just want to denoise only the chroma use 3 (helps with compressability with the clip being almost identical to the original)
# - postMix (0), if the degraining is too strong, increase the value going from 0 to 100
# - outputStage (2), if the degraining is too strong, you can output earlier stages

# Changelog: 
# May 15, 2018: v2.0
# - use the exeptional motion estimation from QTGMC
# - use MDegrainN for unbound temporal radius
# - automatic tuning of default parameters based on input size
# - add optional motion compensated post processing FFT filtering
# Oct 19, 2018: v2.0.1
# - rename function to TemporalDegrain2
# - expose TrueMotion parameter through meTM, and let it default to false
# Oct 22, 2018: v2.0.2
# - use power of 2 blocksizes for MAnalyse which have much better performance
# - check that Undot exists before calling it
# Oct 23, 2018: v2.0.3
# - use RemoveGrain(1) instead of Undot
# Oct 26, 2018: v2.1
# - tune motion estimation
# Oct 27, 2018: v2.1.1
# - allow for a controlled over-sharpen through extraSharp
# - correct parameter types
# Oct 30, 2018: v2.1.2
# - correct usage of KNLMeansCL
# - update comments
# Nov 03, 2018: v2.1.3
# - another try to fix KNLMeansCL
# - expose KNLMeansCL device id through knlDevId
# Nov 19, 2018: v2.1.4
# - minor updates to code comments
# Dec 26, 2018: v2.1.5
# - convert TV range to PC range in search clip, improving motion estimation (idea from SMDegrain)
# Dec 27, 2018: v2.1.6
# - tweak parameters for higher noise removal
# Dec 27, 2018: v2.1.7
# - settings depening on input noise level, flag must be set manually
# - add post processing behaviour of TemporalDegrain v1.23 to postFFT=-1
# - change defaults and rewrite recommendations
# Jan 02, 2019: v2.2
# - high bit support, native "double width" format not "stacked" format
# - currently just postFFT=0, 1 and 4 are supported for high bit depths
# Feb 24, 2019: v2.2.1
# - swap deprecated use of ConvertToXbit by ConvertBits
# - relaxed settings for scene change detection, was too aggressive
# Apr 12, 2019: v2.2.2
# - refine input size categorization
# Feb 02, 2021: v2.2.3
# - rescale SAD/SCD thresholds when DCT is switched from SAD to SATD
# - allow change of motion estimation also based on chroma (meChroma)
# Feb 02, 2021: v2.2.4
# - use optional high bitdepth processing for FFT3DGPU
# - added postMix setting do be able to degrease filter strength
# Feb 02, 2021: v2.2.5
# - use neo fft
# - add optional high bitdepth processing for dfttest
# Feb 05, 2021: v2.2.6
# - correct scaling for DCT=5 and set it as default
# Feb 07, 2021: v2.3.0
# - use native high bit format also for KNLMeansCL
# - scale sigma of FFT3DGPU
# - grainLevel is now interger range 0-2
# - make setup of grainLevel easier by using parameter grainLevelSetup=true
# - provide user with the choice which stage of the pipeline to output (outputStage)
# Feb 07, 2021: v2.3.1
# - tune grainLevel 1 to fit more centrally between 0 and 2
# - reorganize arguments by impoprtance
# Aug 12, 2021: mod by kedautinh12
# - add BM3D_CPU & BM3D_CUDA (based on BM3D prefilter of Dogway's SMDegrain)
# Sep 07, 2021: mod by kedautinh12
# - optimization BM3D (based on BM3D prefilter of Dogway's SMDegrain)
# Oct 01, 2021: mod by kedautinh12
# - improve sigma value of BM3D
# Oct 23, 2021: mod by kedautinh12
# - fix bug with device_id in BM3D
# Nov 12, 2021: mod by kedautinh12
# - fix artefacts in BM3D

function TemporalDegrain2 ( clip input, int "degrainTR", int "grainLevel", bool "grainLevelSetup", int "degrainPlane", int "postFFT", int "postTR", float "postSigma", int "postDither", int "postMix", \
    int "meAlg", int "meAlgPar", int "meSubpel", int "meBlksz", bool "meTM", bool "meChroma", int "limitFFT", float "limitSigma", int "limitBlksz", int "fftThreads", \
    int "device_id", float "ppSAD1", float "ppSAD2", float "ppSCD1", int "thSCD2", int "DCT", float "gaussParam", bool "extraSharp", int "outputStage", bool "debug")
{
  longlat = (input.Width() > input.Height()) ?  input.Width() : input.Height()
  shorlat = (input.Width() < input.Height()) ?  input.Width() : input.Height()
  autoTune = (longlat<=1050 && shorlat<=576) ? 0 : \
             (longlat<=1280 && shorlat<=720) ? 1 : \
             (longlat<=2048 && shorlat<1600) ? 2 : 3

  degrainTR = default( degrainTR,1 )        # MDegrain temporal radius. 
  degrainPlane = default( degrainPlane, 4 ) # which planes to degrain: 0=luma, 3=chroma, 4=luma+chroma.
  grainLevel= default( grainLevel, 2 )      # can be set to 0 when the noise level of the input is so low that it does not disturb the motion estimation. Thus decreasing probability of smearing of very fine high velocity detail and increasing speed.
  
  meAlg   = default( meAlg,    4 )          # Motion estimation algorithm (5 might be a little better but is significantly slower, 2 will be a little faster while missing some vectors), https://forum.doom9.org/showthread.php?p=693742
  meAlgPar= default( meAlgPar, Select( meAlg,2,2,2,2,16,24,2,2 ) ) # radius/range parameter for the motion estimation algorithms
  meSubpel= default( meSubpel, Select( autoTune, 4, 2, 2, 1 ) )    # higher values increase motion vector quality at the cost of speed
  meBlksz = default( meBlksz,  Select( autoTune, 8, 8,16,32 ) )    # higher values for more speed, but higher probability of smearing of fine details, do also not go too small so that blocks still have enough content to be distinguishable
  meTM    = default( meTM,     false )      # this is the default of QTGMC and prefered by Didee (https://forum.doom9.org/showthread.php?p=1407409&highlight=truemotion#post1407409)
  meChroma= default( meChroma, true )       # use also chroma plane for motion vectors
  
  limitFFT= default( limitFFT,  1 )         # Algorithm for producing the limiting clip, 1 for CPU based, 2 for GPU based.
  limitSigma= default( limitSigma, Select( autoTune, 8,12,16,32 ) )    # strength of filtering for limit clip
  limitBlksz= default( limitBlksz, Select( autoTune,16,24,32,64 ) )    # FFT3D blocksize
 
  postFFT = default( postFFT,   0 )         # Whether the FFT post processing takes place, deminishes remaining noise, 1 is fast but produces some banding, 3 is of high quality but slow, 5 is of very high quality but slowest, 2, 4 and 6 are GPU based versions. -1 is the fastest smoothing, equivalent behaviour of TemporalDegrain v1.23.
  postTR  = default( postTR,    1 )         # Temporal radius of FFT processing, increasing to 2 does not help much, but is much slower
  postSigma=default( postSigma,1.0)         # Strength of the filtering
  postDither=default(postDither,-1)         # any negative value enables 16bit post FFT with a final call to ditherpost, positive values are dithering strength for dfttest
  postMix = default (postMix,   0 )         # increase the value up to 100 if you want less degraining
  device_id = default(device_id,  0 )

  fftThreads = default( fftThreads, 1 )     # Number of threads to be used for FFTs
  extraSharp = default( extraSharp, false)  # enable for a moderate over-sharpen, do not use this if you want the output to be as close to the original as possible, only to be used by sharpness junkies
  DCT        = default( DCT, 5    )         # default setting of 0 has issues with luminosity changes from one frame to the next (e.g. fade-ins, fade-outs, moving shaddows), the degraining will be much too weak. Setting to 5 will solve this issue, but it's also slower. All other settings apart of 0 and 5 are not to be used!
  
  outputStage = default( outputStage, 2 )   # you can decide to skip the processing of later stages and directly output the clip as process of the stage given: 0= output after first degraining, 1= output after second degraining, 2= output after FFT post processing (that's the last stage and the default)
  grainLevelSetup = default(grainLevelSetup, false)
  debug      = default (debug, false)
  
  outputStage = grainLevelSetup ? 0 : outputStage
  degrainTR = grainLevelSetup ? 3 : degrainTR
  
  postTR  = (postFFT > 0) ? postTR : 0
  postTD  = postTR * 2 + 1
  maxTR = (degrainTR > postTR) ? degrainTR : postTR
  LumaNoise = (degrainPlane == 0) || (degrainPlane == 4)
  ChromaNoise = (degrainPlane > 0) ? true : false
  Chr = ChromaNoise ? 3 : 1
  inHighBits = input.BitsPerComponent()>8
  postDither = inHighBits ? 0 : postDither

  ChromaMotion = meChroma
  GlobalNames = "TD2"
  ReuseGlobals = false
  ReplaceGlobals = false
  SubPelInterp = 2 #fix?
  SubPel = meSubpel
  Blocksize = meBlksz
  Overlap = Blocksize/2
  Search = meAlg
  SearchParam = meAlgPar
  PelSearch = SubPel
  TrueMotion = meTM
  GlobalMotion = true #fix!
  SrchClipPP = (grainLevel > 0) ? 3 : 0
  gaussParam = default(gaussParam, grainLevel > 1 ? 3.0 : 6.0)
  
  Lambda = ((TrueMotion) ? 1000 : 100 ) * (BlockSize*BlockSize)/(8*8)
  LSAD   = (TrueMotion) ? 1200 : 400
  PNew   = (TrueMotion) ? 50   : 25
  PLevel = (TrueMotion) ? 1    : 0
  ppSAD1 = default(ppSAD1, 10)
  ppSAD2 = default(ppSAD2, 6)
  ppSCD1 = default(ppSCD1, 5)
  ppSAD1 = (DCT == 5) ? (ppSAD1 * 1.7) : ppSAD1 #rescale threshold to match the SAD values when using SATD
  ppSAD2 = (DCT == 5) ? (ppSAD2 * 1.7) : ppSAD2 #rescale threshold to match the SAD values when using SATD
  ppSCD1 = ppSCD1 #this must not be scaled since scd is always based on SAD independently of the actual dct setting
  thSAD1 = int(ppSAD1*8*8)   #here the per-pixel measure is converted to the per-8x8-Block measure MVTools is using
  thSAD2 = int(ppSAD2*8*8)   #here the per-pixel measure is converted to the per-8x8-Block measure MVTools is using
  thSCD1 = int(ppSCD1*8*8)   #here the per-pixel measure is converted to the per-8x8-Block measure MVTools is using
  thSCD2 = default(thSCD2, 130)            #MVTools default
  
  #---------------------------------------
  # Pre-Processing
  
  Assert(input.IsYUV() == true, \
     "TemportalDegrain2: expecting progressive YUV as input format")
  
  w = input.Width()
  h = input.Height()
  epsilon = 0.0001

  # Reverse "field" dominance for progressive repair mode 3 (only difference from mode 2)
  compl = input

  # Pad vertically during processing (to prevent artefacts at top & bottom edges)
  clip = compl

  # Calculate padding needed for MVTools super clips to avoid crashes [fixed in latest MVTools, but keeping this code for a while]
  hpad = w - (Int((w - Overlap) / (Blocksize - Overlap)) * (Blocksize - Overlap) + Overlap)
  vpad = h - (Int((h - Overlap) / (Blocksize - Overlap)) * (Blocksize - Overlap) + Overlap)
  hpad = (hpad > 8) ? hpad : 8 # But match default padding if possible
  vpad = (vpad > 8) ? vpad : 8
  
  #---------------------------------------
  # Motion Analysis

  # >>> Planar YUY2 for motion analysis, interleaved whilst blurring search clip
  planarClip = clip

  # Bob the input as a starting point for motion search clip
  bobbed = planarClip 
  
  # If required, get any existing global clips with a matching "GlobalNames" setting. Unmatched values get NOP (= 0)
  srchClip  = DT_GetUserGlobal( GlobalNames, "srchClip",  ReuseGlobals )
  srchSuper = DT_GetUserGlobal( GlobalNames, "srchSuper", ReuseGlobals )
  vmulti    = DT_GetUserGlobal( GlobalNames, "vmulti",    ReuseGlobals )

  CMmt = ChromaMotion ? 3   :  1
  CMts = ChromaMotion ? 255 :  0
  CMrg = ChromaMotion ? 12  : -1
  
  # Remove areas of difference between temporal blurred motion search clip and bob that are not due to bob-shimmer - removes general motion blur
  repair0 = bobbed
  
  # Luma expansion TV->PC (up to 16% more values for motion estimation)
  repair0 = inHighBits ? repair0.ConvertBits(8,dither=-1) : repair0 
  repair0 = repair0.ColorYUV(levels="TV->PC")

  # Blur image and soften edges to assist in motion matching of edge blocks. Blocks are matched by SAD (sum of absolute differences between blocks), but even
  # a slight change in an edge from frame to frame will give a high SAD due to the higher contrast of edges
  spatialBlur = (IsClip(srchClip) || SrchClipPP == 0) ? NOP() :		\
    (SrchClipPP == 1) ? repair0.BilinearResize( w/2, h/2 ).RemoveGrain( 12,CMrg ).BilinearResize( w, h ) : \
    repair0.RemoveGrain( 12,CMrg ).GaussResize( w,h, 0,0, w+epsilon,h+epsilon, p=gaussParam )
  spatialBlur = (IsClip(spatialBlur) && SrchClipPP > 1) ? (ChromaMotion ? spatialBlur.Merge( repair0, 0.1 ) : spatialBlur.MergeLuma( repair0, 0.1 )) : spatialBlur
  tweaked     = repair0
  srchClip    = IsClip(srchClip)  ? srchClip :	 \
    (SrchClipPP == 0) ? repair0 :			     \
    (SrchClipPP < 3)  ? spatialBlur :			 \
    spatialBlur.mt_lutxy( tweaked, "x 7 scalef + y < x 2 scalef + x 7 scalef - y > x 2 scalef - x 51 * y 49 * + 100 / ? ?", U=CMmt, V=CMmt, use_expr=2)
  #return srchClip.Subtitle("blz:"+String(BlockSize)+" ov:"+String(Overlap)+" se:"+String(Search)+" pa:"+String(SearchParam)+" ps:"+String(PelSearch))
  # Calculate forward and backward motion vectors from motion search clip
  srchSuper = IsClip(srchSuper) ? srchSuper :				\
    (maxTR > 0) ? srchClip.MSuper( pel=SubPel, sharp=SubPelInterp, hpad=hpad, vpad=vpad, chroma=ChromaMotion ) : NOP()
  vmulti = IsClip(vmulti) ? vmulti : \
    (maxTR > 0) ? srchSuper.MAnalyse( isb=true, multi=true, delta=maxTR, blksize=BlockSize, overlap=Overlap, search=Search, searchparam=SearchParam, \
                               pelsearch=PelSearch, truemotion=TrueMotion, lambda=Lambda, lsad=LSAD, pnew=PNew, plevel=PLevel, \
                               global=GlobalMotion, DCT=DCT, chroma=ChromaMotion ) : NOP()
                               
  #return(MShow(srchSuper,vmulti.SelectEvery(maxTR*2,0)))
  # Expose search clip, motion search super clip and motion vectors to calling script through globals
  DT_SetUserGlobal( GlobalNames, "srchClip",  srchClip,  ReplaceGlobals )
  DT_SetUserGlobal( GlobalNames, "srchSuper", srchSuper, ReplaceGlobals )
  DT_SetUserGlobal( GlobalNames, "vmulti",    vmulti,    ReplaceGlobals )
  
  #---------------------------------------
  # Degrain

  dgO  = clip
  dgS2 = floor( limitSigma * 0.625 ) # See sigma
  dgS3 = floor( limitSigma * 0.375 ) # See sigma
  dgS4 = floor( limitSigma * 0.250 ) # See sigma
  dgOvNum = Select(grainLevel, 4, 3, 2)
  dgOv = limitBlksz/dgOvNum
  
  dgLimit = (degrainTR>0 && limitFFT==1) ? dgO.neo_fft3d(y=LumaNoise?3:2, u=ChromaNoise?3:2, v=ChromaNoise?3:2, sigma=limitSigma, sigma2=dgS2, sigma3=dgS3, sigma4=dgS4, bt=3, bw=limitBlksz, bh=limitBlksz, ow=dgOv, oh=dgOv, ncpu=fftThreads ) : \
            (degrainTR>0 && limitFFT==11)? dgO.FFT3DFilter(plane=degrainPlane, sigma=limitSigma, sigma2=dgS2, sigma3=dgS3, sigma4=dgS4, bt=3, bw=limitBlksz, bh=limitBlksz, ow=dgOv, oh=dgOv, ncpu=fftThreads) : \
            (degrainTR>0 && limitFFT==2) ? dgO.FFT3DGPU(plane=degrainPlane, sigma=limitSigma, sigma2=dgS2, sigma3=dgS3, sigma4=dgS4, bt=3, bw=limitBlksz, bh=limitBlksz, ow=dgOv, oh=dgOv) : NOP()
  #dgLimit = grainLevel ? dgLimit.HQdn3D(4,3,6,3) : dgLimit  #for very grainy input this will remove very slightly some more noise
  
  # "spat" is a prefiltered clip which is used to limit the effect of the 1st MV-denoise stage.
  # For simplicity, we just use the FFT3DFilter. There's lots of other possibilities.
  dgSpatD= (degrainTR>0) ? mt_makediff(dgO,dgLimit) : NOP()
  
  # First MV-denoising stage. Usually here's some temporal-medianfiltering going on.
  # For simplicity, we just use MVDegrain.
  dgVm  = (degrainTR>0) ? vmulti.SelectRangeEvery(maxTR*2,degrainTR*2) : NOP()
  dgOs  = (degrainTR>0) ? dgO.MSuper(pel=SubPel, levels=1, chroma=ChromaNoise) : NOP()
  dgNR1 = (degrainTR>0) ? dgO.MDegrainN(dgOs, dgVm, degrainTR, plane=degrainPlane, thSAD=thSAD1, thSCD1=thSCD1, thSCD2=thSCD2) : NOP()
  
  # Limit NR1 to not do more than what "spat" would do.
  dgNR1D = (degrainTR>0) ? mt_makediff(dgO,dgNR1) : NOP()
  dgDD   = (degrainTR>0) ? mt_lutxy(dgSpatD,dgNR1D,"x range_half - abs y range_half - abs < x y ?",use_expr=2) : NOP()
  dgNR1x = (degrainTR>0) ? mt_makediff(dgO,dgDD,U=2,V=2) : NOP()
  
  # Second MV-denoising stage. We use MVDegrain2.
  dgNR1xS= (degrainTR>0) ? dgNR1x.MSuper(pel=SubPel, levels=1, chroma=ChromaNoise) : NOP()
  dgNR2  = (degrainTR>0) ? dgNR1x.MDegrainN(dgNR1xS, dgVm, degrainTR, plane=degrainPlane, thSAD=thSAD2, thSCD1=thSCD1, thSCD2=thSCD2) : dgO
  
  #---------------------------------------
  # post FFT

  fullClip = dgNR2
  
  fullSuper = (postTR > 0) ? fullClip.MSuper( pel=subpel, levels=1, chroma=ChromaNoise ) : NOP() 
  noiseWindow = (postTR == 0) ? fullClip :				\
                fullClip.MCompensate( fullSuper, vmulti.SelectRangeEvery(maxTR*2,postTR*2), tr=postTR, center=true, thSAD=thSAD2, thSCD1=thSCD1, thSCD2=thSCD2 )
                           
  dftDither = (postDither > 0) ? postDither : 0
  forceHiBitProc = (postDither < 0) ? true : false
  dnWindow = (postFFT == 0) ? noiseWindow.RemoveGrain(mode=1) :				\
             (postFFT == 1) ? neo_fft3d( forceHiBitProc ? noiseWindow.ConvertBits(16) : noiseWindow, y=LumaNoise?3:2, u=ChromaNoise?3:2, v=ChromaNoise?3:2, sigma=postSigma, bt=postTD, ncpu=fftThreads ) : \
             (postFFT == 11)? FFT3DFilter( forceHiBitProc ? noiseWindow.ConvertBits(16) : noiseWindow, plane=degrainPlane, sigma=postSigma, bt=postTD, ncpu=fftThreads ) : \
             (postFFT == 2) ? FFT3DGPU( forceHiBitProc ? noiseWindow.ConvertBits(16) : noiseWindow, plane=degrainPlane, sigma=postSigma*2/3, bt=postTD ) : \
             (postFFT == 3) ? neo_dfttest( forceHiBitProc ? noiseWindow.ConvertBits(16) : noiseWindow, y=LumaNoise?3:2, u=ChromaNoise?3:2, v=ChromaNoise?3:2, sigma=postSigma*4, tbsize=postTD, dither=dftDither, threads=fftThreads ) : \
             (postFFT == 13)? dfttest( forceHiBitProc ? noiseWindow.ConvertBits(16) : noiseWindow, Y=LumaNoise, U=ChromaNoise, V=ChromaNoise, sigma=postSigma*4, tbsize=postTD, threads=fftThreads, dither=dftDither ) : \
             (postFFT == 4) ? DT_KNLMeansCL( forceHiBitProc ? noiseWindow.ConvertBits(16) : noiseWindow, a=2, d=postTR, h=0.5*postSigma, Luma = LumaNoise, Chroma = ChromaNoise, device_type="GPU", device_id=device_id ) : \
             (postFFT == 5) ? DT_BM3D( noiseWindow, radius=postTR, sigma=0.5*postSigma, CUDA=false, UV=Chr ) : \
             (postFFT == 6) ? DT_BM3D( noiseWindow, radius=postTR, sigma=0.5*postSigma, CUDA=true, UV=Chr, device_id=device_id ) : \
             (postFFT == -1)? noiseWindow.HQDn3D(0,0,4,1) : NOP()
  dnWindow = dnWindow.SelectEvery( postTD, postTR )
  denoised = forceHiBitProc && postFFT > 0  ? dnWindow.ConvertBits(8,dither=1) : dnWindow

  sharpened = DT_ContraSharpening(denoised, dgO, extraSharp)
  
  # mix with original to leave the posibility to decrease the denoising strength
  sharpened = postMix > 0 ? mt_lutxy(dgO,sharpened,"x "+String(postMix)+" * y "+String(int(100-postMix))+" * + 100 /") : sharpened

  # Crop off temporary vertical padding
  cropped = sharpened
  
  output = debug ? Select(outputStage, dgNR1x, dgNR2, cropped, repair0, spatialBlur, srchClip, dgLimit, denoised) : Select(outputStage, dgNR1x, dgNR2, cropped)
  return output
}

# contra-sharpening: sharpen the denoised clip, but don't add more to any pixel than what was removed previously.
# script function from Didee from the VERY GRAINY thread
function DT_ContraSharpening(clip denoised, clip original, bool "extraSharp")
{
  # Damp down remaining spots of the denoised clip.
  s = denoised.DT_MinBlur(1,1)

  # The difference achieved by the denoising.
  allD = mt_makediff(original,denoised)

  # The difference of a simple kernel blur.
  ssD = mt_makediff(s,extraSharp?s.removegrain(20,-1).removegrain(20,-1):s.removegrain(11,-1))

  # Limit the difference to the max of what the denoising removed locally.
  ssDD = ssD.repair(extraSharp?ssD.repair(allD,1):allD,extraSharp?12:1)

  # abs(diff) after limiting may not be bigger than before.
  ssDD = SSDD.mt_lutxy(ssD,"x range_half - abs y range_half - abs < x y ?",use_expr=2)

  # Apply the limited difference. (Sharpening is just inverse blurring.)
  denoised.mt_adddiff(ssDD,U=2,V=2)
  
  return(last)
}

# MinBlur by Didee, http://avisynth.org/mediawiki/MinBlur
# Nifty Gauss/Median combination
function DT_MinBlur(clip clp, int r, int "uv")
{
  uv   = default(uv,3)
  uv2  = (uv==2) ? 1 : uv
  rg4  = (uv==3) ? 4 : -1
  rg11 = (uv==3) ? 11 : -1
  rg20 = (uv==3) ? 20 : -1
  medf = (uv==3) ? 1 : -200

  RG11D = (r==1) ? mt_makediff(clp,clp.removegrain(11,rg11),U=uv2,V=uv2)
   \    : (r==2) ? mt_makediff(clp,clp.removegrain(11,rg11).removegrain(20,rg20),U=uv2,V=uv2)
   \    :          mt_makediff(clp,clp.removegrain(11,rg11).removegrain(20,rg20).removegrain(20,rg20),U=uv2,V=uv2)
  RG4D  = (r==1) ? mt_makediff(clp,clp.removegrain(4,rg4),U=uv2,V=uv2)
   \    : (r==2) ? mt_makediff(clp,clp.medianblur(2,2*medf,2*medf),U=uv2,V=uv2)
   \    :          mt_makediff(clp,clp.medianblur(3,3*medf,3*medf),U=uv2,V=uv2)
  DD    = mt_lutxy(RG11D,RG4D,"x range_half - y range_half - * 0 < range_half x range_half - abs y range_half - abs < x y ? ?",U=uv2,V=uv2,use_expr=2)
  clp.mt_makediff(DD,U=uv,V=uv)
  return(last)
}

function DT_KNLMeansCL(clip input, String "device_type", int "device_id", bool "Luma", bool "Chroma", bool "stacked", float "h", int "d", int "a")
{
    uplane = input.ExtractU()
    vplane = input.ExtractV()
    cw = uplane.Width()
    ch = uplane.Height()
    yw = input.Width()
    yh = input.Height()
    channels = Select( (Luma ? 1 : 0) + (Chroma ? 2 : 0), 0, "Y", "UV", "YUV" )
    strength = (Luma && Chroma) ? h*9/16 : Luma ? h : h/4.7
    temp = (Luma && Chroma) ? YToUV(uplane.BilinearResize(yw,yh), vplane.BilinearResize(yw,yh), input.ExtractY()) : Luma ? input.ExtractY() : input
    output = KNLMeansCL(temp, a=a, d=d, h=strength, channels = channels, stacked=stacked)
    (Luma && Chroma) ? YToUV(output.ExtractU().BilinearResize(cw,ch), output.ExtractV().BilinearResize(cw,ch), output.ExtractY()) : Luma ? YToUV(uplane, vplane, output) : output
}

function DT_BM3D(clip a, float "sigma", int "radius", bool "CUDA", int "UV", int "device_id") {

    rgb = isRGB(a)
    isy = isy(a)
    bi  = BitsPerComponent(a)

    s  = Default(sigma,    3)
    r  = Default(radius,   1)
    cd = Default(CUDA,  true)
    UV = Default(UV,    rgb ? 3 : 1)
    device_id = Default(device_id, 0)

    ch = !(isy || UV!=3)
    ch ? ConverttoYUV444(a,chromaresample="spline16") : a
    ConvertBits(bits=32)

    cd ? BM3D_CUDA(sigma=[s,ch?s/2:0,ch?s/2:0], radius=r, chroma=ch, fast=true, extractor_exp=6, device_id=device_id) : \
         BM3D_CPU( sigma=[s,ch?s/2:0,ch?s/2:0], radius=r, chroma=ch)
         BM3D_VAggregate(radius=r)

    if (bi < 32) {
        ConvertBits(bits=16, dither=-1)
        ConvertBits(bits=bi, dither= 1)
    }
    ch ? MatchColorFormat(a) : mergechroma(a) }
    
# Set global variable called "Prefix_Name" to "Value". Throws exception if global already exists unless Replace=true, in which case the global is overwritten
function DT_SetUserGlobal( string Prefix, string Name, val Value, bool "Replace" )
{
	Replace = default( Replace, false )
	globalName = Prefix + "_" + Name

	# Tricky logic to check global: enter catch block if Replace=true *or* globalName doesn't exist (i.e. need to set the global), the exception is not rethrown
	# Not entering catch block means that Replace=false and global exists - so it throws an exception back to AviSynth
	try { Assert( !Replace && defined(Eval(globalName)) ) }
	catch (e)
	{
		Eval( "global " + globalName + " = Value" )
		Replace = true
	}
	Assert( Replace, """Multiple calls to QTGMC, set PrevGlobals="Replace" or read documentation on 'Multiple QTGMC Calls'""" )
}

# Return value of global variable called "Prefix_Name". Returns NOP() if it doesn't exist or Reuse is false
function DT_GetUserGlobal( string Prefix, string Name, bool "Reuse" )
{
	Reuse = default( Reuse, false )
	globalName = Prefix + "_" + Name

	try       { ret = Reuse ? Eval( globalName ) : NOP() }
	catch (e) { ret = NOP() }
	return ret
}
