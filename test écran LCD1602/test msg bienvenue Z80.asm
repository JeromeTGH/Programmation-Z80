; ==========
; CONSTANTES
; ==========
ADRESSE_DEBUT_MEMOIRE_ROM   EQU $0000       ; La mémoire EEPROM de 32Ko s'étend de 0000 à 7FFF
ADRESSE_FIN_MEMOIRE_RAM     EQU $FFFF       ; La mémoire RAM de 32Ko s'étend de 8000 à FFFF

ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD    EQU 00100000b   ; Écran LCD (adresse de commande) -> 0x20
ADRESSE_POUR_ENVOYER_DES_DONNEES_AU_LCD     EQU 00100001b   ; Écran LCD (adresse pour données) -> 0x21

; ===========================================
; DEFINITION DE L'ADRESSE DU POINTEUR DE PILE
; ===========================================
LD SP, (ADRESSE_FIN_MEMOIRE_RAM)

; =======================================================
; INITIALISATION DE L'ECRAN LCD 1602 (contrôleur HD44780)
; =======================================================
INITIALISATION_DE_L_ECRAN_LCD:
    ; Function set (interface 8 bits, mode 2 lignes d'affichage, et font de petite taille)
        ; Bits 7/6/5 = 001 (="Function Set")
        ; Bit 4 = 1 (="Interface 8-bits")
        ; Bit 3 = 1 (="2 lignes d'affichage")
        ; Bit 2 = 0 (="Mode 5x8 points")
        ; Bits 1 et 0 = 0 (inutilisés, en fait)
    LD A, 00110000b
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    LD A, 00111000b
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    
    ; Control display (avec curseur bien visible, pour faire les essais)
        ; Bits 7/6/5/4/3 = 00001 (="Contrôle afficheur ON/OFF")
        ; Bit 2 = 1 ("Écran on/off" : affichage des caractères ou rien)
        ; Bit 1 = 0 ("Curseur on/off" : souligne-fixe ou rien)
        ; Bit 0 = 0 ("Clignotement curseur on/off" : alternances en pavé plein)
    LD A, 00001100b
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    
    ; Clear display (effaçage d'écran)
        ; Bits 7/6/5/4/3/2/1 à 0
        ; Et bit 0 à 1
    LD A, 00000001b
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    
    ; Entry set mode (déplacement curseur et affichage)
        ; Bits 7/6/5/4/3/2 = 000001
        ; Bit 1 = déplacement du curseur vers la droite, à chaque nouveau caractère
        ; Bit 0 = aucun décalage d'affichage, à chaque nouveau caractère
    LD A, 00000110b
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI
    
    
; ==========================
; AFFICHAGE D'UN MESSAGE (1)
; ==========================
LD HL, MESSAGE_LIGNE_1   ; Adresse du début du message

BOUCLE_MESSAGE_1:             ; Bouclage ici pour chaque caractère suivant
    LD A, (HL)              ; Charge le caractère suivant dans le registre A
    AND A                   ; Teste si on est à la fin du message (caractère "0") ; méthode détournée
    JP Z, DEPLACEMENT_SECONDE_LIGNE  ; Si on est à la fin du message, on saute plus loin

    OUT (ADRESSE_POUR_ENVOYER_DES_DONNEES_AU_LCD), A    ; Envoi du caractère sur l'écran LCD
    CALL DELAI              ; Petite pause pour ralentir la vitesse d'envoi des données à l'écran LCD
    
    INC HL                  ; Passage au caractère suivant (en déplaçant le pointeur sur le caractère suivant)
    JP BOUCLE_MESSAGE_1       ; Rebouclage, pour traitement du caractère suivant

; ===========================
; DÉPLACEMENT À LA 2ÈME LIGNE
; ===========================
DEPLACEMENT_SECONDE_LIGNE:
    ; Set DDRAM address (déplacement du curseur) ; DD=display data
        ; Bits 7 = 1
        ; Bit 6/5/4/3/2/1 = adresse en DDRAM	(ligne 1 : 00h à 27h ; ligne 2 : 40h à 67h)
		; ici, nous allons mettre le début lg 2, donc 40h, donc 01000000
    LD A, 11000000b
    OUT (ADRESSE_POUR_ENVOYER_UNE_COMMANDE_AU_LCD), A
    CALL DELAI

; ==========================
; AFFICHAGE D'UN MESSAGE (2)
; ==========================
LD HL, MESSAGE_LIGNE_2   ; Adresse du début du message

BOUCLE_MESSAGE_2:             ; Bouclage ici pour chaque caractère suivant
    LD A, (HL)              ; Charge le caractère suivant dans le registre A
    AND A                   ; Teste si on est à la fin du message (caractère "0") ; méthode détournée
    JP Z, FIN_DU_PROGRAMME  ; Si on est à la fin du 2nd message, on saute à la fin du programme

    OUT (ADRESSE_POUR_ENVOYER_DES_DONNEES_AU_LCD), A    ; Envoi du caractère sur l'écran LCD
    CALL DELAI              ; Petite pause pour ralentir la vitesse d'envoi des données à l'écran LCD
    
    INC HL                  ; Passage au caractère suivant (en déplaçant le pointeur sur le caractère suivant)
    JP BOUCLE_MESSAGE_2       ; Rebouclage, pour traitement du caractère suivant


; ================
; FIN DU PROGRAMME
; ================
FIN_DU_PROGRAMME:
    HALT                ; Arrêt du Z80

; =======================================================================
; DELAI (pour ralentir la vitesse d'envoi des instructions à l'écran LCD)
; =======================================================================
DELAI:
    
    LD C, 0x03              ; Initialisation d'un compteur primaire, dans le registre C
	; Test 1 : C=0x1F (trop lent)
	; Test 2 : C=0x01 (trop rapide)
	; Test 3 : C=0x0F (ça marche)
	; Test 4 : C=0x04 (ça marche encore)
	; Test 5 : C=0x02 (certaines lettres manquent)
	; ==> donc 0x03 pour registre C est "optimal"
    TEMPO_C:
        DEC C               ; On décrémente C
        JP Z, FIN_DELAI     ; Si C est égal à 0, alors c'est que la tempo est finie
        LD D, 0xFF              ; Initialisation d'un compteur secondaire, dans le registre D
        TEMPO_D:
            DEC D               ; On décrémente D
            JP Z, TEMPO_C       ; Si D est égal à 0, alors on reprend le décompte sur C
            JP TEMPO_D          ; sinon, on reboucle pour continuer à décrémenter D

FIN_DELAI:
    RET

; ==================
; DONNEES A AFFICHER
; ==================
MESSAGE_LIGNE_1:
    db "BONJOUR A TOUS !",0
MESSAGE_LIGNE_2:
    db "Et bienvenue ;)",0
