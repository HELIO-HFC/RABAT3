;+
; NAME:
;		Routine_RefData	
;
; PURPOSE:
;		Computes reference levels (galactic, sky, HF filter, and system backgrounds)  		
;
; CATEGORY:
;		Calibration
;
; GROUP:
;		ROULIB
;
; CALLING SEQUENCE:
;		IDL>Routine_RefData,entete,cal,f,ciel,gal,reponse,Tsys,repOK
;
; INPUTS:
;		entete   - Structure containing the header of the raw data file (receiver configuration).
;		cal	     - Structure containing calibration parameters. 
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		None.
;
; OUTPUTS:
;		f	     - Vector containing the frequency channels (in MHz).
;		ciel     - Vector containing the sky background lvl (in dB above 1K).
;		gal    	 - Vector containing the galaxy background lvl (in dB above 1K).
;		reponse - Array containing the HF filter reponse lvl (in dB above 1K).
;		Tsys    - Vectore containing the system background lbl (in dB above 1K).
;		repOK   - Array containing the status of the filter. 		
;
; OPTIONAL OUTPUTS:
;		None.	
;
; COMMON BLOCKS:		
;		None.			
;
; SIDE EFFECTS:
;		None.		
;
; RESTRICTIONS/COMMENTS:
;		None.
;		
; CALL:
;		None.
;
; EXAMPLE:
;		None.	
;
; MODIFICATION HISTORY:
;		Written by A.Lecacheux.
;											
;-

;--------------------------------------------------------------------------------------------------
;calcul du niveau de bruit galactique
;--------------------------------------------------------------------------------------------------
Pro Routine_RefData, entete, cal, $
                     f, $              ;valeurs en MHz des 400 canaux de fréquence
                     ciel, $           ;spectre "ciel froid" en dB au-dessus de 1 K
                     gal, $            ;spectre "galaxie" en dB au-dessus de 1 K
                     Tsys, $			 ;spectre du système en dB au-dessus de 1K
                     reponse, $        ;spectre du filtre HF pour chaque polarisation (dB/1 K)
                     repOk             ;réponse disponible
;--------------------------------------------------------------------------------------------------
;échelle de fréquence correspondant aux 400 canaux
  f = entete.MHzMin + (entete.MHzMax - entete.MHzMin)*findgen(400)/399.
  ;flog = entete.MHzMin + (entete.MHzMax - entete.MHzMin)*findgen(400)/399.
;forme du filtre passe bande pour chaque polarisation (sur diode 41.2 dB enr)
    
  if Size (cal, /TYPE) eq 8 then begin
    c = savgol (64,64,0,6)               ;lissage par convolution avec un filtre de Savitsky-Golay
    reponse = fltarr(400,2,4)            ;fréquence, polarisation, filtre
    Tsys = reponse
  	repOk = bytarr(2,4)
    for i=0,3 do begin
      for ip=0,1 do begin
        w = where (cal.filtre[ip,3] eq (i+1), nw)
        if (nw gt 0) then begin
          r = reform (cal[w].dB[*,ip,3])
          if (nw gt 1) then r = Total (r, 2)/nw
          r = convol (r, c, /EDGE_TRUNCATE)
          reponse[*,ip,i] = r - (41.2 + 24.8)
          r0 = reform(cal[w].dB[*,ip,0])
          if (nw gt 1) then r0 = total(r0,2)/nw
          r0 = convol(r0,c,/EDGE_TRUNCATE)
          r = 10.^(0.1*(r-r0))
          Tsys[*,ip,i] = 41.2 + 24.8 + 10.*alog10((1. - 0.001*r)/(r-1.))
          repOk[ip,i] = 1
          endif
        endfor
      endfor
    endif else message,/INFO,'Warning: Pas d'+string(39b)+'etalonnage'
;spectre galactique en dB au-dessus de 1 K (cf. Allen, "Astrophysical Quantities")
  gal = 10*poly (alog10 (f), poly_fit (alog10 ([10, 20, 50, 100]), [5.9, 5.5, 4.8, 4.09], 1))
;spectre du ciel froid en dB au-dessus de 1K (cf. Cane, 1979)
  tau = 5.0/f^2.1
  ciel = (2.48e8/f^0.52)*(1 - exp (-tau))/tau + (1.06e8/f^0.80)*exp(-tau)
  ciel = 10*alog10 (ciel/3.0715) - 20*alog10 (f)
  end

