.data
titolo: 		.asciiz "GESTIONE MAGAZZINO\n"
operazioni: 	.space 32

newline:		.asciiz "\n"
strerr:			.asciiz "codice errato: inserire valore tra 0 e 7\n"
strhelp:		.asciiz "operazioni possibili:\n0 -> help\n1 -> cerca prodotto\n2 -> inserisci nuovo prodotto\n3 -> cancella prodotto\n4 -> aumenta quantità di un prodotto\n5 -> diminuisci quantità di un prodotto\n6 -> valore del magazzino\n7 -> fine programma\n"
strcerca: 		.asciiz "cerca\n"
strcercaask:	.asciiz "inserire il codice del prodotto da ricercare\n"
strnontrovato:	.asciiz "prodotto non in magazzino\n"
strcodice:		.asciiz "codice prodotto:\t"
strnome:		.asciiz "nome prodotto:\t"
straskquantita:	.asciiz "quantità prodotto:\t"
strvaloreprd:	.asciiz "valore prodotto:\t"
strinserisci: 	.asciiz "inserisci\n"
strasknome:		.asciiz "inserire nome prodotto (max 7 caratteri)\n"
straskvalore:	.asciiz "inserire valore prodotto (intero)\n"
strinserito:	.asciiz "prodotto inserito\n"
strcancella: 	.asciiz "cancella\n"
straumenta: 	.asciiz "aumenta\n"
strquantitain:	.asciiz "inserire la quantità di prodotti da spostare in magazzino (numero positivo):\n"
strquantitaout:	.asciiz "inserire la quantità di prodotti da prelevare dal magazzino (numero positivo):\n"
strerrneg:		.asciiz "inserita una quantità negativa, spostamento prodotti annullato\n"
strmaxmag:		.asciiz "non è possibile aggiungere la quantità specificata di prodotti\nposti rimanenti: "
straumentato:	.asciiz "quantità del prodotto aumentata\n"
strdiminuisci: 	.asciiz "diminusci\n"
strminmag:		.asciiz "la quantità di prodotti da prelevare specificata è maggiore della quantità del prodotto in magazzino\nquantità del prodotto: "
strdiminuito:	.asciiz "quantità del prodotto diminuita\n"
strvalore: 		.asciiz "valore magazzino\n"
strvaloremag: 	.asciiz "il valore dei prodotti in magazzino è: "
strexit:		.asciiz "fine\n"
strzero:		.asciiz "non sono presenti prodotti in magazzino\n"



# 0($gp) <-> |capienza| 					-> 2 byte in 0x10040000
# 2($gp) <-> |quantità prodotti|			-> 2 byte in 0x10040002
# 4($gp) <-> |indirizzo base prodotti|  	-> 4 byte in 0x10040004
# 8($gp) <-> |indirizzo limite prodotti|  	-> 4 byte in 0x10040008

.text
main:
# stampa titolo
	la $a0, titolo
	li $v0, 4
	syscall
	
# inizializzazione impostazioni
# numero elementi  = 0x0000
# massima capienza = 0xFFFF
	li $t0, 0xFFFF
	sw $t0, 0($gp)
	
# indirizzo base della lista di prodotti
# alloca spazio per 10 prodotti
	li $a0, 200
	li $v0, 9
	syscall
	move $t0, $v0
	sw $t0, 4($gp)
	sw $t0, 8($gp)
	
# inizializzazione jump address table delle operazioni disponibili
	la $t0, operazioni
	la $t1, help
	sw $t1, 0($t0)
	la $t1, cerca
	sw $t1, 4($t0)
	la $t1, inserisci
	sw $t1, 8($t0)
	la $t1, cancella
	sw $t1, 12($t0)
	la $t1, aumenta
	sw $t1, 16($t0)
	la $t1, diminuisci
	sw $t1, 20($t0)
	la $t1, valore
	sw $t1, 24($t0)
	la $t1, exit
	sw $t1, 28($t0)

# stampa help
	la $a0, strhelp
	li $v0, 4
	syscall
	
# richiesta operazione
Loop:
	li $v0, 5
	syscall
	
# controllo operazione
	li $t0, 8
	move $t1, $v0
	blt $t1, $t0, cmdok

# errore codice comando
	la $a0, strerr
	li $v0, 4
	syscall
	j Loop
	
# chiama operazione
cmdok:
	la $t0, operazioni
	sll $t1, $t1, 2
	add $t1, $t0, $t1
	lw $t1, 0($t1)
	jal $t1
	j Loop
	
