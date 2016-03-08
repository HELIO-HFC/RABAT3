FUNCTION read_rawdam, filename, polar=polar,$
				       header=header,$
				       gal=gal,ciel=ciel,sys=sys, $
				       reponse=reponse, filter=filter,$
				       found=found,$
				       input_dir=input_dir,$
				       SILENT=SILENT

;+
; NAME:
;		read_rawdam	
;
; PURPOSE:
;		Reads the Nancay Decametric Array (NDA) raw data file (.RT1).  		
;
; CATEGORY:
;		I/O
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>Data = read_rawdata(filename)
;
; INPUTS:
;		filename - Scalar of string type that contains the name of the DAM raw data file (.RT1).
;	
; OPTIONAL INPUTS:
;		polar 	  - Specify the polarisation:
;						'r' 		--> right
;						'l' 		--> left
;						'p' 		--> r - l
;						'i' 		--> r + l (default)
;						'r-l/r+l'	--> r-l/r+l
;		input_dir - Scalar of string type that contains the directory of the input file.
;
; KEYWORD PARAMETERS:
;		/SILENT - Quiet mode.
;
; OUTPUTS:
;		data - IDL structure containing the dam data. 		
;
; OPTIONAL OUTPUTS:
;		header 		- IDL structure containing file header (receiver configuration).
;		gal	   		- Vector containing the galaxy background lvl (in dB above 1K).
;		ciel   		- Vector containing the ciel background lvl (in dB above 1K).
;		sys    		- Vector containing the system background lvl (in dB above 1K).
;		reponse    	- Array containing the HF filter reponse lvl (in dB above 1K).
;		filter		- Status of filter.
;		found  		- Equal to 1 if data are found, 0 else.		
;
; COMMON BLOCKS:		
;		None.			
;
; SIDE EFFECTS:
;		None.		
;
; RESTRICTIONS/COMMENTS:
;		Compile roulib.pro before run the routine.
;		
; CALL:
;		Routine_RawData
;		Routine_Filters
;		Routine_CalData
;		Routine_RefData
;
; EXAMPLE:
;			;Get DAM data from the 14th of March, 2001 :
;			data = read_rawdata('S20010314.RT1')	
;
; MODIFICATION HISTORY:
;		Written by X.Bonnin,	26-JUL-2010. (Adapted from stick_rawdata.pro)
;											
;-

;[1]:Initialize input parameters
;[1]:===========================
found = 0
if (~keyword_set(filename)) then begin
	message,/INFO,'Call is:'
	print,'Data = read_rawdam(filename,polar=polar,$'
	print,'                   header=header,gal=gal,$'
	print,'                   ciel=ciel,sys=sys,$'
	print,'                   reponse=reponse,filter=filter,found=found,$'
	print,'                   input_dir=input_dir,/SILENT)'
	return,0
endif 

file = strtrim(filename[0],2)
if (keyword_set(input_dir)) then file = input_dir + path_sep() + file_basename(file)
if (~file_test(file)) then begin
	message,/INFO,'No input file found!'
	return,0
endif

if (~keyword_set(polar)) then pol = 'i' else pol = strtrim(strlowcase(polar[0]),2)
;[1]:===========================



;[2]:Read DAM data file
;[2]:==================

; Read raw data
fNom = Routine_RawData (file, entete, jd, x, etat)
; Extract number of filter
nfil = Routine_Filters (entete, jd, x)
; Extract calibration data
cal = Routine_CalData (entete, jd, x, etat, nfil)
; Compute reference levels
Routine_RefData, entete, cal, freq, ciel, gal, sys, reponse, filter

;Get raw spectra
damdata = x

; Dans le cas ou le nombre d'elements du temps est impair
; on enleve le dernier balayage
n_jd = n_elements(jd)
if (n_jd mod 2) ne 0 then begin
    jd = jd[0:n_jd-2]
    damdata = damdata[*,0:n_jd-2]
endif


damjd = reform(jd,2,fix(n_elements(jd)/2))
damjd_final = (damjd[0,*] + damjd[1,*]) /2
damjd_final = reform(damjd_final)
damdata = float(reform(damdata,n_elements(freq),2,fix(n_elements(jd)/2)))
damdata2 = damdata

; convert in decibels
damdata = damdata*(entete.dBmax - entete.dBmin)/255. + entete.dBmin

; Define polara
spec_r = reform(damdata[*,0,*])
spec_l = reform(damdata[*,1,*])
spec_i = 10.*alog10(10.^(0.1*spec_r) + 10.^(0.1*spec_l))
spec_p = 10.^(0.1*spec_r) - 10.^(0.1*spec_l)

