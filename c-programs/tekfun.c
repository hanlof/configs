// A simple TEK4010/4014 Graphics Vector terminal - DEMO
// You need ie. TeraTerm or Xterm switched into TEK4010/14 Emulation
// The current vector's addressing is 1024x1024 (10bit)
//
// Loosely inspired by
// http://www.ne.jp/asahi/shared/o-family/ElecRoom/AVRMCOM/TEK4010/TEK4010gdisp.html
// and other related information found on the web
//
// Provided as-is, no warranties of any kind are provided :)
// by Pito 7/2017

#include <inttypes.h>
#include <unistd.h>
#include <stdio.h>

#include <math.h>

void Tekgin();
void Teksprite(char* sprite);
void Tekbox(uint16_t bx, uint16_t by, uint16_t tx, uint16_t ty);
void Tekcls();
void Tekcolor(uint8_t color);
void Tekgraph(uint8_t style);
void Tekfont(uint8_t fontsize);
void Tekpoint(uint16_t x, uint16_t y);
void Tekdot(uint16_t x, uint16_t y);
void Tekline(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2);
void Tekplot(uint16_t x1, uint16_t y1);
void Teklocate(uint16_t x1, uint16_t y1);
void Tekstyle(uint8_t style);
void Tekalpha();
void Tekstyleb(uint8_t style);

void loop() {

  // Draw some primitives on the screen for fun
  // Origin (0,0) is the left bottom corner, y| __x

  //uint32_t elapsed = micros();

  Tekcls();
  Tekcolor(2);
  Tekgraph(4);
  Tekpoint(100, 100);
  Tekpoint(200, 100);
  Tekpoint(200, 200);
  Tekpoint(100, 200);

  Tekcolor(3);
  for (uint32_t i = 300; i < 500; i = i + 10) {
    Tekline(i, 400, i, 600);
  }

  Tekstyle(0);

  Tekline(300, 300, 500, 500);
  Tekstyle(1);
  Tekline(600, 400, 200, 300);
  Tekstyleb(2);
  Tekcolor(7);
  Tekplot(10, 700);
  Tekplot(500, 30);
  Tekstyle(3);
  Tekline(400, 600, 100, 800);
  Tekcolor(4);
  Tekstyleb(4);
  Tekplot(300, 330);

  Tekalpha();

  Tekfont(1);
  Teklocate(700, 400);
  Tekcolor(6);
  printf("Hello World !!");

  Tekfont(2);
  Tekcolor(1);
  Teklocate(700, 300);
  printf("STM32duino !!");

  Tekfont(0);
  Tekcolor(2);
  Teklocate(500, 200);
  printf("THIS IS A TEST OF TEK4014 !!");

  Tekstyle(0);
  Tekcolor(1);
  Tekbox(300, 200, 600, 600);

  Tekcolor(2);
  Tekstyle(0);
  Tekdot(150, 150);

  uint32_t i;

  for (i = 0; i < 360; i++) {
    float q = i;
    q = 3.141592f * q / 180.0f;
    float r = cosf(q);
    q = sinf(q);
    q = q * 120.0f;
    q = q + 195.0f;
    r = r * 120.0f;
    r = r + 580.0f;
    Tekdot((uint16_t) r, (uint16_t) q);
  }

  Tekcolor(5);

  for (i = 0; i < 360; i++) {
    float q = i;
    q = 3.141592f * q / 180.0f;
    q = sinf(q);
    q = q * 150.0f;
    q = q + 195.0f;
    float r = i + 30.0f;
    Tekdot((uint16_t) r, (uint16_t) q);
  }

  uint32_t a = 450;
  for (i = 1; i < 34; i++) {
    Tekline(0, 450, 1000, a);
    a = a + 10;
  }

  Tekalpha();
  Teklocate(400, 100);

  //elapsed = micros() - elapsed;
  //Serial.print("Elapsed: ");
  //Serial.print(elapsed);
  //printf(" micros");

  usleep(50000);
}

// ********************************************************
// TEK4010/4014 basic 10bit commands library
// For details consult the TEK4010/4014 manual
// Pito 7/2017 for stm32duino
// ********************************************************

// Colors for print, plot, dot
#define black 0
#define red 1
#define green 2
#define yellow 3
#define blue 4
#define magenta 5
#define cyan 6
#define white 7

// Line styles
#define solid 0
#define dotted 1
#define dash_dotted 2
#define short_dashed 3
#define long_dashed 4

// Font sizes
#define large 0
#define normal 1
#define small 2
#define smallest 3

// Clear Tek screen
void Tekcls() {
  printf("%c", 0x1B);
  printf("%c", 0x0c);
//printf("%c", 0x0d);printf("%c", 0x0a);
}