exit:
	la $a0, strexit
	li $v0, 4
	syscall
	li $v0, 10
	syscall
	
#############################################################################################################################

help:
	la $a0, strhelp
	li $v0, 4
	syscall
	jr $ra
	
cerca:
# prologo
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
# stampa strcerca
	la $a0, strcerca
	li $v0, 4
	syscall
	
# controlla numero di prodotti
	lw $s0, 4($gp)					# $s0 = indirizzo base prodotti
	lw $s1, 8($gp)					# $s1 = indirizzo limite prodotti	
	beq $s0, $s1, zeropr
	
# sono presenti prodotti
	sub $s0, $s1, $s0
	li $s2, 20
	div $s0, $s0, $s2				# $s0 = numero prodotti
	lw $s1, 4($gp)					# $s1 = indirizzo primo prodotto

# richiesta prodotto da ricercare
	la $a0, strcercaask
	li $v0, 4
	syscall
	li $v0, 5
	syscall

# RicBin($array, length, n)
	move $a0, $s1
	move $a1, $s0
	move $a2, $v0
	jal RicBin

	move $s1, $v0			# $s1 = risultato ricerca

	beq $s1, $zero, nontrovato

	lw $t0, 0($s1)			# $t0 = codice prodotto
	addi $t1, $s1, 4		# $t1 = indirizzo nome prodotto
	lw $t2, 12($s1)			# $t2 = quantità prodotto
	lw $t3, 16($s1)			# $t3 = valore prodotto

# stampa codice prodotto
	la $a0, strcodice
	li $v0, 4
	syscall
	
	move $a0, $t0
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall

# stampa nome prodotto
	la $a0, strnome
	li $v0, 4
	syscall
	
	move $a0, $t1
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall

# stampa quantità prodotto
	la $a0, straskquantita
	li $v0, 4
	syscall
	
	move $a0, $t2
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall

# stampa valore prodotto
	la $a0, strvaloreprd
	li $v0, 4
	syscall
	
	move $a0, $t3
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	j epilogo

# non sono presenti prodotti in magazzino
zeropr:
	la $a0, strzero
	li $v0, 4
	syscall
	j epilogo

nontrovato:
	la $a0, strnontrovato
	li $v0, 4
	syscall
	
# epilogo
epilogo:
	lw $ra, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 16
	jr $ra

inserisci:
# prologo
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s0, 8($sp)
	sw $s1, 4($sp)
	sw $s2, 0($sp)

# stampa
	la $a0, strinserisci
	li $v0, 4
	syscall

# controlla presenza di prodotti
	lw $s0, 4($gp)		# $s0 = indirizzo base prodotti
	lw $s1, 8($gp)		# $s1 = indirizzo limite prodotti
	beq $s0, $s1, primo

# controlla se c'è spazio per l'inserimento
	sub $s0, $s1, $s0	# calcola il numero di prodotti
	li $s1, 20
	div $s0, $s0, $s1	# $s0 = numero di prodotti
	li $s1, 10
	div $s0, $s1
	mfhi $s1			# $s1 = $s0 % 10
	
# se $s1 = 9 aumenta spazio per altri 10 prodotti
	li $s2, 9
	bne $s1, $s2, spaziosuff
	li $a0, 200
	li $v0, 9
	syscall	
	
spaziosuff:
# l'indirizzo in cui inserire il prodotto è in fondo alla lista
	lw $s1, 8($gp)		# $s1 = indirizzo dove inserire il prodotto
	j insert
	
primo:
	li $s0, 0			# $s0 = 0 = codice del primo prodotto

insert:
# salva codice prodotto default
	sw $s0, 0($s1)

# chiedi nome prodotto
	la $a0, strasknome
	li $v0, 4
	syscall
	add $a0, $s1, 4
	li $a1, 8
	li $v0, 8
	syscall

# salva quantità default 0
	sw $zero, 12($s1)

# chiedi valore prodotto
	la $a0, straskvalore
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	sw $v0, 16($s1)
	
# stampa prodotto inserito
	la $a0, strinserito
	li $v0, 4
	syscall
	
# aggiorna indirizzo limite
	addi $s1, $s1, 20
	sw $s1, 8($gp)

# epilogo
	lw $ra, 12($sp)
	lw $s0, 8($sp)
	lw $s1, 4($sp)
	lw $s2, 0($sp)
	addi $sp, $sp, 16
	jr $ra

cancella:
# stampa
	la $a0, strcancella
	li $v0, 4
	syscall
	jr $ra

