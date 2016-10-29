##########################################################################
# 	       @author: Wojciech Janaszek				 #
#      		      - negatyw obrazka bmp				 #
##########################################################################

		.data

buff:		.space 4
offset:		.space 4
size:		.space 4
width:		.space 4
height:		.space 4
poczatek:	.space 4

msgIntro:	.ascii " Wojciech Janaszek\n"
		.asciiz "--- Negatyw bmp ---\n"
msgFileExc:	.asciiz "Blad zwiazany z plikiem\n"
fileNameIn:	.asciiz "czwarty.bmp"
fileNameOut:	.asciiz "c-out.bmp"

		.text
		.globl main

main:
	# wyswietlenie informacji powiatlnej:
	la $a0, msgIntro
	li $v0, 4
	syscall
	
readFile:
	##########################################################################
	# Zawartosc rejestrow:
	##########################################################################
	# $t1 --> deskryptor pliku
	# $s0 --> rozmiar pliku
	# $s1 --> adres zaalokowanej pamieci
	# $s2 --> width
	# $s3 --> height
	##########################################################################

	# otworzenie pliku o nazwie 'in.bmp':
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	move $t1, $v0 		# deskryptor pliku do $t1
	
	bltz $t1, fileExc
	
	# odczytanie 2 bajtow 'BM':
	move $a0, $t1
	la $a1, buff
	li $a2, 2
	li $v0, 14
	syscall
	
	# odczytanie 4 bajtow okreslajacych rozmiar pliku
	move $a0, $t1
	la $a1, size
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s0, size		# zapisanie rozmiaru w $s0
	
	# alokacja pamieci o rozmiarze pliku:
	move $a0, $s0
	li $v0, 9
	syscall
	
	move $s1, $v0		# przekazanie adresu zaalokowanej pamieci do $s1
	sw $s1, poczatek
	
	# odczytanie 4 bajtow zarezerwowanych:
	move $a0, $t1		# przywrocenie deskrptora pliku dla $a0
	la $a1, buff
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie offsetu:
	move $a0, $t1
	la $a1, offset
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie 4 bajtow naglowka informacyjnego:
	move $a0, $t1
	la $a1, buff
	li $a2, 4
	li $v0, 14
	syscall
	
	# odczytanie szerokosci (width) obrazka:
	move $a0, $t1
	la $a1, width
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s2, width			# zaladowanie width do $s2
	
	# odczytanie wysokosci (height) obrazka:
	move $a0, $t1
	la $a1, height
	li $a2, 4
	li $v0, 14
	syscall
	
	lw $s3, height			# zaladowanie height do $s3
	
	# zamkniecie pliku:
	move $a0, $t1
	li $v0, 16
	syscall
	
readBytes:
	# wczytuje tablice pikseli do pod adres zaalokowanej pamieci w $s1
	la $a0, fileNameIn
	la $a1, 0
	la $a2, 0
	li $v0, 13
	syscall
	
	move $t1, $v0
	
	move $a0, $t1
	la $a1, ($s1)
	la $a2, ($s0)		# wczytanie tylu bajtow, ile ma plik
	li $v0, 14
	syscall
	
	lw $s0, size
	
	move $a0, $t1		# zamkniecie pliku
	li $v0, 16
	syscall
	