;+
; NAME:
;		Routine_CalData	
;
; PURPOSE:
;		Search and extract the DAM calibrations.  		
;
; CATEGORY:
;		Calibration
;
; GROUP:
;		ROULIB
;
; CALLING SEQUENCE:
;		IDL>Cal = Routine_CalData(entete, jd, x, etat, nfil)
;
; INPUTS:
;		entete   - Structure containing the header of the raw data file (receiver configuration).
;		jd   	  - Time in Julian day
;		x		  - Raw radio spectra.
;		etat	  - Instrument status.
;		nfil 	  - Filter number.
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		SILENT - Quiet mode.
;
; OUTPUTS:
;		cal	     - Structure containing calibration parameters.  		
;
; OPTIONAL OUTPUTS:
;		None.	
;
; COMMON BLOCKS:		
;		None.			
;
; SIDE EFFECTS:
;		None.		
;
; RESTRICTIONS/COMMENTS:
;		None.
;		
; CALL:
;		None.
;
; EXAMPLE:
;		None.	
;
; MODIFICATION HISTORY:
;		Written by A.Lecacheux.
;											
;-

;--------------------------------------------------------------------------------------------------
;recherche et extraction des étalonnages
;--------------------------------------------------------------------------------------------------
Function Routine_CalData, entete, jd, x, etat, nfil
;--------------------------------------------------------------------------------------------------
  wc = where (etat eq '11'x, nw)       ;détection des débuts de palier d'étalonnage

  wcal = where (etat eq '00'x, ncal)    ;détection des fins d'étalonnage (retour sur ciel)
  if ((nw eq 0) or (ncal eq 0)) then begin
    ;print, 'séquences d''étalonnage non détectées -- on arrête'
    return, 0
    endif
;recherche des séquences complètes
  wc = [wc, wcal]
  wc = wc[sort (wc)]
  k = Round (interpol (findgen(ncal), wcal, wc))
  h = histogram (k, MIN=0, REV=r)
  wh = where (h eq 5, ncal)
  if (ncal eq 0) then begin
    ;print, 'séquences d''étalonnage non cohérentes -- on arrête'
    return, 0
    endif $
  else begin
    ;print, ncal, ' séquences d''étalonnage utilisables'
    ww = r[r[wh[0]]:r[wh[0]+1]-1] & for i=1,ncal-1 do ww = [ww, r[r[wh[i]]:r[wh[i]+1]-1]]
    w = wc[reform (ww, 5, ncal, /OVER)]
    polar = byte (lindgen(N_elements (etat)) mod 2)
    cal = replicate ({jd:0d0, dB:fltarr(400,2,4), filtre:bytarr(2,4)}, ncal)
    cal.jd = reform (jd[w[0,*]])
    for i=0,ncal-1 do begin             ;numéro de la séquence d'étalonnage
      for j=0,3 do begin                ;numéro du palier d'étalonnage
        n_j = w[j+1,i]-1-w[j,i]
        if (n_j le 0) then continue
        ww = w[j,i] + 1 + indgen(n_j)
        for k=0,1 do begin              ;polarisation
          wp = ww[where (polar[ww] eq k, np)]
          z = Total (x[*,wp], 2)/np
          cal[i].dB[*,k,j] = entete.dbMin + z*(entete.dbMax-entete.dbMin)/256.
          m = Mean (nfil[wp])
          m = m*(Total (abs (nfil[wp] - m)) eq 0)
          cal[i].filtre[k,j] = m        ;numéro du filtre
          endfor
        endfor
      endfor
    endelse
;  k = Value_Locate (wc, wcal)
;  k = k[where (k ge 4)]
;  k = reverse(-indgen(5))#replicate(1, N_elements (k)) + replicate(1, 5)#k
;exclusion de toutes les données d'étalonnage
  for i=0,n_elements (h)-1 do nfil[wc[r[r[i]]]:wc[r[r[i+1]-1]]] = 0
  return, cal
  end

;+
; NAME:
;		Routine_Filters	
;
; PURPOSE:
;		Filter change management.  		
;
; CATEGORY:
;		Calibration
;
; GROUP:
;		ROULIB
;
; CALLING SEQUENCE:
;		IDL>nfil = Routine_Filters( entete, jd, x)
;
; INPUTS:
;		entete   - Structure containing the header of the raw data file (receiver configuration).
;		jd   	  - Time in Julian day
;		x		  - Raw radio spectra.
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		SILENT - Quiet mode.
;
; OUTPUTS:
;		nfil - Vector containing the filter number.  		
;
; OPTIONAL OUTPUTS:
;		None.	
;
; COMMON BLOCKS:		
;		None.			
;
; SIDE EFFECTS:
;		None.		
;
; RESTRICTIONS/COMMENTS:
;		None.
;		
; CALL:
;		None.
;
; EXAMPLE:
;		None.	
;
; MODIFICATION HISTORY:
;		Written by A.Lecacheux.
;											
;-

