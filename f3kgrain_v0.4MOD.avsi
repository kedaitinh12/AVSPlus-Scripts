###################################################
###                                             ###
###                  f3kgrain                   ###
###                                             ###
###       by 06_taro - astrataro@gmail.com      ###
###                                             ###
###              v0.4 - 21 May 2012             ###
###                                             ###
###     mod by kedautinh12 - 10 February 2022   ###
###                                             ###
###################################################
###
### Fast luma-adaptive grain generator
###
### Temporal soften strength of grain is changeable ( it can only be set on/off in F3KDB_3 )
###
###
### +---------+
### |  USAGE  |
### +---------+
###
### f3kgrain()
###
### See below for explanation of parameters
###
### +----------------+
### |  REQUIREMENTS  |
### +----------------+
###	
###    Plugins:
### -> SysInfo
### -> RT_Stats
### -> flash3kyuu_deband
### -> neo-f3kdb      
### -> MaskTools2        [v2.0a48]
### -> RgTools
### -> dither            [v1.17.0]
###
###    Scipts:
### -> F3KDB_s           [v1.3+] (https://raw.githubusercontent.com/realfinder/AVS-Stuff/Community/avs%202.5%20and%20up/F3KDB_s.avsi)
### -> Zs_RF_Shared      [1.154+] https://raw.githubusercontent.com/realfinder/AVS-Stuff/Community/avs%202.5%20and%20up/Zs_RF_Shared.avsi)
### -> mt_xxpand_multi
### -> dither
### -> ExTools           [3.0+] (https://raw.githubusercontent.com/Dogway/Avisynth-Scripts/master/ExTools.avsi)
###
### +-----------+
### | CHANGELOG |
### +-----------+
###
### mod  - 10 February 2022
###      - Add support adapt variable scaled to HBD (thank Dogway)
###
### mod  - 05 July 2021
###      - Replace MaskTools2 with ExTools
###      - Replace f3db with F3KDB_3
###
### v0.4 - 21 May 2012
###      - Add support for 8-bit YV16/YV24
###      - Add support for setting sigma(standard deviation) of Gaussian distribution
###
### v0.3 - 06 April 2012
###      - Add support for 16-bit input and output, need dither.dll v1.15.0 or newer
###
### v0.2 - 14 March 2012
###      - Synchronize argument names with parameter names of f3kdb v1.5.0
###
### v0.1 - 02 March 2012
###      - First release
###

Function f3kgrain(clip input, int "luma", int "chroma", int "mode", int "temp", int "adapt", float "sigma", bool "lsb"){

  luma   = Default(luma,   64)   # Luma grain strength
  chroma = Default(chroma, 64)   # Chroma grain strength
  mode   = Default(mode,    1)   # random_algo_grain mode, 0 - old algorithm, 1 - uniform distribution, 2 - Gaussian(normal) distribution
  temp   = Default(temp,   50)   # Temporal stabilization for grain (the higher, the more calm) [0=nervous,...,100=static]
  adapt  = Default(adapt,  64)   # Brightness threshold for adaptative grain mask [-1=off, 0=input, 1...254, 255=invert]
                                 # The higher, the less grain in dark areas & the more grain in bright areas
  sigma  = Default(sigma, 1.0)   # Standard deviation of Gaussian distribution mode
  lsb    = Default(lsb, float(input.width)/input.height > 1.2 ? false : true)
                                 # Input and output clips are stacked 16-bit or normal 8-bit

  Assert( temp>=0 && temp<=100,    "f3kgrain: invalid value for temp(0~100)!"   )
  Assert( adapt>=-1 && adapt<=255, "f3kgrain: invalid value for adapt(-1~255)!" )

  Y = luma  ==0 ? 2 : 3
  U = chroma==0 ? 2 : 3
  V = chroma==0 ? 2 : 3
  bi = BitsPerComponent(input)
  adaptHBD = ex_bs(adapt, 8, bi, true)
  
  Lclip = lsb ? input.f3kg_get_msb : input

  Lmask = adapt==0   ? Lclip.RemoveGrain(19, -1)
  \     : adapt==255 ? Lclip.ex_invert(UV=1).RemoveGrain(19, -1)
  \     :              Lclip.ex_lut(Format("x {adaptHBD} - abs range_max * {adaptHBD} range_half - abs range_half + /"), UV=1, fulls=true).RemoveGrain(19, -1)

  grain = Lclip.BlankClip(color_yuv=$808080).F3KDB_3(Y=0, Cb=0, Cr=0, grainY=luma, grainC=chroma, dynamic_grain=true, random_algo_grain=mode, random_param_grain=sigma)

  gsoft = (luma!=0 && chroma!=0) ? grain.TemporalSoften(1, 255, 255, scenechange=255, mode=2)
  \     :  luma!=0               ? grain.TemporalSoften(1, 255,   0, scenechange=255, mode=2)
  \     :  chroma!=0             ? grain.TemporalSoften(1,   0, 255, scenechange=255, mode=2)
  \     :                          grain


  gmerge = (temp ==   0) ? grain
  \      : (temp == 100) ? gsoft
  \      : (luma!=0 && chroma!=0) ? Merge(grain, gsoft, temp/100.)
  \      :  luma!=0               ? MergeLuma(grain, gsoft, temp/100.)
  \      :  chroma!=0             ? MergeChroma(grain, gsoft, temp/100.)
  \      :                          grain

  adsoft = lsb ? Dither_add16(input, gmerge.f3kg_convert_8_to_16, dif=true, Y=Y, U=U, V=V) : ex_adddiff(input, gmerge, Y=Y, UV=U)

  b_luma = chroma!=0 && ( Lmask.Is420 || lsb ) ? True : False
  Lmask  = !b_luma && chroma!=0 ? Lmask.MergeChroma( Lmask.YToUV(Lmask).BilinearResize(Lmask.width, Lmask.height) )
  \	                            : Lmask

  return adapt==-1 ? adsoft
  \                : lsb ? f3kg_merge16_8(adsoft, input, Lmask, luma=b_luma, Y=Y, U=U, V=V)
  \                      : ex_merge(adsoft, input, Lmask, luma=b_luma, Y=Y, UV=U)
}

# ==============================================

Function f3kg_get_msb(clip src){  return src.Crop(0, 0, src.Width, src.Height/2) }
Function f3kg_get_lsb(clip src){  return src.Crop(0, src.Height/2, src.Width, src.Height/2) }
Function f3kg_convert_8_to_16(clip src){ return StackVertical(src, BlankClip(src, color_yuv=0)) }

Function f3kg_merge16_8(clip src1, clip src2, clip mask, bool "luma", int "y", int "u", int "v"){

	luma = Default(luma, false)

	y = Default(y, 3)
	u = Default(u, 2)
	v = Default(v, 2)

	mask16 = StackVertical(mask, mask)
	Dither_merge16(src1, src2, mask16, luma=luma, y=y, u=u, v=v)
}
