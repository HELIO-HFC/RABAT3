;+
; NAME:
;		type3_driftrate_func
;
; PURPOSE:
; 		Compute the integral of the type III solar radio
;		burst drift rate df/dt = A[0]*(F)^(A[1]), giving frequencies F
;		and parameters A as input arguments (A[2] will be is integration constant).		
;
; CATEGORY:
;		Mathematics
;
; GROUP:
;		None.
;
; CALLING SEQUENCE:
;		IDL>Time = type3_driftrate_func(frequency,A)
;
; INPUTS:
;		frequency - Vector of n elements containing the frequency values (in MHz).
;					Frequencies must ordered by increasing values.
;		A		  - Vector of 3 elements containing the function's parameters.
;	
; OPTIONAL INPUTS:
;		None.
;
; KEYWORD PARAMETERS:
;		None.
;
; OUTPUTS:
;		Time - Vector of n elements containing the time computed (in second).
;			   Time function t(f) is defined by:
;					
;						t = (f^(1. - A[1]))/((1. - A[1])*A[0]) 
;							- (max(f)^(1. - A[1]))/((1. - A[1])*A[0]) 
;							+ A[2],
;						
;				where t is in second and f in MHz.
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
;		Compute type III time versus frequency profile between 0.1 and 1 MHz,
;		using Alvarez et al. 1973 drift rate parameters:
;				
;		A = [-0.01,1.84,0]
;		freq = 0.1*findgen(10) + 0.1
;		t = type3_driftrate_func(freq,A)	
;		plot_io,t,f	
;
; MODIFICATION HISTORY:
;		Written by X.Bonnin,	26-JUL-2006.			
;														
;-

FUNCTION type3_driftrate_func,frequency,A

if (n_params() lt 2) then begin
	message,/INFO,'Call is: '
	print,'Results = type3_driftrate_func(frequency,A)'
	return,0
endif

a1 = 1. - A[1]
time = (frequency^(a1))/(a1*A[0]) - (max(frequency,/NAN)^(a1))/(a1*A[0])
time = time + A[2]

return,time
END