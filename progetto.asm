.data
titolo:					.asciiz "GESTIONE MAGAZZINO\n"
operazioni: 			.space 32
	
newline:				.asciiz "\n"
str_main_askcod:		.asciiz "\nInserire il codice dell'operazione da eseguire:\n"
str_main_coderr:		.asciiz "Codice errato: inserire valore tra 0 e 7\n"
str_op_help:			.asciiz "Operazioni possibili:\n0 -> help\n1 -> cerca prodotto\n2 -> inserisci nuovo prodotto\n3 -> cancella prodotto\n4 -> aumenta quantita di un prodotto\n5 -> diminuisci quantita di un prodotto\n6 -> valore del magazzino\n7 -> fine programma\n"
str_op_cerca: 			.asciiz "Cerca prodotto\n"
str_cerca_zeroprod:		.asciiz "Non sono presenti prodotti in magazzino\n"
str_cerca_askcod:		.asciiz "Inserire il codice del prodotto da ricercare\n"
str_cerca_nontrovato:	.asciiz "Prodotto non in magazzino\n"
str_cerca_codprod:		.asciiz "Codice prodotto:\t"
str_cerca_nomeprod:		.asciiz "Nome prodotto:\t"
str_cerca_qntprod:		.asciiz "Quantita del prodotto in magazzino:\t"
str_cerca_valprod:		.asciiz "Valore del prodotto:\t"
str_op_inserisci: 		.asciiz "Inserisci prodotto\n"
str_inserisci_asknome:	.asciiz "Inserire il nome del prodotto (max 7 caratteri)\n"
str_inserisci_val:		.asciiz "Inserire il valore del prodotto (intero)\n"
str_inserisci_inserito:	.asciiz "Prodotto inserito\n"

str_op_aumenta: 		.asciiz "Aumenta quantita prodotto\n"
str_aumenta_qnt:		.asciiz "Inserire la quantita di prodotti da spostare in magazzino (numero positivo):\n"
str_aumenta_aumentato:	.asciiz "Aumentata la quantita del prodotto\n"
str_aumenta_numneg:		.asciiz "Inserita una quantita negativa, spostamento prodotti annullato\n"
str_aumenta_maxmag:		.asciiz "Non e' possibile aggiungere la quantita specificata di prodotti\nPosti rimanenti: "
str_op_diminuisci: 		.asciiz "Diminusci quantita prodotto\n"
str_diminuisci_qnt:		.asciiz "Inserire la quantita di prodotti da prelevare dal magazzino (numero positivo):\n"
str_diminuisci_diminuito:.asciiz "Quantita del prodotto diminuita\n"
str_diminuisci_minmag:	.asciiz "La quantita di prodotti da prelevare specificata e maggiore della quantita del prodotto in magazzino\nQuantita del prodotto: "
str_op_valore: 			.asciiz "Valore del magazzino\n"
str_valore_val: 		.asciiz "Il valore dei prodotti in magazzino e: "
str_exit:				.asciiz "Fine programma\n"


strcancella: 			.asciiz "cancella\n"

#########################################################################################################################################################################

.text
main:
# stampa titolo
	la $a0, titolo
	li $v0, 4
	syscall
	
# inizializzazione impostazioni
# quantità prodotti = 0x0000 in 2($gp)
# massima capienza = 0xFFFF in 0($gp)
	li $t0, 0xFFFF
	sw $t0, 0($gp)
	
# calcola indirizzo base e limite iniziali della lista di prodotti
# alloca spazio per 10 prodotti
	li $a0, 200
	li $v0, 9
	syscall
	move $t0, $v0		# $t0 = indirizzo memoria allocata
	sw $t0, 8($gp)
	sw $t0, 12($gp)

# numero prodotti = 0x0000 in 6($gp)
# posti in memoria = 0x000A in 4($gp)
	li $t0, 0xA
	sw $t0, 4($gp)
	