case pol of
    'i': spec = spec_i
    'p': begin
        ; les valeurs de 1 a ++, on les met en log
        spec_p[where(spec_p gt 1.)] = 10.*alog10(spec_p[where(spec_p gt 1.)])
        ; les valeurs de -- a -1, on les met en positif puis
        ;  on les met en log puis on les repasse en negatif
        spec_p[where(spec_p lt -1.)] = (10.*alog10(spec_p[where(spec_p lt -1.)]*(-1.)))*(-1.)
        ; on ne change pas les valeurs entre -1 et 1.
        ;spec = spec_p < 90. > (-90.)
        spec = spec_p
    end
    'r': spec = spec_r
    'l': spec = spec_l
    'r-l/r+l': spec = spec_p / (10.^(0.1*spec_r) + 10.^(0.1*spec_l))
endcase

spec = reform(spec)
spec = transpose(spec)

; Modif du 28/07/2009
; Bug du 21/07/2009
; ETAT = Array[46157] alors qu'il devrait etre
; de 46156
if n_elements(etat) ne n_elements(jd) then $
  etat = etat[0:n_elements(jd)-1]

; Suppression des barres d'etalonnages
etat = reform(etat,2,(n_elements(etat)/2))
etat1 = etat[0,*]
etat2 = etat[1,*]
etat1 = reform(etat1)
etat2 = reform(etat2)
ind_suppr = where((etat1 eq '11'x)or(etat2 eq '11'x))
; Suppression des barres d'etalonnages
; une barre d'etalonnage dure 10 secondes
; Modif du 31/08/2009
; Bug sur le jour du 03/01/2003
; Bug quand ind_suppr=-1 (cad qu'il n'y a pas de barres)
; Ajout du IF
; Bug sur le jour du 17/11/2009
;   La derniere barre d'etalonnage se finit apres la fin du spectre
;   (il y avait un depassement de tableau)
if ind_suppr[0] ne -1 then begin
    for i=0,n_elements(ind_suppr)-1 do begin
        if ind_suppr[i]+10 gt n_elements(damjd_final)-1 then $
          ind_fin = n_elements(damjd_final)-1 else $
          ind_fin = ind_suppr[i]+10
        spec[ind_suppr[i]:ind_fin,*] = !values.f_nan ; min(spec)
    endfor
endif

; temps en jour julian converti en sec dans la journee 
caldat,damjd_final,mm,dd,yy,hh,mn,ss
temps = hh*3600l+mn*60l+ss*1l
; temps en sec dans la journee converti en anytim (temps en sec depuis
; le 01/01/79
tab_anytim = temps + anytim([0L,0L,0L,0L,dd[0],mm[0],yy[0]]) ; [hh,mm,ss,msec,dd,mm,(yy)yy]
; print,anytim(time[0],/yymmdd)  ; 07/06/03, 00:00:00.000

;Integration time (cf. Alain Lecacheux -> 401 pts in 0.5 sec)
Tint = (500./401.)*1.e-3 ;sec

;Bandwith (30 kHz)
Bandwidth = entete.MHZRES ;MHz

jd0 = min(temps,j0,/NAN) 
jd1 = max(temps,j1,/NAN)
date_obs = string(yy[j0],format='(i4.4)') + '-' + string(mm[j0],format='(i2.2)') + '-' + string(dd[j0],format='(i2.2)') + $
           'T' + string(hh[j0],format='(i2.2)') + ':' + string(mn[j0],format='(i2.2)') + string(ss[j0],format='(i2.2)')
date_end = string(yy[j1],format='(i4.4)') + '-' + string(mm[j1],format='(i2.2)') + '-' + string(dd[j1],format='(i2.2)') + $
           'T' + string(hh[j1],format='(i2.2)') + ':' + string(mn[j1],format='(i2.2)') + string(ss[j1],format='(i2.2)')

dt = median(deriv(temps)) ;sec
df = median(deriv(freq))  ;MHz
freq_min = min(freq,/NAN,max=freq_max)

header = {observatory:'Nancay',instrument:'Decametric Array',receiver:'ASB',$
		  time_units:'seconds',freq_units:'MHz',$
		  flux_units:'dB',$
		  date_obs:date_obs,date_end:date_end,$
          tau:Tint,bandwidth:bandwidth,$
		  dt:dt,df:df,nt:n_elements(temps),$
		  nf:n_elements(freq),freq_min:freq_min,freq_max:freq_max,$
		  filename:file_basename(filename),url:'',comment:''}

data = {flux:spec,frequency:freq,jd:damjd_final,time:temps,anytim:tab_anytim}

found = 1
return,data
end
