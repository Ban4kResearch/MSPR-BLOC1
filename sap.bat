echo off
rem ************************************************************************************************************
rem *                                                                                                          *
rem *  Responsable           : Philippe                                                                        *
rem *  Date de derniere MAJ  : 14/10/2022                                                                      *
rem *                                                                                                          *
rem *  Objet                 : Transfert fichier SAP (RISE) vers CashOnTime                                    *
rem *                                                                                                          *
rem *  Reference             : \\FR-DTC-SCRI-P01\SCHEDULE\FR-DTC-SCRI-P01                                      *
rem *  Installation lancer   : PROD_805_SFTP_GEC_COT_Vers_SAP    sans parametres                               *
rem *                                                                                                          *
rem * Paramettres            : Sans = Installation sur les différents serveurs                                 *
rem *                          Mettre au moins 1 paramètre pour différencier de l'installation                 *
rem *                          P1   = ADPZ                                                                     *
rem *                                                                                                          *
rem * Procedures appelees    : WINSCP sur c:\planning  SAVEVT sur C:\Planning                                  *
rem * Installe sur           : FR-DTC-SCRI-P01                                                                 *
rem *                                                                                                          *
rem ************************************************************************************************************
rem *                                                                                                          *
rem * La procedure va tranférer les fichiers de SAP vers CashOnTime                                            *
rem *                                                                                                          *
rem ************************************************************************************************************
rem * Cause nouvelle version :                                                                                 *
rem * 2022-10-14.01  Reprise procédure TRANS_CashOntile_SAP pour nouvel environnement SAP                      *
rem * 2022-10-17.01  Rajout dans le fichier FTP d'une ligne CD pour avoir des doit de lancer et ecrite les LOG *
rem * 2023-05-30.01  Configuration avec connexion sur Rise                                                     *
rem *                                                                                                          *
rem * Pour tester procédure : copie fichier                                                                    *
rem *                         de   E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\SAV                               *
rem *                         vers E:\SCRIPTS\Metier\CashOnTime\PROD_COT_SAP                                   *
rem *                         Aller jusqu'a la phase 06 et tester le fichier FTP manuellement                  *
rem *                                                                                                          *
rem ************************************************************************************************************                                  

rem set debug=oui

if NOT "%debug%" == "" echo on
if     "%debug%" == "" echo off

set version=2023-11-23.01

IF "%1%" == "" GOTO COPIE

cls

C:
cd \
cd planning

:DEBUT-TRAITEMENT

Echo Phase 01 : Création corp du Mail

echo [DST]                                                                                                                                            > E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo w_systeme@panzani.fr                                                                                                                            >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo [SUJ]                                                                                                                                           >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo %COMPUTERNAME% PROD_805_SFTP_GEC_COT_Vers_SAP.bat Synchronisation des répertoires CashOnTime VERS SAP                                           >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo [MSG]                                                                                                                                           >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo - La tache PROD_805_SFTP_GEC_COT_Vers_SAP (version %VERSION%) a ete lancee                                                                      >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo - Lancement a %DATED% sur %COMPUTERNAME%                                                                                                        >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo - Taitement fichiers: %libelle%                                                                                                                 >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo - Traitement Fichier %SAP_FIC_COTP%                                                                                                             >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo - Repertoire de base E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\                                                                             >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo -                                                                                                                                               >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt

set erreur=non
set libelle=Pas d'anomalies detectees

for /F "tokens=1-4 delims=/ " %%i in ('date /t') do (
set fic_WD=%%i
set fic_MM=%%j
set fic_JJ=%%k
set fic_AA=%%l
)

for /F "tokens=1-4 delims=: " %%i in ('time /t') do (
set fic_HH=%%i
set fic_MN=%%j
set fic_PM=%%k
) 

set DATED=%fic_JJ%/%fic_mm%/%fic_aa% %fic_hh%:%fic_mn%

rem ************************************************************************************************************
rem *                                                                                                          *
rem * Initialisation des variales                                                                              *
rem * - SAP_   Traitement Windows ==> SAP                                                                      *
rem * - GEC_   Traitement DIMO ==> Windows                                                                     *
rem *                                                                                                          *
rem ************************************************************************************************************

