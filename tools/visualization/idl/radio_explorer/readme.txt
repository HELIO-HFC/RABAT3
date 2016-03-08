 
 Radio Explorer Software 1.03 (radex)
 -----------------------------------------------

 The Radio Explorer is an IDL sofware that 
 allows to display radio dynamical spectra for the following observatories:

     Wind/Waves 60sec averaged data (GSFC)
     STEREO/Waves 60sec averaged data (GSFC)
     Ulysses/URAP 192sec averaged data (GSFC)


 This directory contains the files to run the radex software.
 The following list gives a short description of each sub-directory :

    /archives 	    contains any archive file.
    /data          directory that can be used to saved data files.
    /lib           contains program libraries used to run radex.
    /logs          can be used to saved log file (obsolote).
    /products      can be used to saved radex products.
    /scripts       contains scripts to launch radex.
    /setup         contains radex setup files.
    /src           contains radex IDL source files.

 Before running radex, be sure that the environment variables required 
 are well defined and loaded. (You can edit and load the setup/radex_setup.sh to do so.)
 To launch the software, call the radex_launcher.sh script in the /scripts directory.

 Example : 
 	 To display wind/waves data for the 1 january 2001 :
	    >source setup/radex_setup.sh
	    >sh scripts/radex_launcher.sh 20010101 wind
 
 X.Bonnin, 10-FEB-2013
