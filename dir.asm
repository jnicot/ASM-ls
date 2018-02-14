;--------------------------------------------
;Prog Assembleur 
;Autheur Meke Nounga
;ENSIBS Cyber 1
;Version 1.0.3
;--------------------------------------------

.386
.model flat,stdcall
option casemap:none
;-------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-------------------------------------------------
;includes
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc
;include c:\masm32\include\windows.inc
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; 
;libs
includelib c:\masm32\lib\msvcrt.lib					
includelib c:\masm32\lib\kernel32.lib
;------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;------------------------------------------------
dirPrint proto directory:DWORD, tab:DWORD
;------------------------------------------------
; Définition des fonctions et types utilisés dans ce programme include 
;---Kernel32.lib---Fonction
; GetFileAttributesA				(Fonction qui retoure les attributs d'un fichier ou d'un réperoire)
; GetCommandLine					(Fonction qui retourne une chaine de caractère correspondant au argument de la fonction)
; FindFirstFile						(Fonction qui retourne un handle sur le premier fichier ou réperoire trouvé dans le répertoire)
; FindNextFile						(Fonction prend en paramètre un handle de fichier dans un répertoire et retourne le fichier suivant)
; GetLastError						(Fonction qui retourne la dernierre erreur rencontré par un fonction lorsqu'elle est appelé apres celle-ci)
; FindClose							(Fonction qui permet de libérer le handle sur un répertoire)
; ExitProcess
; FileTimeToSystemTime				(Fonction qui converti un filetime en systeme_time)
; SystemTimeToTzSpecificLocalTime	(Fonction qui permet de convertir un syteme_time en UTC en un fuseau horaire spécifique en se basant sur le localtime)
; GetCurrentDirectory				(Fonction qui permet de récupérer le répertoire courant)

;---msvcrt.lib---Fonctions
; crt_printf						(Fonction qui permet d'afficher sur la sortie standar)
; crt_strcat						(Fonction qui permet de concatener deux chaine de caractère)
; crt_strcmp						(Fonction qui permet de comparer deux chaine de caractère)
; crt_strcpy						(Fonction qui permet de copier une chaine de caractère dans une chaine null)
; crt_system						(Fonction qui permet d'exécuter un commande système passé sous forme de chaine de caractère comme argument)

;---windows.inc---Types
; MAX_PATH							equ 260
; FILETIME						STRUCT
	; dwLowDateTime     			DWORD     
	; dwHighDateTime    			DWORD
; SYSTEMTIME					STRUCT
	; wYear             			WORD      
	; wMonth            			WORD      
	; wDayOfWeek        			WORD      
	; wDay              			WORD      
	; wHour             			WORD      
	; wMinute           			WORD      
; WIN32_FIND_DATA				STRUCT
	; cFileName						DWORD
	; ftLastWriteTime              	FILETIME
	; dwFileAttributes				DWORD
; HANDLE						STRUCT
	;objectHandle  					DWORD
; INVALID_HANDLE_VALUE				equ -1
; FILE_ATTRIBUTE_DIRECTORY			equ 10h
; FILE_ATTRIBUTE_ARCHIVE			equ 20h
; INVALID_FILE_ATTRIBUTES			equ -1
; NULL								equ 0
;-------------------------------------------------

.DATA
; variable initialisees
	point db ".",0
	crlf db 13,10,0
	endDir db "\*",0
	antislash db "\",0
	pointpoint db "..",0
	cleanArgsLength dd 0
	arg db MAX_PATH dup(0)
	tabegal db "tab = %d",0
	printTabString db "|",9,0
	cleanArgs db MAX_PATH dup(0)
	printfDir db "<Dir> ",9,9,0
	strCommand db "Pause",13,10,0
	Dir db "Current dir = %s",13,10,0
	printFileString db "<FILE>--",9,0
	LaccesstimeString db "%d/%d/%d %d:%d",9,9,0 
	dirExistString db "Dir [%s] Exists",13,10,0
	CurretDirError db "GetCurrentDirectory failed",13,10,0
	maxDirlen db "You entered a dir with legth > MAX_PATH",13,10,0 
	invaliHandleError db "FindFirstFile() failed with code %d",13,10,0
	dirEnd db "_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ ",13,10,0
	dirDoesNotExistString db "Dir [%s] Does not exists",13,10,"Usage : [dir.exe chemin_du_repertoire](un seul chemin avec ou sans guillemet)",13,10,"***Note : Faire attention a ne mettre q'un espace entre dir.exe et le chemin_du_repertoire***",13,10,0

.DATA?
; variables non-initialisees (bss)
	dirReturn dd ?
	buff db MAX_PATH dup(?)
	ErrorCode DWORD ?
	accesstime FILETIME <>
	stUTC SYSTEMTIME <>
	stLocal SYSTEMTIME <>
	

.CODE
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
;Debut de la procédure dir print
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
dirPrint proc directory:DWORD, tab:DWORD
LOCAL file:WIN32_FIND_DATA,Laccesstime:SYSTEMTIME,search:HANDLE,path[MAX_PATH]:DWORD,dir[MAX_PATH]:byte
	mov dword ptr path,0
	;------------
	push directory
	lea eax,path
	push eax
	call crt_strcat
	;------------
	push offset endDir
	lea eax, path
	push eax
	call crt_strcat
	;------------
	lea eax,file
	push eax
	lea eax,path
	push eax
	call FindFirstFile
	;------------
	cmp eax, INVALID_HANDLE_VALUE
	je invaliHandle
	mov search,eax
	jmp FFF_loop
	;-----------
	ret
	
FFF_loop:
	cmp eax,0
	je fin
	;------------
	mov eax,file.dwFileAttributes
	mov ebx,FILE_ATTRIBUTE_DIRECTORY
	mov ecx,FILE_ATTRIBUTE_ARCHIVE
	;------------
	mov edx,eax
	and edx,ebx
	cmp edx,ebx
	je dirFound
	;------------
	mov edx,eax
	and edx,ecx
	cmp edx,ecx
	je fileFound

next:
	lea eax,file
	push eax
	push search
	call FindNextFile
	jmp FFF_loop

dirFound:
	push offset point
	lea edx, file.cFileName
	push edx
	call crt_strcmp
	cmp eax,0
	je next
	;------------
	push offset pointpoint
	lea edx,file.cFileName
	push edx
	call crt_strcmp
	cmp eax,0
	je next
	;------------
	push directory
	lea eax,dir
	push eax
	call crt_strcpy
	;------------
	push offset antislash
	lea eax,dir
	push eax
	call crt_strcat
	;------------
	lea eax, file.cFileName
	push eax
	lea eax, dir
	push eax
	call crt_strcat
	;-----------
	push tab
	call printTab
	add esp, 4
	;-----------
	lea eax, dir
	push eax
	push offset printfDir
	call crt_printf
	;------------
	lea eax,file.ftLastWriteTime
	push eax
	call GetLastAccesstime
	add esp, 4
	;-----------
	lea eax, dir
	push eax
	call crt_printf
	;------------
	push offset crlf
	call crt_printf
	;------------
	mov edx,tab
	inc edx
	push edx
	lea eax,dir
	push eax
	call dirPrint
	;------------
	jmp next
	
fileFound:
	push directory
	lea eax, dir
	push eax
	call crt_strcpy
	;------------
	push offset antislash
	lea eax, dir
	push eax
	call crt_strcat
	;------------
	lea eax, file.cFileName
	push eax
	lea eax,dir
	push eax
	call crt_strcat
	;------------
	push tab
	call printTab
	add esp,4
	;-------------
	push offset printFileString
	call crt_printf
	;------------
	lea eax,file.ftLastWriteTime
	push eax
	call GetLastAccesstime
	add esp, 4
	;------------
	lea edx,dir
	push edx
	call crt_printf
	push offset crlf
	call crt_printf
	jmp next
		
invaliHandle:
	call GetLastError
	mov ErrorCode, eax
	push offset ErrorCode
	push offset invaliHandleError
	call crt_printf
	
fin:
	push search
	call FindClose
	;inc tab
	ret
dirPrint endp
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
;Fin de la procédure dir print
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;



; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
;Debut de la procédure du start
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;

start:
	call getArgumets
	cmp dword ptr cleanArgsLength,0
	ja dirProvided
	;-----------
	push offset Dir 
	call currentDir
	;-----------
	push offset buff
	call dirExist
	;-----------
	cmp eax,1
	jne endProgramme
	;-----------
	push 0
	push offset buff
	call dirPrint
	jmp endProgramme
	
dirProvided:
	push offset arg 
	call currentDir
	;-----------
	push offset arg
	call dirExist
	;-----------
	cmp eax,1
	jne endProgramme
	;-----------
	push 0
	push offset arg
	call dirPrint
	jmp endProgramme
	
endProgramme:
	push offset strCommand
	call crt_system
	push 0
	call ExitProcess
	
dirExist:
	push ebp
	mov ebp,esp
	mov ebx,[ebp+8]
	;-----------
	push ebx
	call GetFileAttributesA
	;-----------
	mov edx,eax
	cmp edx,INVALID_FILE_ATTRIBUTES
	je dirDoesNotExist
	;-----------
	push ebx
	push offset dirExistString
	call crt_printf
	;-----------
	mov eax,1
	jmp dirExistEnd
	
dirDoesNotExist:
	push ebx
	push offset dirDoesNotExistString
	call crt_printf
	mov eax,0
	jmp dirExistEnd

dirExistEnd:
	mov esp,ebp
	pop ebp
	ret

sizeOfArgs:
	push ebp
	mov ebp,esp
	;-----------
	mov esi, 0
	mov edx, 0
	mov dword ptr cleanArgsLength,0
	mov ebx,DWORD ptr[ebp+8]
	jmp count

count:
	mov cl, byte ptr [ebx+esi]
	cmp cl,0
	je countEnd
	;-----------
	inc esi
	xor eax,eax
	movzx eax,cl
	inc edx
	jmp count
	
countEnd:
	mov dword ptr cleanArgsLength,edx
	cmp edx,0
	ja compareSizeToMaxpath
	jmp sizeOfArgsend

compareSizeToMaxpath:
	mov eax, MAX_PATH
	cmp edx,eax
	jb sizeOfArgsend
	;-----------
	push offset maxDirlen
	call crt_printf
	;-----------
	push offset strCommand
	call crt_system
	;-----------
	push 0
	call ExitProcess
	
sizeOfArgsend:
	xor eax,eax
	mov eax,dword ptr cleanArgsLength
	mov esp,ebp
	pop ebp
	ret
	
getArgumets:
	push ebp
	mov ebp,esp
	;-----------
	call GetCommandLine
	;-----------
	mov ebx, eax
	mov dword ptr cleanArgs,ebx
	push ebx
	call sizeOfArgs
	;---------
	xor ebx,ebx
	mov ebx,dword ptr cleanArgs
	push ebx
	call getDir
	;---------
	push offset arg
	call sizeOfArgs
	jmp getArgumetsEnd
	
getDir:
	push ebp
	mov ebp,esp
	;---------
	mov esi,0
	mov edi,0
	mov ebx,DWORD ptr[ebp+8]
	jmp getDirLoop1
	
getDirLoop1:
	mov cl, byte ptr [ebx+esi]
	mov ch, byte ptr [ebx+esi+1]
	cmp ch,0
	je getDirEnd
	;-----------
	cmp cl,ch
	jne continueGetDir
	;-----------
	cmp cl,22h
	je continueGetDir
	;-----------
	cmp cl,20h
	jne continueGetDir
	;-----------
	add esi,2
	jmp getDirLoop2
	
getDirLoop2:
	mov cl, byte ptr [ebx+esi]
	cmp cl,0
	je getDirEnd
	;-----------
	cmp cl,20h
	je continueGetDir2
	;-----------
	cmp cl,22h
	je continueGetDir2
	;-----------
	mov arg[edi],cl
	;-----------
	inc esi
	inc edi
	jmp getDirLoop2

continueGetDir:
	add esi,1
	jmp getDirLoop1
	
continueGetDir2:
	add esi,1
	jmp getDirLoop2

getDirEnd:
	mov arg[edi+1],0
	mov esp,ebp
	pop ebp
	ret
	
getArgumetsEnd:
	mov esp,ebp
	pop ebp
	ret
	
printTab : 
	push ebp
	mov ebp,esp

subPrintTab:
	mov ebx,[ebp+8] ; valeur de tab
	cmp ebx,0
	je printTabEnd
	;-----------
	dec ebx
	mov [ebp+8],ebx
	;-----------
	push offset printTabString
	call crt_printf
	;-----------
	jmp subPrintTab

printTabEnd:
	mov esp,ebp
	pop ebp
	ret	
	
GetLastAccesstime:
	push ebp
	mov ebp,esp
	;-----------
	mov ebx,[ebp+8] ; ebx pointeur to Laccesstime
	;-----------
	mov eax,ebx
	push offset stUTC
	push eax
	call FileTimeToSystemTime
	;-----------
	push offset stLocal
	push offset stUTC
	push NULL
	call SystemTimeToTzSpecificLocalTime
	;-----------
	movzx eax,stLocal.wMinute
	push eax
	movzx eax,stLocal.wHour
	push eax
	movzx eax,stLocal.wYear
	push eax
	movzx eax,stLocal.wMonth
	push eax
	movzx eax,stLocal.wDay
	push eax
	push offset LaccesstimeString
	call crt_printf
	;-----------
	mov esp,ebp
	pop ebp
	ret
	
currentDir:
	push ebp ;mettre la valeur de ebp dans la pile
	mov ebp,esp ;ebp égale à esp
	;-----------
	mov eax,[ebp+8] 
	;-----------
	push eax
	push offset buff
	push offset MAX_PATH
	call GetCurrentDirectory
	;-----------
	cmp eax,0
	je errorgetcurrentDir
	;-----------
	push offset buff
	push offset Dir
	call crt_printf
	;-----------
	mov esp,ebp
	pop ebp
	ret
	
errorgetcurrentDir:
	push offset CurretDirError
	call crt_printf

end start
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
;Fin de la procédure dir print
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ; ;