# inizializzazione jump address table delle operazioni disponibili
	la $t0, operazioni	# $t0 = indirizzo base jump address table
	la $t1, help		# $t1 = indirizzo operazione
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
	la $a0, str_op_help
	li $v0, 4
	syscall
	
#########################################################################################################################################################################

main_magazzino:
# stampa richiesta operazione
	la $a0, str_main_askcod
	li $v0, 4
	syscall
	
# richiedi codice operazione
	li $v0, 5
	syscall
	
# controllo codice operazione (cod >= 0 && cod < 8)
	move $t0, $v0			# $t0 = codice operazione dato in input
	blt $t0, $zero, main_coderr

	li $t1, 8
	blt $t0, $t1, main_cmdok

# errore codice comando
main_coderr:
	la $a0, str_main_coderr
	li $v0, 4
	syscall
	j main_magazzino

main_cmdok:
# call operazione: (codice * 4) + jat
# $t0 = codice operazione dato in input
	la $t1, operazioni	# $t1 = indirizzo base jump address table
	sll $t0, $t0, 2
	add $t1, $t0, $t1	# $t1 = indirizzo operazione in memoria
	lw $t1, 0($t1)		# $t1 = indirizzo operazione
	jal $t1
	
# operazione eseguita
	j main_magazzino
	
#########################################################################################################################################################################

help:
# stampa help
	la $a0, str_op_help
	li $v0, 4
	syscall
	jr $ra

#########################################################################################################################################################################
	
cerca:
# prologo
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
# stampa str_op_cerca
	la $a0, str_op_cerca
	li $v0, 4
	syscall
	
# controlla numero di prodotti
	lhu $s0, 6($gp)			# $s0 = numero prodotti
	beq $s0, $zero, cerca_zeroprod
	
# sono presenti prodotti in magazzino: ricava indirizzo base
	lw $s1, 8($gp)

# richiesta prodotto da ricercare
	la $a0, str_cerca_askcod
	li $v0, 4
	syscall
	
# richiedi codice prodotto
	li $v0, 5
	syscall

# call ricbin(*array, length, n)
# $s0 = numero prodotti = length
# $s1 = indirizzo base prodotti
# $v0 = codice prodotto da cercare
	move $a0, $s1
	move $a1, $s0
	move $a2, $v0
	jal ricbin

	move $s1, $v0			# $s1 = risultato ricerca binaria

# se il risultato è 0 il prodotto non è in magazzino
	beq $s1, $zero, cerca_nontrovato

# prodotto trovato
	lw $t0, 0($s1)			# $t0 = codice prodotto
	addi $t1, $s1, 4		# $t1 = indirizzo prodotto + 4 = indirizzo nome prodotto
	lw $t2, 12($s1)			# $t2 = quantità prodotto
	lw $t3, 16($s1)			# $t3 = valore prodotto

# stampa str_cerca_codprod
	la $a0, str_cerca_codprod
	li $v0, 4
	syscall

# stampa codice prodotto	
# $t0 = codice prodotto
	move $a0, $t0
	li $v0, 1
	syscall
	
# stampa newline
	la $a0, newline
	li $v0, 4
	syscall

# stampa str_cerca_nomeprod
	la $a0, str_cerca_nomeprod
	li $v0, 4
	syscall

# stampa nome prodotto
# $t1 = indirizzo nome prodotto
	move $a0, $t1
	li $v0, 4
	syscall

# stampa newline	
	la $a0, newline
	li $v0, 4
	syscall

# stampa str_cerca_qntprod
	la $a0, str_cerca_qntprod
	li $v0, 4
	syscall

# stampa quantita prodotto
# $t2 = quantità prodotto
	move $a0, $t2
	li $v0, 1
	syscall

# stampa newline	
	la $a0, newline
	li $v0, 4
	syscall

# stampa str_cerca_valprod
	la $a0, str_cerca_valprod
	li $v0, 4
	syscall

# stampa valore prodotto
# $t3 = valore prodotto
	move $a0, $t3
	li $v0, 1
	syscall
	
