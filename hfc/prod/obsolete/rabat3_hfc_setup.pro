PRO rabat3_hfc_setup

;Define some Local system variables
;==================================
;Temporary Inf/NaN value 
defsysv,'!MIN_INF_VALUE',1.e-30

;speed of light
defsysv,'!CLIGHT',299792458.0d ;m/s

;Bolztmann contstant
defsysv,'!KBOLTZ',1.3806504e-23

;Quantile to define to compute the background level
defsysv,'!QUANTILE',0.1


END