;--------------------------------------------------------------------------------------------------
;gestion des changements de filtre
;--------------------------------------------------------------------------------------------------
Function Routine_Filters, entete, jd, x
;--------------------------------------------------------------------------------------------------
  nfil = replicate (1B, N_elements (jd))  ;filtre 1, par défaut
;recherche des dates de changement de filtre
  if (entete.filtre[0] gt 0) then begin
    n = N_elements (jd)
    k = Interpol (dindgen (n), jd, entete.jdf) > 0 < (n - 200)
    nfil = replicate (entete.filtre[0], n)  ;valeur initiale du filtre
    for i=(k[0] eq 0),N_elements (k)-1 do begin
      q = Total (x[0:99, k[i]:k[i]+199], 1)/100
      s = fltarr(200)
      for j=0,199 do begin
        w = where (indgen(200) lt j, nw, COMPLEMENT=wn, NCOMPLEMENT=nwn)
        if (nw ge 2) then s[j] = s[j] + Variance (q[w])
        if (nwn ge 2) then s[j] =  s[j] + Variance (q[wn])
        endfor
;calcul du sigma et des niveaux moyens avant et après
      smin = sqrt (min (s, is))
      if (is gt 0) then m1 = Mean (q[0:is-1]) else m1 = 0
      m2 = Mean (q[is:*])
;numéro du spectre de transition
      is = k[i] + is
      Caldat, jd[is], im, ij, ia, hh, mn, ss
     ; print, 'filtre ' + String (nfil[is], FORMAT='(i1)') + '->' + $
     ;   String (entete.filtre[i], FORMAT='(i1)') + $
     ;   ' changé: ' + String (ia, im, ij, hh, mn, ss, FORMAT='(i4,i2.2,i2.2,1x,i2.2,i2.2,i2.2)') + $
     ;   String ([smin, m1, m2]*(entete.dBmax - entete.dBmin)/256. + $
     ;   [0, 1, 1]*entete.dBmin, FORMAT='(3f8.2)')
      nfil[is:*] = entete.filtre[i]
      endfor
  endif
  return, nfil                           ;numéro du filtre (0= hors ciel ou erreur)
  end

;+
; NAME:
;		Routine_RawData	
;
; PURPOSE:
;		Read DAM raw data (.RT1).  		
;
; CATEGORY:
;		I/O
;
; GROUP:
;		ROULIB
;
; CALLING SEQUENCE:
;		IDL>fnom = routine_rawdata(fRoutine, $
;                        		   entete, $       
;                          		   jd, $           
;                         		   x, $            
;                         		   etat)
;
; INPUTS:
;		fRoutine - Scalar of string type containing the name of the DAM raw data file (.RT1). 
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		NODATA - Not return data.
;		SILENT - Quiet mode.
;
; OUTPUTS:
;		fRoutine - Scalar of string type containing the name of the DAM raw data file (.RT1). 		
;
; OPTIONAL OUTPUTS:
;		entete   - Structure containing the header of the raw data file (receiver configuration).
;		jd   	  - Time in Julian day
;		x		  - Raw radio spectra.
;		etat	  - Instrument status.	
;
; COMMON BLOCKS:		
;		None.			
;
; SIDE EFFECTS:
;		None.		
;
; RESTRICTIONS/COMMENTS:
;		None.
;		
; CALL:
;		None.
;
; EXAMPLE:
;		None.	
;
; MODIFICATION HISTORY:
;		Written by A.Lecacheux.
;											
;-

;--------------------------------------------------------------------------------------------------
;lecture des données brutes
;--------------------------------------------------------------------------------------------------
Function routine_rawdata, fRoutine, $
                          entete, $       ;configuration du récepteur
                          jd, $           ;dates des spectres
                          x, $            ;spectres de 400 points
                          etat, $         ;mot d'état (télescope) pour chaque spectre
                          NODATA=nodata   ;retour sans lecture des données
                          SILENT=SILENT	  ;mode silencieux 
;--------------------------------------------------------------------------------------------------
   SILENT = keyword_set(SILENT) 	
 
  ;if (~SILENT) then print,'Routine_rawdata'


;  fNom = (Reverse (StrSplit (fRoutine, '.\:', /EXTRACT)))[1]
  fNom = (Reverse (StrSplit (fRoutine, './:', /EXTRACT)))[1]
  ;;if (~SILENT) then print,'Nom du fichier: '+fNom
  ReadS, fNom, ia, im, ij, FORMAT='(1x,i2,i2,i2)'
  jd = JulDay (im, ij, ia + 1900*(ia gt 80) + 2000*(ia lt 50), 0, 0, 0)
  OpenR, lun, /GET_LUN, fRoutine