// Select a color (0-7)
void Tekcolor(uint8_t color) {
	/*
  printf("%c", 0x1B);
  printf("%c", 0x5b);
  printf("%c", 0x33);
  printf("%c", 0x30 + color);
  printf("%c", 0x6d);
  */
  if (color > 8) return;
  if (color < 0) return;
  char * col[] = {
    "black",
    "red",
    "blue",
    "green",
    "white",
    "white",
    "white",
    "white"
  };

  printf("%c]15;%s%c", 0x1B, col[color], 0x07);
}

// Switch to graphical mode with a line style (0-4)
void Tekgraph(uint8_t style) {
  printf("%c", 0x1D);
  printf("%c", 0x1B);
  printf("%c", style | 0x60);
}

// Select a font size (0-3) for printing alphanumeric strings
// The actual font type has to be set in the Emulator
void Tekfont(uint8_t fontsize) {
  printf("%c", 0x1B);
  printf("%c", 0x38 + fontsize);
}

// Normal style lines (0-4)
void Tekstyle(uint8_t style) {
  printf("%c", 0x1B);
  printf("%c", 0x60 + style);
}

// Bold style lines (??)
void Tekstyleb(uint8_t style) {
  printf("%c", 0x1B);
  printf("%c", 0x68 + style);
}

// Switch to alphanumeric mode
void Tekalpha() {
  printf("%c", 0x1f);
}

// Draw a point as a small cross (??)
void Tekpoint(uint16_t x, uint16_t y) {
  printf("%c", 0x1C);  // FS
  printf("%c", 0x20 + ((y >> 5) & 0x1F));
  printf("%c", 0x60 + ((y) & 0x1F));
  printf("%c", 0x20 + ((x >> 5) & 0x1F));
  printf("%c", 0x40 + ((x) & 0x1F));
}

// Draw a single dot
void Tekdot(uint16_t x, uint16_t y) {
  printf("%c", 0x1D);  // GS
  printf("%c", 0x20 + ((y >> 5) & 0x1F));
  printf("%c", 0x60 + ((y) & 0x1F));
  printf("%c", 0x20 + ((x >> 5) & 0x1F));
  printf("%c", 0x40 + ((x) & 0x1F));
  printf("%c", 0x40 + ((x) & 0x1F));
}

// Draw a line from (x1, y1) to (x2, y2)
void Tekline(uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2) {
  printf("%c", 0x1D);  // GS
  printf("%c", 0x20 + ((y1 >> 5) & 0x1F));
  printf("%c", 0x60 + ((y1) & 0x1F));
  printf("%c", 0x20 + ((x1 >> 5) & 0x1F));
  printf("%c", 0x40 + ((x1) & 0x1F));
  printf("%c", 0x20 + ((y2 >> 5) & 0x1F));
  printf("%c", 0x60 + ((y2) & 0x1F));
  printf("%c", 0x20 + ((x2 >> 5) & 0x1F));
  printf("%c", 0x40 + ((x2) & 0x1F));
}

// Continue with drawing a line to (x1, y1)
void Tekplot(uint16_t x1, uint16_t y1) {
  printf("%c", 0x20 + ((y1 >> 5) & 0x1F));
  printf("%c", 0x60 + ((y1) & 0x1F));
  printf("%c", 0x20 + ((x1 >> 5) & 0x1F));
  printf("%c", 0x40 + ((x1) & 0x1F));
}

// Locate a point where to print a string
void Teklocate(uint16_t x1, uint16_t y1) {
  printf("%c", 0x1D);  // GS
  printf("%c", 0x20 + ((y1 >> 5) & 0x1F));
  printf("%c", 0x60 + ((y1) & 0x1F));
  printf("%c", 0x20 + ((x1 >> 5) & 0x1F));
  printf("%c", 0x40 + ((x1) & 0x1F));
  Tekalpha();
}

// Draw a box with left bottom corner at (bx, by) and top right corner at (tx, ty)
void Tekbox(uint16_t bx, uint16_t by, uint16_t tx, uint16_t ty) {
  Tekline(bx, by, tx, by);
  Tekplot(tx, ty);
  Tekplot(bx, ty);
  Tekplot(bx, by);
}

// Draw small sprites
void Teksprite(char* sprite) {
  printf("%c", 0x1E);
  printf("%s", sprite); 
}

// Go to the Graphics-IN mode
void Tekgin() {
  printf("%c", 0x1B);
  printf("%c", 0x1A);
}

void Tekinit()
{
  printf("%c", 0x1B);
  printf("[?38h");
}


void main(int argc, char * argv[])
{
	Tekinit();
	for(;;) loop();
}