# stampa newline
	la $a0, newline
	li $v0, 4
	syscall
	j cerca_epilogo

cerca_zeroprod:
# non sono presenti prodotti in magazzino
# stampa str_cerca_zeroprod
	la $a0, str_cerca_zeroprod
	li $v0, 4
	syscall
	j cerca_epilogo

cerca_nontrovato:
# stampa str_cerca_nontrovato
	la $a0, str_cerca_nontrovato
	li $v0, 4
	syscall
	
cerca_epilogo:
# epilogo
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12
	jr $ra

#########################################################################################################################################################################

inserisci:
# prologo
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)

# stampa str_op_inserisci
	la $a0, str_op_inserisci
	li $v0, 4
	syscall

# controlla numero di prodotti: se è zero si deve inserire il nuovo prodotto all'inizio
	lhu $s0, 6($gp)
	beq $s0, $zero, inserisci_primaposizione

# se non è il primo prodotto calcola se c'è spazio per l'inserimento
# $s0 = numero prodotti
	lhu $s1, 4($gp)		# $s1 = prodotti inseribili in memoria
	blt $s0, $s1, inserisci_spaziosuff
	
# se non c'è spazio alloca spazio per altri 10 prodotti
# $s1 = prodotti inseribili in memoria
	li $a0, 200
	li $v0, 9
	syscall
	addi $s1, $s1, 10
	sh $s1, 4($gp)
	
inserisci_spaziosuff:
# l'indirizzo in cui inserire il prodotto è in fondo alla lista
	lw $s1, 12($gp)		# $s1 = indirizzo dove inserire il prodotto (posizione limite)
	j inserisci_inserimento

inserisci_primaposizione:
# codice prodotto di default
	li $s0, 0			# $s0 = 0 = codice del primo prodotto
	lw $s1, 8($gp)		# $s1 = indirizzo base prodotti

inserisci_inserimento:
# $s0 = codice prodotto
# $s1 = indirizzo dove inserire il prodotto
# salva codice prodotto
	sw $s0, 0($s1)

# stampa str_inserisci_asknome
	la $a0, str_inserisci_asknome
	li $v0, 4
	syscall
	
# salva nome prodotto in memoria nella struttura prodotto
	add $a0, $s1, 4
	li $a1, 8
	li $v0, 8
	syscall

# salva quantità default pari a 0
	sw $zero, 12($s1)

# chiedi valore prodotto
	la $a0, str_inserisci_val
	li $v0, 4
	syscall
	
# salva valore prodotto
	li $v0, 5
	syscall
	sw $v0, 16($s1)
	
# stampa str_inserisci_inserito
	la $a0, str_inserisci_inserito
	li $v0, 4
	syscall
	
# aggiorna indirizzo limite
# $s0 = codice prodotto
# $s1 = indirizzo dove inserire il prodotto
	addi $s1, $s1, 20	# $s1 = indirizzo prodotto successivo, nuovo indirizzo limite
	sw $s1, 12($gp)

# aggiorna numero prodotti
	lhu $s0, 6($gp)
	addi $s0, $s0, 1
	sh $s0, 6($gp)
	
# epilogo
	lw $ra, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 12
	jr $ra

#########################################################################################################################################################################

cancella:
# stampa
	la $a0, strcancella
	li $v0, 4
	syscall
	jr $ra

#########################################################################################################################################################################

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

# stampa str_op_aumenta
	la $a0, str_op_aumenta
	li $v0, 4
	syscall
	
# controlla numero di prodotti: se indirizzo base e indirizzo limite sono diversi allora sono presenti prodotti
	lw $s0, 8($gp)			# $s0 = indirizzo base prodotti			
	lw $s1, 12($gp)			# $s1 = indirizzo limite prodotti			
	beq $s0, $s1, aumenta_zeroprod
	
# stampa str_cerca_askcod
	la $a0, str_cerca_askcod
	li $v0, 4
	syscall
	