Echo Phase 01 : initialisation des variables

if NOT "%debug%" == "" set fic
if NOT "%debug%" == "" pause ""

rem * Traitement des variables

set SAP_DIR_DEST=S:\Interfaces\COT\in\
set SAP_DIR_SOUR=E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\IN\
set SAP_DIR_SAUV=E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\SAV\

set SAP_FIC_SOUR=COT_Postings_*.txt

set SAP_PARTAGES=\\10.215.0.6\riserfpinterfpzn
set SAP_USERNAME=localhost\sapstorageaccountpanzani
set SAP_PASSWORD=

set GEC_DIR_SOUR=/OUT/
set GEC_DIR_DEST=%SAP_DIR_SOUR%
set GEC_FIC_COTP=%SAP_FIC_SOUR%

set GEC_SRV_DIST=Transfert.mygec-software.com
set GEC_USR_CONN=panzani_gec.sftp
set GEC_USR_PASS=Tgd5TrYZ9yy
set GEC_SAP_HKEY=ssh-rsa 3072 28:77:1d:28:07:2b:5c:cd:26:e6:10:b1:ce:35:b0:81

if NOT "%debug%" == "" pause ""
Echo Phase 02 : Transfert fichiers de FTP GEC vers Windows

echo option echo on>                                                                                                                                     E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp
echo option confirm off>>                                                                                                                                E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp
echo open sftp://%GEC_USR_CONN%:%GEC_USR_PASS%@%GEC_SRV_DIST% -hostkey="%GEC_SAP_HKEY%">>                                                                E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp
echo ls   %GEC_DIR_SOUR%>>                                                                                                                               E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp
echo get -nopreservetime -delete %GEC_DIR_SOUR%%GEC_FIC_COTP% %GEC_DIR_DEST%>>                                                                           E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp
echo exit>>                                                                                                                                              E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp

if NOT "%debug%" == "" pause ""

if     "%debug%" == "" c:\planning\Winscp.com /script=E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\FTP\GEC_GECSAP.ftp /loglevel=0  >                    E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\LOG\GEC_GECSAP.log
c:\planning\wait 20

find /c "Active session"  E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\LOG\GEC_GECSAP.log
if  %ERRORLEVEL%==1        set erreur=oui

if NOT "%debug%" == "" pause ""

SET /a nb_files=0

FOR %%i IN (%GEC_DIR_DEST%%GEC_FIC_COTP%) DO ( SET /a nb_files+=1 ) 

set libelle_Journal=NB fichiers COT : %nb_files%

if     %nb_files%==0 set libelle=Pas de fichiers traites
if     %nb_files%==0 echo Pas de fichiers à traiter
if     %nb_files%==0 goto NO_SAP

set libelle=Nombre de fichiers traites : %nb_files%

copy /y %GEC_DIR_DEST%%GEC_FIC_COTP% %SAP_DIR_SAUV%

if NOT "%debug%" == "" pause ""



echo Phase 03 : Transfert des fichiers vers SAP
echo - Montage lecteur de fichier sur SAP riserfpinterfpzn                                                                                           >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt

net use s: /delete
net use S: %SAP_PARTAGES%  /User:%SAP_USERNAME% %SAP_PASSWORD%                                                                                       >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt

if NOT %ERRORLEVEL%==0        set erreur=oui
if NOT %ERRORLEVEL%==0        echo - Erreur montage lecteur                                                                                          >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
if NOT %ERRORLEVEL%==0        goto :NO_SAP

echo - Montage lecteur OK                                                                                                                            >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo -                                                                                                                                               >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt

SET /a nb_files=0

FOR %%i IN (%SAP_DIR_SOUR%%SAP_FIC_SOUR%) DO (
	SET /a nb_files+=1
	echo - Fichiers traite : %%i                                                                                                                     >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
	copy %%i %SAP_DIR_DEST%                                                                                                                          >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
	if NOT exist %SAP_DIR_DEST%%%~ni%%~xi   set erreur=oui
 	if NOT exist %SAP_DIR_DEST%%%~ni%%~xi   echo - Fichier %SAP_DIR_DEST%%%~ni%%~xi non trouve                                                       >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
 	if     exist %SAP_DIR_DEST%%%~ni%%~xi   echo - Fichier %SAP_DIR_DEST%%%~ni%%~xi bien copie                                                       >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
	if     exist %SAP_DIR_DEST%%%~ni%%~xi 	del  %%i                                                                                                 >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
	) 
