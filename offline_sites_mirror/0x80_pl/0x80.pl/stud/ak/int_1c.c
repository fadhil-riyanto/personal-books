/* 
	Przerwanie zegarowe; stoper
	Wojciech Mula, 16.04.2004
*/

/* POP == Procedura Obslugi Przerwania */

#include <dos.h>
#include <conio.h>
#include <values.h>
#include <stdio.h>

unsigned int counter;       /* licznik stopera */
unsigned char overflow = 0; /* przepelnienie stopera */
unsigned char enabled  = 0; /* stoper wlaczony */

void interrupt (*prevhandler)(); /* adres do poprzedniej POP */

void interrupt inthandler() {    /* nasza POP */
 if (enabled) {           /* jesli stoper wlaczony */
  if (counter == MAXINT)  /* sprawdz czy nie nastapilo przepelnienie */
   overflow = 1;      /* jesli tak ustaw odpowiedni znacznik */
  else
   counter++;         /* w przeciwnym razie normalnie zliczaj */
 }

 prevhandler();      /* wywolanie poprzedniej POP */
}

void menu() {
 puts("S - wlaczenie/wylaczenie stopera");
 puts("K - koniec programu");
}

int main() {
 prevhandler = getvect(0x1c); /* zapamietanie adresu poprzedniej POP */
 setvect(0x1c, inthandler);   /* ustawienie naszej POP */

 menu();
 while (1)
 {
  if (overflow)     /* jesli nastapilo przekrocznie
          zakresu stopera */
     {
      enabled  = 0; /* wylacz go */
      overflow = 0; /* i poinformuj uzytownika */
      puts("Nastapilo przepelnienie licznika!");
      menu();
     }

  if (kbhit())
      switch (getch()) {
       case 0: getch(); break; /* klawisz rozszerzony */

       case 'K': /* koniec programu */
       case 'k': goto end;

       case 'S': /* wl/wyl zliczania */
       case 's': if (enabled) /* wylacz */
     {
      printf("koniec; odmierzono czas %f s (%d cykli).\n", 
              (counter*55.5)/1000.0, counter);
      enabled = 0;
      menu();
     }
   else /* wlacz (enabled=0) */
     {
      counter = 0;
      enabled = 1;
      overflow= 0;
      printf("Rozpoczeto zliczanie...");
     }
   break;
  }
 }

end:
 setvect(0x1c, prevhandler); /* przywrocenie poprzedniej POP */
 return 0;                   /* zwroc do systemu ENOERROR */
}