negative:
	##########################################################################
	#| Zawartosc rejestrow:							|#
	##########################################################################
	# $s0 --> size
	# $s1 --> adres zaalokowanej pamieci (gdzie wczytany zostal caly plik bmp)
	# $s2 --> width
	# $s3 --> height
	# $s5 --> offset
	# $t5 --> liczba pikseli w calym pliku (koniec petli)
	# $s6 --> licznik pikseli w wierszu
	##########################################################################
	# Kolory itp:								 #
	##########################################################################
	# $t0 --> R piksela
	# $t1 --> G piksela
	# $t2 --> B piksela
	# $t3 --> stala 255
	# $t4 --> licznik przerobionych pikseli
	# $t6 --> tymczasowy rejestr do obliczen
	# $t7 --> reszta z dzielenia width / 4 (padding)
	##########################################################################
	
	lw $s5, offset		# zaladowanie offsetu do $s5
	li $t4, 0		# licznik przerobionych pikseli ustawiony na 0
	
	lw $s2, width
	lw $s3, height
	
	mul $t5, $s2, $s3	# width * height
	li $t3, 255		# zaladowanie stalej maksymalnej skladowej koloru
	
	add $s1, $s1, $s5	# przejscie na poczatek tabeli pikseli
	
	li $s6, 1		# ustawienie licznika pikseli w wierszu na 1
		
paddingCheck:
	li $t7, 4
	andi $t7, $s2, 0x00000003

loop:	
	beq $t4, $t5, saveFile
	lbu $t0, ($s1)		# wczytanie R piksela
	addi $s1, $s1, 1	# przejscie o kolejny bajt
	
	lbu $t1, ($s1)		# wczytanie G piksela
	addi $s1, $s1, 1	# przejscie o kolejny bajt
	
	lbu $t2, ($s1)		# wczytanie B piksela
	addi $s1, $s1, -2	# wroc do danego piksela
	
	# przerabianie skladowej kazdego koloru dla danego piksela:
	sub $t6, $t3, $t0		# R = 255 - pix.getR()
	sb $t6, ($s1)			# nadpisanie nowa skladowa
	addi $s1, $s1, 1		# przejscie o kolejny bajt w tablicy pikseli
	
	sub $t6, $t3, $t1		# G = 255 - pix.getG()
	sb $t6, ($s1)			# nadpisanie nowa skladowa
	addi $s1, $s1, 1		# przejscie o kolejny bajt w tablicy pikseli
	
	sub $t6, $t3, $t2		# B = 255 - pix.getB()
	sb $t6, ($s1)			# nadpisanie nowa skladowa
	addi $s1, $s1, 1		# przejscie o kolejny bajt w tablicy pikseli
	
	# sprawdzamy padding:
	beq $s6, $s2, padding		# jesli licznik pikseli w wierszu = width
	addi $t4, $t4, 1		# zwiekszenie licznika przerobionych pikseli
	addi $s6, $s6, 1		# zwiekszenie liczby pikseli 
	j loop
	
padding:
	li $s6, 1
	beq $t7, 0, padding0
	beq $t7, 1, padding1
	beq $t7, 2, padding2
	beq $t7, 3, padding3

padding0:		
	# przechodzimy o jeden bajt dalej - nic nie robimy
	b loop

padding1:
	# przechodzimy lacznie o 2 bajty dalej (1 paddingowy omijamy)
	addi $s1, $s1, 1
	b loop
	
padding2:
	# przechodzimy lacznie o 3 bajty dalej (2 paddingowe omijamy)
	addi $s1, $s1, 2
	b loop
	
padding3: 
	# przechodzimy lacznie o 4 bajty dalej (3 paddingowe omijamy)
	addi $s1, $s1, 3
	b loop

saveFile:
	# zapisujemy wynik pracy w pliku "out.bmp":
	la $a0, fileNameOut
	li $a1, 1
	li $a2, 0
	li $v0, 13		# najpierw otwieramy plik wynikowy
	syscall
	
	move $t0, $v0
	
	bltz $t0, fileExc
	lw $s0, size
	lw $s1, poczatek		# adres zaalokowanej pamieci
	
	move $a0, $t0			# teraz zapisujemy dane
	la $a1, ($s1)
	la $a2, ($s0)
	li $v0, 15
	syscall
	
	move $a0, $t0			# zamykamy plik i konczymy prace przechodzac do 'exit'
	li $v0, 16
	syscall
	
exit:	
	# zamkniecie programu:
	li $v0, 10
	syscall

fileExc:
	la $a0, msgFileExc
	li $v0, 4
	syscall