echo -                                                                                                                                               >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo - Nombre de traite : %nb_files%                                                                                                                 >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt

cd SAPEVT_PROD
sapevt_rfc -dest RFP -eventid ZP_FICO_COT_POSTINGS

cd ..

wait 20
net use s: /delete

:NO_SAP

if NOT "%debug%" == "" pause ""
Echo Phase 100 : Controle de la procedure

rem ********************************************************************
rem *                   FIN DE TRAITEMENT                              *
rem ********************************************************************

echo -                                                                                                                                               >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
if NOT %erreur%==oui echo - Tache terminee avec succes                                                                                               >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
if     %erreur%==oui echo - Tache terminee en erreur                                                                                                 >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo -                                                                                                                                               >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo [ATT]                                                                                                                                           >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt
echo GEC_GECSAP.log                                                                                                                                  >> E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt

copy E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\LOG\GEC_GECSAP.log   \\fr-dtc-scri-p01\transmis

set fichier_lotus=PROD_805_SFTP_GEC_COT_Vers_SAP_%COMPUTERNAME%.fla

for /F "tokens=1-4 delims=/ " %%i in ('date /t') do (
set fic_WD=%%i
set fic_MM=%%j
set fic_JJ=%%k
set fic_AA=%%l
)

for /F "tokens=1-4 delims=: " %%i in ('time /t') do (
set fic_HH=%%i
set fic_MN=%%j
set fic_PM=%%k
) 

set DATEF=%fic_JJ%/%fic_mm%/%fic_aa% %fic_hh%:%fic_mn%

if NOT %erreur%==oui set journal=%COMPUTERNAME%;PROD_805_SFTP_GEC_COT_Vers_SAP;%version%;%DATED%;%DATEF%;OK %libelle_Journal%
if     %erreur%==oui set journal=%COMPUTERNAME%;PROD_805_SFTP_GEC_COT_Vers_SAP;%version%;%DATED%;%DATEF%;ERREUR %libelle_Journal%

if     %erreur%==oui Copy E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt \\FR-DTC-SCRI-P01\TRANSMIS\%fichier_lotus%
if NOT %nb_files%==0 Copy E:\SCRIPTS\Metier\CashOnTime\PROD_805_COT_SAP\MAIL\PROD_805_SFTP_GEC_COT_Vers_SAP_Lotus.txt \\FR-DTC-SCRI-P01\TRANSMIS\%fichier_lotus%

Echo %journal% >> \\FR-DTC-SCRI-P01\audit\PWS_INTERFACE.TXT

C:
cd \
cd planning

GOTO FIN

:COPIE

REM ****************************************************************************************************
REM *                                                                                                  *
REM *   Procédure du mise en place du batch de PROD_805_SFTP_GEC_COT_Vers_SAP                          *
REM *                                                                                                  *
REM ****************************************************************************************************

if NOT "%debug%" == "" echo on
if     "%debug%" == "" echo off

cls
Echo **********************************************************************
Echo * Installation nouvelle version de PROD_805_SFTP_GEC_COT_Vers_SAP    *
Echo **********************************************************************
Echo *

C:\PLANNING\CHOICE /C:ONF "* Mise a jour PROD_805_SFTP_GEC_COT_Vers_SAP Version %version% "

IF errorlevel = 3  goto FIN
IF errorlevel = 2  goto NO_COPIE

Echo .
Echo . Mise en place : FR-DTC-SCRI-P01
Echo .
copy "\\FR-DTC-SCRI-P01\SCHEDULE\FR-DTC-SCRI-P01\PROD_805_SFTP_GEC_COT_Vers_SAP.bat" \\FR-DTC-SCRI-P01\planning\

pause

:NO_COPIE
:FIN