# richiedi codice prodotto
# $s0 = indirizzo base prodotti	
# $s1 = indirizzo limite prodotti
	li $v0, 5
	syscall
	move $s0, $v0 # $s0 = codice prodotto da aumentare

# stamp str_aumenta_qnt
	la $a0, str_aumenta_qnt
	li $v0, 4
	syscall
	
# richiedi quantita
	li $v0, 5
	syscall
	
# $s1 = quantita da aggiungere
	move $s1, $v0

# controlla se il numero di prodotti da aggiungere sia un numero positivo
# $s0 = codice prodotto da aumentare
# $s1 = quantita da aggiungere
	ble $s1, $zero, aumenta_numneg

# controlla che l'aumento della quantita di prodotto non superi la capienza del magazzino
# $s2 = prodotti in magazzino ; $s3 = capienza massima ; $s4 = prodotti in magazzino + quantita
	lhu $s2, 2($gp)			# $s2 = quantita prodotti attuali
	lhu $s3, 0($gp)			# $s3 = capienza massima
	add $s4, $s1, $s2		# $s4 = prodotti attuali + prodotti da inserire
	bgt $s4, $s3, aumenta_maxmag

# se l'aggiunta non supera la capienza del magazzino cerca il prodotto
# call ricbin(*array, length, n)
# $s0 = codice prodotto da aumentare
# $s1 = quantita da aggiungere
# $s2 = quantita prodotti attuali
# $s3 = capienza massima
# $s4 = prodotti attuali + prodotti da inserire
	lw $a0, 8($gp)
	
# calcola lunghezza array (numero prodotti)
	lw $s3, 8($gp)			# $s3 = indirizzo base prodotti
	lw $s5, 12($gp)			# $s5 = indirizzo limite prodotti
	sub $s3, $s5, $s3		# $s3 = indirizzo limite - indirizzo base
	li $s5, 20				# $s5 = dimensione struttura prodotto
	div $s3, $s3, $s5		# $s3 = lunghezza array
	move $a1, $s3
	
	move $a2, $s0
	jal ricbin
	
# controllo risultato ricerca: se è 0 allora il prodotto non è presente in magazzino
	beq $v0, $zero, aumenta_nontrovato
	
# aumenta quantita prodotto
# $s0 = codice prodotto da aumentare
# $s1 = quantita da aggiungere
# $s2 = quantita prodotti attuali
# $s3 = indirizzo limite - indirizzo base
# $s4 = prodotti attuali + prodotti da inserire
# $s5 = dimensione struttura prodotto
	move $s0, $v0			# $s0 = indirizzo prodotto
	lw $s2, 12($s0)			# $s2 = quantita attuale prodotto
	add $s2, $s2, $s1		# $s2 = quantita finale prodotto
	sw $s2, 12($s0)

# aggiorna contatore dei prodotti in magazzino
	sh $s4, 2($gp)
	
# stampa str_aumenta_aumentato
	la $a0, str_aumenta_aumentato
	li $v0, 4
	syscall
	j aumenta_epilogo

aumenta_zeroprod:
# non sono presenti prodotti in magazzino
# stampa str_cerca_zeroprod
	la $a0, str_cerca_zeroprod
	li $v0, 4
	syscall
	j aumenta_epilogo
	
# è stato inserita una quantità negativa
aumenta_numneg:
# stampa str_aumenta_numneg
	la $a0, str_aumenta_numneg
	li $v0, 4
	syscall
	j aumenta_epilogo

# è stata superata la capienza del magazzino
aumenta_maxmag:
# stampa str_aumenta_maxmag
	la $a0, str_aumenta_maxmag
	li $v0, 4
	syscall
	
# stampa posti rimanenti
# $s0 = codice prodotto da aumentare
# $s1 = quantita da aggiungere
# $s2 = quantita prodotti attuali
# $s3 = indirizzo limite - indirizzo base
# $s4 = prodotti attuali + prodotti da inserire
# $s5 = dimensione struttura prodotto
	sub $a0, $s3, $s2	# $a0 = indirizzo limite - indirizzo base - quantita attuale
	li $v0, 1
	syscall
	