aumenta:
# prologo
	addi $sp, $sp, -28
	sw $ra, 24($sp)
	sw $s0, 20($sp)
	sw $s1, 16($sp)
	sw $s2, 12($sp)
	sw $s3, 8($sp)
	sw $s4, 4($sp)
	sw $s5, 0($sp)

# stampa titolo
	la $a0, straumenta
	li $v0, 4
	syscall
	
# stampa richiesta
	la $a0, strcercaask
	li $v0, 4
	syscall
	li $v0, 5
	syscall

# $s0 = codice prodotto da aumentare
	move $s0, $v0

# richiedi quantita
	la $a0, strquantitain
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	
# $s1 = quantità
	move $s1, $v0

# controlla numero positivo
	ble $s1, $zero, errnegaum

# controlla capienza magazzino
# $s2 = prodotti in magazzino ; $s3 = capienza massima ; $s4 = prodotti in magazzino + quantita
	lhu $s2, 2($gp)
	lhu $s3, 0($gp)
	add $s4, $s2, $s1
	bgt $s4, $s3, maxmag
	
# cerca prodotto
	lw $a0, 4($gp)
	
	lw $s3, 4($gp)
	lw $s5, 8($gp)
	sub $s3, $s5, $s3
	li $s5, 20
	div $s3, $s3, $s5				# $s3 = numero prodotti
	move $a1, $s3
	
	move $a2, $s0
	jal RicBin
	
# controllo prodotto
	beq $v0, $zero, errpntaum
	
# modifica quantità prodotto
# $s0 = indirizzo prodotto
# $s2 = quantità prodotto
	move $s0, $v0
	lw $s2, 12($s0)
	add $s2, $s2, $s1
	sw $s2, 12($s0)

# modifica impostazioni magazzino
	sh $s4, 2($gp)
		##################################################################		
# stampa stringa aumentato
	la $a0, straumentato
	li $v0, 4
	syscall
	j epilogoaum

# è stato inserita una quantità negativa
errnegaum:
	la $a0, strerrneg
	li $v0, 4
	syscall
	j epilogoaum

# è stata superata la capienza del magazzino
maxmag:
	la $a0, strmaxmag
	li $v0, 4
	syscall
	
# stampa posti rimanenti
	sub $a0, $s3, $s2
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	j epilogoaum

# prodotto non in magazzino
errpntaum:
	la $a0, strnontrovato
	li $v0, 4
	syscall
	
# epilogo
epilogoaum:
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28
	jr $ra

diminuisci:
# prologo
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	
# stampa titolo
	la $a0, strdiminuisci
	li $v0, 4
	syscall

# stampa richiesta
	la $a0, strcercaask
	li $v0, 4
	syscall
	li $v0, 5
	syscall

# $s0 = codice prodotto da aumentare
	move $s0, $v0
	
# richiedi quantita
	la $a0, strquantitaout
	li $v0, 4
	syscall
	li $v0, 5
	syscall
	
# $s1 = quantità da prelevare
	move $s1, $v0
	
# controlla numero positivo
	ble $s1, $zero, errnegdim

# cerca prodotto
	lw $a0, 4($gp)
	
	lw $s2, 4($gp)
	lw $s3, 8($gp)
	sub $s2, $s3, $s2
	li $s3, 20
	div $s2, $s2, $s3				# $s2 = numero prodotti
	move $a1, $s2
	
	move $a2, $s0
	jal RicBin

# controllo prodotto
	beq $v0, $zero, errpntdim

# $s0 = indirizzo prodotto
# $s2 = quantità prodotto in magazzino
	move $s0, $v0
	lw $s2, 12($s0)
	
# controllo quantità prodotto - quantità da prelevare >= 0
	sub $s3, $s2, $s1
	blt $s3, $zero, minmag
	
# preleva prodotto
	sw $s3, 12($s0)
	
# modifica impostazioni magazzino
	lhu $s3, 2($gp)
	sub $s3, $s3, $s1
	sh $s3, 2($gp)

# stampa stringa diminuito
	la $a0, strdiminuito
	li $v0, 4
	syscall
	j epilogodim

# è stato inserita una quantità negativa
errnegdim:
	la $a0, strerrneg
	li $v0, 4
	syscall
	j epilogodim

# si prelevano più prodotti di quelli presenti in magazzino
minmag:
	la $a0, strminmag
	li $v0, 4
	syscall