;analyse de l'entête
  b = bytarr(405) & ReadU, lun, b
  s = string (b[1:*]) & b = intarr(8)
  ofs = 2*(jd ge Julday (2,24,1994,0,0,0))
  ReadS, StrMid (s, 0, 19 + ofs), b, FORMAT='(i2,i2,i3,i3,i' + $
    String (3 + ofs, FORMAT='(i1)') + ',i2,i2,i2)'
  jdMer = jd + b[6]/24d0 + b[7]/1440d0
;changements de filtre commandés
  s = StrMid (s, 19 + ofs, 1000)
  nchg = Strlen (s)/6
  if (nchg gt 0) then begin
    nf = bytarr(nchg) & jdf = dblarr(nchg)
    Catch, err
    if (err ne 0) then begin
      nchg = 0
      nf = 0
      jdf = min (jd)
      goto, nochg
      endif
    for i=0,nchg-1 do begin
      ReadS, StrMid (s, 6*i, 6), n, hh, mn, FORMAT='(i1,i2,1x,i2)'
      nf[i] = n
      jdf[i] = jd  + hh/24d0 + mn/1440d0
      jdf[i] = jdf[i] - Round (jdf[i] - jdMer)
      endfor
    w = where (nf ne 0, nchg)
    if (nchg gt 0) then begin
      nf = nf[w]
      jdf = jdf[w]
      endif
    endif $
  else begin
    nf = 0
    jdf = min (jd)
    endelse
;mise en forme de l'entête
nochg:
  nchg = nchg > 1
  entete = {MHzMin:0, MHzMax:0, MHzRes:0.0, dBmin:0, secBal:0.0, dBmax:0, jdMer:0d0, $
    filtre:intarr(nchg), jdf:dblarr(nchg)}
  entete.MHzMin = b[0]                          ;fréquence minimum en MHz
  entete.MHzMax = b[1]                          ;fréquence maximum en MHz
  entete.MHzRes = 0.001*b[2]                    ;largeur du filtre de détection en MHz
  entete.dBmin = b[3] - 8*b[5]                  ;puissance minimale
  entete.secBal = 0.001*b[4]                    ;duréé d'un balayage en secondes
  entete.dBmax = b[3]                           ;puissance maximale
;if (~SILENT) then print,'puissance maximale ===== ', entete.dBmax
  entete.jdMer = jdMer                          ;date de passage au méridien
  entete.filtre = nf                            ;numéro du filtre
  entete.jdf = jdf                              ;heure commandée de changement de filtre
  
  if Keyword_Set (NODATA) then return, fNom
;extraction des données
  n = FStat (lun) & n = (n.Size/405) - 1
;if (~SILENT) then print, 'nombre de balayages: ', n
  x = bytarr(405,n)
  ReadU, lun, x
  Free_Lun, lun
  h = transpose ([3600., 60., 1., 0.01])
  sec = transpose (h#x[0:3,*])
  sec = sec + 86400*(sec lt sec[0])
  jd = jd + sec/86400d0
  jd = jd - Round (Mean (jd) - entete.jdMer)    ;date du début de chaque balayage
  Caldat, Min (jd), im, ij, ia, hh, mn, ss
 ;if (~SILENT) then print, 'début:    ' + String (ia, im, ij, hh, mn, ss, FORMAT='(i4,i2.2,i2.2,1x,i2.2,i2.2,i2.2)')
  Caldat, Max (jd), im, ij, ia, hh, mn, ss
 ;if (~SILENT) then print, 'fin:      ' + String (ia, im, ij, hh, mn, ss, FORMAT='(i4,i2.2,i2.2,1x,i2.2,i2.2,i2.2)')
  Caldat, entete.jdMer, im, ij, ia, hh, mn, ss
 ;if (~SILENT) then print, 'méridien: ' + String (ia, im, ij, hh, mn, FORMAT='(i4,i2.2,i2.2,1x,i2.2,i2.2)')
  for i=0,nchg-1 do begin
    Caldat, entete.jdf[i], im, ij, ia, hh, mn, ss
   ;if (~SILENT) then print, 'filtre: ' + String (entete.filtre[i], FORMAT='(i1)') + $
   ;   ' commandé ' + String (ia, im, ij, hh, mn, FORMAT='(i4,i2.2,i2.2,1x,i2.2,i2.2)')
    endfor
  etat = transpose (x[404,*])                   ;mot d'état pour chaque balayage
  x = x[4:403,*]                                ;spectre brut, échantillonné sur 400 fréquences

return, fNom
end