# stampa newline	
	la $a0, newline
	li $v0, 4
	syscall
	j aumenta_epilogo

# prodotto non in magazzino
aumenta_nontrovato:
	la $a0, str_cerca_nontrovato
	li $v0, 4
	syscall
	
# epilogo
aumenta_epilogo:
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28
	jr $ra

#########################################################################################################################################################################

diminuisci:
# prologo
	addi $sp, $sp, -20
	sw $ra, 16($sp)
	sw $s3, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
# stampa str_op_diminuisci
	la $a0, str_op_diminuisci
	li $v0, 4
	syscall

# controllo presenza prodotti in magazzino (indirizzo base == indirizzo limite)
	lw $s0, 8($gp)			# $s0 = indirizzo base prodotti
	lw $s1, 12($gp)			# $s1 = indirizzo limite prodotti
	beq $s0, $s1, diminuisci_zeroprod	
	
# stampa str_cerca_askcod
	la $a0, str_cerca_askcod
	li $v0, 4
	syscall

# richiedi codice prodotto
	li $v0, 5
	syscall

# $s0 = codice prodotto da aumentare
	move $s0, $v0
	
# stampa str_diminuisci_qnt
	la $a0, str_diminuisci_qnt
	li $v0, 4
	syscall

# richiedi quantita da prelevare
	li $v0, 5
	syscall
	
# $s0 = codice prodotto da aumentare
# $s1 = quantita da prelevare
	move $s1, $v0
	
# la quantita inserita deve essere positiva
	ble $s1, $zero, diminuisci_numneg

# cerca prodotto
# call ricbin(*array, length, n)
	lw $a0, 8($gp)
	
	lw $s2, 8($gp)				# $s2 = indirizzo base prodotti
	lw $s3, 12($gp)				# $s3 = indirizzo limite prodotti
	sub $s2, $s3, $s2			# $s2 = indirizzo limite - indirizzo base prodotti
	li $t0, 20					# $t0 = dimensione struttura prodotto
	div $s2, $s2, $t0			# $s2 = numero prodotti = length
	move $a1, $s2
	
	move $a2, $s0
	jal ricbin

# controllo risultato ricerca: se è 0 allora il prodotto non è presente in magazzino
	beq $v0, $zero, diminuisci_nontrovato

# $s0 = codice prodotto da aumentare
# $s1 = quantita da prelevare
# $s2 = numero prodotti
# $s3 = indirizzo limite prodotti
	move $s0, $v0				# $s0 = indirizzo prodotto
	lw $s2, 12($s0)				# $s2 = quantita prodotto cercato in magazzino
	
# controllo quantita prodotto - quantita da prelevare >= 0
	sub $s3, $s2, $s1			# $s3 = quantita prodotto - quantita da prelevare = nuova quantita prodotto
	blt $s3, $zero, diminuisci_minmag
	
# se la quantita rimane positiva aggiorna la quantita del prodotto
# $s3 = nuova quantita prodotto
	sw $s3, 12($s0)
	
# modifica impostazioni magazzino
# $s0 = codice prodotto da aumentare
# $s1 = quantita da prelevare
# $s2 = numero prodotti
# $s3 = nuova quantita prodotto
	lhu $s3, 2($gp)				# $s3 = quantita totale di prodotti in magazzino
	sub $s3, $s3, $s1			# $s3 = quantita totale - quantita prelevata
	sh $s3, 2($gp)

# stampa str_diminuisci_diminuito
	la $a0, str_diminuisci_diminuito
	li $v0, 4
	syscall
	j diminuisci_epilogo

# non sono presenti prodotti in magazzino
diminuisci_zeroprod:
#stampa str_cerca_zeroprod
	la $a0, str_cerca_zeroprod
	li $v0, 4
	syscall
	j diminuisci_epilogo
	
