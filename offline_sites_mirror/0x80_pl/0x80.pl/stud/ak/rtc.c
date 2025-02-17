/*
	Odczyt pamieci CMOS, interpretacja danych RTC
	Wojciech Mula, 22.03.2004
*/
#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <conio.h>

typedef unsigned char byte;

byte read_CMOS_byte(byte num) {
 num = num & 0x7f;           /* 6 bitow -- zakres 0..127 */
 outportb(0x70, num | 0x80); /* 7 bity -- wlaczenie NMI */
 return inportb(0x71);
}

byte bcd2num(byte b) {
 return (b & 0x0f) + 10*(b>>4);
}

void print_RTC_time() {
 static char* weekday[7] = {
  "niedziela", "poniedzialek",
  "wtorek", "sroda", "czwartek",
  "piatek", "sobota"};

 byte status_B;
 byte ampm, pm;
 byte bcd;
 byte s,m,h;
 byte D,M,Yy,Yc,W;
 unsigned int Y;

 /* 7 bit ustawiony - dane w CMOS sa uaktualniane; czekaj */
 while (read_CMOS_byte(0xa) & 0x80 == 0x80);

 status_B = read_CMOS_byte(0xb);
 ampm = ((status_B & 0x2) == 0); /* 1 bit: 0-am/pm; 1-24h */
 bcd  = ((status_B & 0x4) == 0); /* 2 bit: 0-format bcd; 1-format binarny */

 s  = read_CMOS_byte(0x00); /* sekundy     */
 m  = read_CMOS_byte(0x02); /* minuty      */
 h  = read_CMOS_byte(0x04); /* godziny     */
 D  = read_CMOS_byte(0x07); /* dzien mies. */
 M  = read_CMOS_byte(0x08); /* miesiac     */
 Yy = read_CMOS_byte(0x09); /* dwie ostatnie cyfry roku */
 Yc = read_CMOS_byte(0x32); /* wiek (dwie starsze cyfry roku; zawsze BCD */
 W  = read_CMOS_byte(0x06)-1; /* 1-niedziela itd. */

 if (bcd) {
  s=bcd2num(s); m=bcd2num(m);
  M=bcd2num(M); D=bcd2num(D); Yc=bcd2num(Yc); Yy=bcd2num(Yy);
  Y = 100*Yc + Yy;

  if (h & 0xf0 >= 0x80) {
	h -= 0x80;
	h  = bcd2num(h) | 0x80;
  }
  else
	h = bcd2num(h);
 }


 puts(read_CMOS_byte(0x0d) & 0x80 ? "Bataria OK" : "Bateria wyczerpana");

 if (ampm) {
  pm = h & 0x80 == 0x80;
  h  = h & 0x8f;

  printf("%s, %d:%02d:%02d %s, %d.%02d.%4d\n",
	 weekday[W],
	 h, m, s, pm ? "PM" : "AM",
	 D, M, Y);
 }
 else
  printf("%s, %d:%02d:%02d, %d.%02d.%4d\n", weekday[W], h, m, s, D, M, Y);
}

int main()
{
	clrscr();
	print_RTC_time();
	return 0;
}
