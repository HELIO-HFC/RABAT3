function stick_rawdam, fich, iprl=iprl,$
				       header=entete,$
				       gal=gal,ciel=ciel,$
				       rep=reponse

; iprl = 'i' , 'p' , 'r' , 'l', 'r-l/r+l'
; Renvoie seulement r (par la suite i et a la demande r)

if n_elements(iprl) eq 0 then iprl = 'i'

; *** Lecture des donnees brutes
fNom = Routine_RawData (fich, entete, jd, x, etat)
nfil = Routine_Filters (entete, jd, x)
cal = Routine_CalData (entete, jd, x, etat, nfil)
Routine_RefData, entete, cal, freq, ciel, gal, reponse, repOk

data = x

; Dans le cas ou le nombre d'elements du temps est impair
; on enleve le dernier balayage
n_jd = n_elements(jd)
if (n_jd mod 2) ne 0 then begin
    jd = jd[0:n_jd-2]
    data = data[*,0:n_jd-2]
endif


damjd = reform(jd,2,fix(n_elements(jd)/2))
damjd_final = (damjd[0,*] + damjd[1,*]) /2
damjd_final = reform(damjd_final)
damdata = float(reform(data,n_elements(freq),2,fix(n_elements(jd)/2)))
damdata2 = damdata

; convertit en decibels
damdata = damdata*(entete.dBmax - entete.dBmin)/255. + entete.dBmin

; reponse, convertit en valeur d'intensite solaire
for i=0,(n_elements(jd)/2)-1 do begin
    damdata[*,*,i] = damdata[*,*,i] - reponse[*,*,0]
endfor

; on prend par defaut la somme des polar r et l
spec_r = damdata[*,0,*]
spec_l = damdata[*,1,*]
spec_i = 10.*alog10(10.^(0.1*spec_r) + 10.^(0.1*spec_l))
; spec_p = 10.*alog10(10.^(0.1*spec_r) - 10.^(0.1*spec_l))  ; faux
spec_p = 10.^(0.1*spec_r) - 10.^(0.1*spec_l)

case iprl of
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


dam = {image:spec,freq:freq,jd:damjd_final,temps:temps,anytim:tab_anytim}

return,dam

end