# è stata inserita una quantita negativa
diminuisci_numneg:
	la $a0, str_aumenta_numneg
	li $v0, 4
	syscall
	j diminuisci_epilogo

# si prelevano più prodotti di quelli presenti in magazzino
diminuisci_minmag:
# stampa str_diminuisci_minmag
	la $a0, str_diminuisci_minmag
	li $v0, 4
	syscall

# stampa quantita attuale del prodotto in magazzino
# $s2 = numero prodotti
	move $a0, $s2
	li $v0, 1
	syscall
	
# stampa newline
	la $a0, newline
	li $v0, 4
	syscall
	j diminuisci_epilogo
	
# prodotto non in magazzino
diminuisci_nontrovato:
	la $a0, str_cerca_nontrovato
	li $v0, 4
	syscall

# epilogo
diminuisci_epilogo:
	lw $ra, 16($sp)
	lw $s3, 12($sp)
	lw $s2, 8($sp)
	lw $s1, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 20
	jr $ra

#########################################################################################################################################################################

valore:
# prologo
	addi $sp, $sp, -16
	sw $ra, 12($sp)
	sw $s2, 8($sp)
	sw $s1, 4($sp)
	sw $s0, 0($sp)
	
# stampa titolo
	la $a0, str_op_valore
	li $v0, 4
	syscall

# controllo presenza prodotti in magazzino (indirizzo base == indirizzo limite)
	lw $s0, 8($gp)			# $s0 = indirizzo base prodotti
	lw $s1, 12($gp)			# $s1 = indirizzo limite prodotti
	beq $s0, $s1, valore_zeroprod

# calcola numero di prodotti
# $s0 = indirizzo base prodotti
# $s1 = indirizzo limite prodotti
	sub $s1, $s1, $s0		# $s1 = indirizzo limite - indirizzo base
	li $t0, 20				# $t0 = dimensione struttura prodotto
	div $s1, $s1, $t0		# $s1 = numero prodotti
	li $s2, 0				# $s2 = somma valori
	
valoreLoop:
# calcola valore totale del prodotto corrente(quantita * valore)
# $s0 = indirizzo prodotto corrente
	lw $t0, 12($s0)			# $t0 = quantita prodotto
	lw $t1, 16($s0)			# $t1 = valore prodotto
	mul $t0, $t0, $t1		# $t0 = valore totale prodotto

# somma valore del prodotto corrente al totale
# $s2 = somma valori
	add $s2, $s2, $t0		# $s2 = valore prodotti precedenti + valore prodotto corrente
	
# controllo fine prodotti
# $s1 = numero prodotti
	addi $s1, $s1, -1		# decrementa contatore (numero prodotti)
	beq $s1, $zero, valore_res
	
# calcola indirizzo del prossimo prodotto
# $s0 = indirizzo prodotto corrente
	addi $s0, $s0, 20		# $s0 = indirizzo prodotto corrente + dimensione struttura prodotto
	j valoreLoop
	
# non ci sono prodotti in magazzino
valore_zeroprod:
# stampa str_cerca_zeroprod
	la $a0, str_cerca_zeroprod
	li $v0, 4
	syscall
	j valore_epilogo
	
# stampa risultato valore magazzino
valore_res:
# stampa str_valore_val
	la $a0, str_valore_val
	li $v0, 4
	syscall

# stampa valore
# $s2 = valore magazzino
	move $a0, $s2
	li $v0, 1
	syscall
	
# stampa newline
	la $a0, newline
	li $v0, 4
	syscall
	
valore_epilogo:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $ra, 12($sp)
	addi $sp, $sp, 16
	jr $ra

exit:
# stampa
	la $a0, str_exit
	li $v0, 4
	syscall

# exit
	li $v0, 10
	syscall	

#########################################################################################################################################################################