# stampa quantità prodotto in magazzino
	add $a0, $zero, $s2
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	j epilogodim
	
# prodotto non in magazzino
errpntdim:
	la $a0, strnontrovato
	li $v0, 4
	syscall

# epilogo
epilogodim:
	lw $ra, 8($sp)
	lw $s0, 4($sp)
	lw $s1, 0($sp)
	addi $sp, $sp, 12
	jr $ra

valore:
# prologo
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s0, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
# stampa titolo
	la $a0, strvalore
	li $v0, 4
	syscall
	
# $s0 = indirizzo primo prodotto
# $s1 = indirizzo ultimo prodotto
	lw $s0, 4($gp)
	lw $s1, 8($gp)

# controllo presenza prodotti in magazzino
	beq $s0, $s1, noprod
	
# $s0 = indirizzo prodotto corrente
# $s1 = numero prodotti
# $s2 = somma
	sub $s1, $s1, $s0
	li $s2, 20
	div $s1, $s1, $s2
	li $s2, 0

valoreLoop:	
# calcola valore totale del prodotto (quantità * valore)
	lw $t0, 12($s0)
	lw $t1, 16($s0)
	mul $t0, $t0, $t1

# somma valore del prodotto corrente al totale
	add $s2, $s2, $t0
	
# controllo fine prodotti
	addi $s1, $s1, -1
	beq $s1, $zero, result
	
# calcola indirizzo del prossimo prodotto
	addi $s0, $s0, 20
	j valoreLoop
	
noprod:
	la $a0, strzero
	li $v0, 4
	syscall
	j valoreepilogo
	
result:
	la $a0, strvaloremag
	li $v0, 4
	syscall
	
	move $a0, $s2
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
valoreepilogo:
	lw $s2, 0($sp)
	lw $s1, 4($sp)
	lw $s0, 8($sp)
	lw $ra, 12($sp)
	jr $ra

# ricerca binaria (*array, length, n)
RicBin:
# prologo
	addi $sp, $sp, -28
	sw $ra, 24($sp)				# save $ra
	sw $s0, 20($sp)				# save $s0
	sw $s1, 16($sp)				# save $s1
	sw $s2, 12($sp)				# salva $s2
	sw $s3, 8($sp)				# salva $s3
	sw $s4, 4($sp)				# salva $s4
	sw $s5, 0($sp)				# salva $s5

# controlla numero di prodotti
	li $t0, 1
	bgt $a1, $t0, Ric			# se ci sono più di 1 prodotto vai a Ric
	
# controlla l'unico prodotto in magazzino
	move $s1, $a0
	lw $s2, 0($s1)
	beq $a2, $s2, ReturnBase
	j ReturnFalse
	
Ric:
# $s0 = length / 2
	srl $s0, $a1, 1
	
# $s1 = $s0 * sizeof(prodotto)	
	li $t0, 20
	mul $s1, $s0, $t0
	
# $s1 = &array[length / 2]
# $s2 = array[length / 2]
	add $s1, $a0, $s1		
	lw $s2, 0($s1)
	
# controlla se in $s2 c'è l'elemento cercato
	beq $a2, $s2, ReturnBase

# ricerca a destra
	bgt $a2, $s2, SearchDx

# ricerca a sinistra	
	move $a1, $s0
	jal RicBin
	
# controlla risultato
	beq $v0, $zero, ReturnFalse
	j ReturnTrue
	
SearchDx:
	lw $s3, 8($gp)		# $s3 = indirizzo limite
	addi $s4, $s1, 20	# $s4 = &array[length / 2 + 1]
	bge $s4, $s3, ReturnFalse
	
# $s5 = length % 2
	li $t0, 2
	div $a1, $t0
	mfhi $s5

# controlla se $s4 è pari o dispari
	beq $s5, $zero, Pari
	
# RicBin(array[length / 2 + 1], length / 2, n)
	move $a0, $s4			
	move $a1, $s0
	jal RicBin
	
# controllo risultati
	beq $v0, $zero, ReturnFalse
	j ReturnTrue
	
Pari:
# RicBin(array[length / 2 + 1], length / 2 - 1, n)
	move $a0, $s4				
	addi $a1, $s0, -1
	jal RicBin
	
# controllo risultati
	beq $v0, $zero, ReturnFalse
	j ReturnTrue	
	
ReturnBase:
	move $v0, $s1
	
ReturnTrue:
# epilogo	
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28
	jr $ra

ReturnFalse:
# epilogo
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28
	
	li $v0, 0
	jr $ra