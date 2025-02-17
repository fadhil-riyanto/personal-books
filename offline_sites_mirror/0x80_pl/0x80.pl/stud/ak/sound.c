/*
	Programowanie glosniczka
	Wojciech Mula, 23.03.2004
*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <dos.h>
#include <conio.h>

typedef unsigned char byte;

void speaker_on() {
 byte b;
 b  = inportb(0x61);
 b |= 0x03;       /* ustaw dwa najmlodsze bity
		     bit 1 -- wlacza/wylacza generator
		     bit 0 -- przylacza wyj. generatora 2 do glosniczka
		  */
 outport(0x61, b);
}

void speaker_off() {
 byte b;
 b  = inportb(0x61);
 b &= ~0x1;
 outportb(0x61, b);
}

void set_div(unsigned int div) {
/*
10 11 x11 0 = 10110110b = 0xC6
 |  |  |  |
 |  |  |  +-- 0 -- licznik binarny
 |  |  |      1 -- licznik BCD (4 dekady -- 0..9999)
 |  |  |                        
 |  |  |      000 -- OUT = ________ N cykli_|~~~~~~~~~~~
 |  |  |      001 -- OUT = ~~~~~|___________|~~~~~~~~~~~
 |  |  |      x10 -- gen. impulsow szpilkowych o okresie N*T
 |  |  +----- x11 -- gen. fali prostokatnej o wypelnieniu 1/2, okres j.w.
 |  |         100 -- gen. impulsu po czasie N*T; odliczanie zaczyna sie 
 |  |                po wpisaniu informacji do rejestrow licznika, stad 
 |  |                mowi sie o *programowaym* wyzwalaniu generatora
 |  |	      101 -- j.w., ale wyzwalania sprzetowe
 |  |
 |  |         00 -- zatrzasnij wynik
 |  |         01 -- zapis/odczyt mlodszego bajtu
 |  |         10 -- zapis/odczyt starszego bajtu
 |  +-------- 11 -- zapis/odczyt 16 bitow (najpierw mlodszy bajt,
 |                  potem starszy)
 |
 |            00 -- licznik nr 0 (zegarek)
 |	      01 -- licznik nr 1 (odswiezanie DRAM)
 +----------- 10 -- licznik nr 2 (speaker)
*/
/*
porty
	0x40 -- port danych licznika 0
	0x41 -- ... licznika 1
	0x42 -- ... licznika 2
	0x43 -- rejestr kontrolny
*/
 outportb(0x43, 0xc6);
 outportb(0x42, (div>>0) & 0xff);
 outportb(0x42, (div>>8) & 0xff);
}


int main()
{
#define FREQ 1191380.0 /* czestotliwosc podstawowa (w Hz) */
#define MAX_FREQ (FREQ/1)
#define MIN_FREQ (FREQ/65536)
 
 float freq;
 unsigned int div;

 printf("Podaj czestotliwosc (w Hz): ");
 scanf("%f", &freq);
 if (freq < MIN_FREQ || freq > MAX_FREQ)
 	freq = 1000;

 speaker_on();

 div = floor(FREQ/freq);
 set_div(div);
 
 puts("Nacisnij dowolny klawisz...");
 getch();
 
 speaker_off();
 return 0;
}