# ricerca binaria (*array, length, n)
ricbin:
# $a0 = indirizzo primo prodotto
# $a1 = numero prodotti
# $a2 = codice prodotto ricercato

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
# $a1 = numero prodotti
	li $t0, 1
	bgt $a1, $t0, ric			# se c'è più di 1 prodotto vai a ric
	
# controlla l'unico prodotto in magazzino
# $a2 = codice prodotto ricercato
	move $s1, $a0				# $s1 = indirizzo primo prodotto
	lw $s2, 0($s1)				# $s2 = codice primo prodotto
	beq $a2, $s2, ReturnBase	# prodotto trovato
	j product_not_found				# prodotto non presente in magazzino
	
ric:
# dimezza array dei prodotti
# $a1 = numero prodotti
	srl $s0, $a1, 1				# $s0 = numero prodotti rimanenti / 2
	
# calcola offset dell'indirizzo del prodotto in posizione centrale
# $s0 = nuova dimensione array
# $s1 = indirizzo base prodotti
	li $t0, 20					# $t0 = dimensione struttura prodotto
	mul $s1, $s0, $t0			# $s1 = offset indirizzo prodotto centrale
	
# ricava prodotto centrale dell'array
# $a0 = indirizzo primo prodotto
# $s1 = offset indirizzo prodotto centrale
	add $s1, $a0, $s1			# $s1 = indirizzo prodotto centrale
	lw $s2, 0($s1)				# $s2 = prodotto centrale
	
# controlla se il prodotto centrale è quello cercato
	beq $a2, $s2, ReturnBase

# se il prodotto cercato non è in posizione centrale controlla l'indice: se è maggiore, ricerca nella parte destra dell'array
# $a2 = codice prodotto ricercato
# $s2 = prodotto centrale
	bgt $a2, $s2, search_dx

# se il prodotto cercato non è in posizione centrale controlla l'indice: se è minore, ricerca nella parte sinistra dell'array
# ricbin(*array, new_length, n)
# $s0 = nuova dimensione array
	move $a1, $s0
	jal ricbin
	
# controlla risultato: se ritorna 0 il prodotto non è in magazzino
	beq $v0, $zero, product_not_found
	j product_found

# ricerca nella parte destra dell'array rimanente	
search_dx:
# controlla se si è raggiunto la fine dell'array
# $s1 = indirizzo prodotto centrale
	lw $s3, 12($gp)				# $s3 = indirizzo ultimo prodotto
	addi $s4, $s1, 20			# $s4 = indirizzo primo prodotto della parte destra dell'array
	bge $s4, $s3, product_not_found
	
# controlla se c'è un numero pari o dispari di prodotti
# $a1 = numero prodotti
	li $t0, 2
	div $a1, $t0
	mfhi $s5					# $s5 = numero prodotti modulo 2
	beq $s5, $zero, pari
	
# ricbin(array[length / 2 + 1], length / 2, n)
# $s0 = nuova dimensione array
# $s4 = indirizzo primo prodotto della parte destra dell'array
	move $a0, $s4
	move $a1, $s0
	jal ricbin
	
# controllo risultati
	beq $v0, $zero, product_not_found
	j product_found
	
pari:
# ricbin(array[length / 2 + 1], length / 2 - 1, n)
# $s0 = nuova dimensione array
# $s4 = indirizzo primo prodotto della parte destra dell'array
	move $a0, $s4				
	addi $a1, $s0, -1
	jal ricbin
	
# controllo risultati
	beq $v0, $zero, product_not_found
	j product_found	
	
# prodotto trovato, return indirizzo prodotto
ReturnBase:
	# $s1 = indirizzo prodotto
	move $v0, $s1
	
product_found:
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

product_not_found:
# epilogo
	lw $ra, 24($sp)
	lw $s0, 20($sp)
	lw $s1, 16($sp)
	lw $s2, 12($sp)
	lw $s3, 8($sp)
	lw $s4, 4($sp)
	lw $s5, 0($sp)
	addi $sp, $sp, 28

# return 0
	li $v0, 0
	jr $ra