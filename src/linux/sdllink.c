/* Copyright (C) 1997-2002 ZSNES Team
* 
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later
* version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*
*/

#include "gblhdr.h"
#include "sw_draw.h"
#include "gl_draw.h"

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned long DWORD;
typedef Uint32 UINT32;
typedef long long _int64;
typedef long long LARGE_INTEGER;

typedef enum { FALSE = 0, TRUE = 1 } BOOL;
typedef enum vidstate_e { vid_null, vid_none, vid_soft, vid_gl } vidstate_t;

// bazz
unsigned char key_scancode_mac_adapter[] = {
0x1e, //   kVK_ANSI_A                    = 0x00, i need A in ZSNES world
0x1f, //   kVK_ANSI_S                    = 0x01,
0x20, //   kVK_ANSI_D                    = 0x02,
0x21, //   kVK_ANSI_F                    = 0x03,
0x23, //   kVK_ANSI_H                    = 0x04,
0x22, //   kVK_ANSI_G                    = 0x05,
0x2c, //   kVK_ANSI_Z                    = 0x06,
0x2d, //   kVK_ANSI_X                    = 0x07,
0x2e, //   kVK_ANSI_C                    = 0x08,
0x2f, //   kVK_ANSI_V                    = 0x09,

0x00, // junk filler

0x30, //   kVK_ANSI_B                    = 0x0B,
0x10, //   kVK_ANSI_Q                    = 0x0C,
0x11, //   kVK_ANSI_W                    = 0x0D,
0x12, //   kVK_ANSI_E                    = 0x0E,
0x13, //   kVK_ANSI_R                    = 0x0F,
0x15, //   kVK_ANSI_Y                    = 0x10,
0x14, //   kVK_ANSI_T                    = 0x11,
0x02, //   kVK_ANSI_1                    = 0x12,
0x03, //   kVK_ANSI_2                    = 0x13,
0x04, //   kVK_ANSI_3                    = 0x14,
0x05, //   kVK_ANSI_4                    = 0x15,
0x07, //   kVK_ANSI_6                    = 0x16,
0x06, //   kVK_ANSI_5                    = 0x17,
0x0d, //   kVK_ANSI_Equal                = 0x18,
0x0a, //   kVK_ANSI_9                    = 0x19,
0x08, //   kVK_ANSI_7                    = 0x1A,
0x0c, //   kVK_ANSI_Minus                = 0x1B,
0x09, //   kVK_ANSI_8                    = 0x1C,
0x0b, //   kVK_ANSI_0                    = 0x1D,
0x1b, //   kVK_ANSI_RightBracket         = 0x1E,
0x18, //   kVK_ANSI_O                    = 0x1F,
0x16, //   kVK_ANSI_U                    = 0x20,
0x1a, //   kVK_ANSI_LeftBracket          = 0x21,
0x17, //   kVK_ANSI_I                    = 0x22,
0x19, //   kVK_ANSI_P                    = 0x23,

0x1c, //   kVK_Return                    = 0x24,

0x26, //   kVK_ANSI_L                    = 0x25,
0x24, //   kVK_ANSI_J                    = 0x26,
0x28, //   kVK_ANSI_Quote                = 0x27,
0x25, //   kVK_ANSI_K                    = 0x28,
0x27, //   kVK_ANSI_Semicolon            = 0x29,
0x2b, //   kVK_ANSI_Backslash            = 0x2A,
0x33, //   kVK_ANSI_Comma                = 0x2B,
0x35, //   kVK_ANSI_Slash                = 0x2C,
0x31, //   kVK_ANSI_N                    = 0x2D,
0x32, //   kVK_ANSI_M                    = 0x2E,
0x34, //   kVK_ANSI_Period               = 0x2F,

0x0f, //   kVK_Tab                       = 0x30,
0x39, //   kVK_Space                     = 0x31,

0x29, // ????  kVK_ANSI_Grave                = 0x32,

0x0e, //   kVK_Delete                    = 0x33,
0x00, //                                     0x34
0x01, //   kVK_Escape                    = 0x35,

0x00, //                                     0x36
0x1d,    //   kVK_Command   i set to same as lCTRL oops ^_^                = 0x37,
0x2a,    //   kVK_Shift                     = 0x38,
0x3a,    //   kVK_CapsLock                  = 0x39,
0x38,    //   kVK_Option                    = 0x3A,
0x1d,    //   kVK_Control                   = 0x3B,
0x36,    //   kVK_RightShift                = 0x3C,
0x38,    //   kVK_RightOption               = 0x3D,
0x1d,    //   kVK_RightControl              = 0x3E,
0,    //   kVK_Function                  = 0x3F,
0,    //   kVK_F17                       = 0x40,

0x00, //   kVK_ANSI_KeypadDecimal        = 0x41,
0x00,
0x00, //   kVK_ANSI_KeypadMultiply       = 0x43,
0x00,
0x00, //   kVK_ANSI_KeypadPlus           = 0x45,
0x00,
0x00, //   kVK_ANSI_KeypadClear          = 0x47,
0x00, //   kVK_VolumeUp                  = 0x48,
0x00, //   kVK_VolumeDown                = 0x49,
0x00, //   kVK_Mute                      = 0x4A,
0x00, //   kVK_ANSI_KeypadDivide         = 0x4B,
0x00, //   kVK_ANSI_KeypadEnter          = 0x4C,
0,
0x00, //   kVK_ANSI_KeypadMinus          = 0x4E,
0x00, //   kVK_F18                       = 0x4F,
0x00, //   kVK_F19                       = 0x50,
0x00, //   kVK_ANSI_KeypadEquals         = 0x51,
0x00, //   kVK_ANSI_Keypad0              = 0x52,
0x00, //   kVK_ANSI_Keypad1              = 0x53,
0x00, //   kVK_ANSI_Keypad2              = 0x54,
0x00, //   kVK_ANSI_Keypad3              = 0x55,
0x00, //   kVK_ANSI_Keypad4              = 0x56,
0x00, //   kVK_ANSI_Keypad5              = 0x57,
0x00, //   kVK_ANSI_Keypad6              = 0x58,
0x00, //   kVK_ANSI_Keypad7              = 0x59,
0,    //   kVK_F20                       = 0x5A,
0x00, //   kVK_ANSI_Keypad8              = 0x5B,
0x00, //   kVK_ANSI_Keypad9              = 0x5C
0,0,0,
0x3f, //   kVK_F5                        = 0x60,
0x40, //   kVK_F6                        = 0x61,
0x41, //   kVK_F7                        = 0x62,
0x3d, //   kVK_F3                        = 0x63,
0x42, //   kVK_F8                        = 0x64,
0x43, //   kVK_F9                        = 0x65,
0,
0, //   kVK_F11                       = 0x67,
0,
0,//  kVK_F13                       = 0x69,
0,//  kVK_F16                       = 0x6A,
0,//  kVK_F14                       = 0x6B,
0,
0x44, //  kVK_F10                       = 0x6D,
0,
0,    //  kVK_F12                       = 0x6F,
0,
0,    //  kVK_F15                       = 0x71,
0,    //  kVK_Help                      = 0x72,
0,    //  kVK_Home                      = 0x73,
0,    //  kVK_PageUp                    = 0x74,
0,    //  kVK_ForwardDelete             = 0x75,
0x3e, //  kVK_F4                        = 0x76,
0,    //  kVK_End                       = 0x77,
0x3c, //  kVK_F2                        = 0x78,
0,    //  kVK_PageDown                  = 0x79,
0x3b, //  kVK_F1                        = 0x7A,
0x5c,    //  kVK_LeftArrow                 = 0x7B,
0x5e,    //  kVK_RightArrow                = 0x7C,
0x60,    //  kVK_DownArrow                 = 0x7D,
0x5a,    //  kVK_UpArrow                   = 0x7E
};


// SOUND RELATED VARIABLES
int SoundEnabled = 1;
BYTE PrevStereoSound;
DWORD PrevSoundQuality;
DWORD BufferLeftOver = 0;	/* should we clear these on sound reset? */
short Buffer[1800 * 2];

extern BYTE StereoSound;
extern DWORD SoundQuality;
extern int DSPBuffer[];

/* NETWORK RELATED VARIABLES */
extern int packettimeleft[256];
extern int PacketCounter;
extern int CounterA;
extern int CounterB;

/* VIDEO VARIABLES */
SDL_Surface *surface;
int SurfaceLocking = 0;
int SurfaceX, SurfaceY;
static DWORD WindowWidth = 256;
static DWORD WindowHeight = 224;
static DWORD FullScreen = 0;
static vidstate_t sdl_state = vid_null;
static int UseOpenGL = 0;
static const int BitDepth = 16;
DWORD FirstVid = 1;

extern BYTE GUIWFVID[];
extern unsigned char cvidmode;

/* JOYSTICK AND KEYBOARD INPUT */
SDL_Joystick *JoystickInput[5];
int shiftptr = 0;
DWORD numlockptr;

extern unsigned char pressed[];
extern int CurKeyPos;
extern int CurKeyReadPos;
extern int KeyBuffer[16];

/* MOUSE INPUT */
float MouseMinX = 0;
float MouseMaxX = 256;
float MouseMinY = 0;
float MouseMaxY = 223;
int MouseX, MouseY;
float MouseMoveX, MouseMoveY;
int MouseMove2X, MouseMove2Y;
Uint8 MouseButton;
float MouseXScale = 1.0;
float MouseYScale = 1.0;
DWORD LastUsedPos = 0;
DWORD CurMode = -1;

extern BYTE GUIOn2;
static BYTE IsActivated = 1;

/* TIMER VARIABLES/MACROS */
#define UPDATE_TICKS_GAME (1000.0/59.95)// milliseconds per world update
#define UPDATE_TICKS_GAMEPAL (20)	// milliseconds per world update
#define UPDATE_TICKS_GUI (1000.0/36.0)	// milliseconds per world update
#define UPDATE_TICKS_UDP (1000.0/60.0)	// milliseconds per world update

int T60HZEnabled = 0;
int T36HZEnabled = 0;
short SystemTimewHour;
short SystemTimewMinute;
short SystemTimewSecond;
Uint32 end, end2;
double start, start2;
double update_ticks_pc, update_ticks_pc2;

extern unsigned char romispal;

/* FUNCTION DECLARATIONS */
void clearwin (void);
void drawscreenwin(void);
void initwinvideo();
void ProcessKeyBuf(int scancode);
void LinuxExit(void);
void UpdateSound(void *userdata, Uint8 * stream, int len);

extern int GUI36hzcall(void);
extern int Game60hzcall(void);
extern void SoundProcess();
#ifdef __OPENGL__
extern void gl_clearwin(void);
#endif

static void adjustMouseXScale(void)
{
	MouseXScale = (MouseMaxX - MouseMinX) / ((float) WindowWidth);
}

static void adjustMouseYScale(void)
{
	MouseYScale = (MouseMaxY - MouseMinY) / ((float) WindowHeight);
}

int Main_Proc(void)
{
	int j;
	SDL_Event event;

	while (SDL_PollEvent(&event))
	{
		switch (event.type)
		{
			case SDL_ACTIVEEVENT:
				IsActivated = event.active.gain;
				break;
			case SDL_KEYDOWN:
				

				if (event.key.keysym.sym == SDLK_LSHIFT ||
				    event.key.keysym.sym == SDLK_RSHIFT)
					shiftptr = 1;
				if (event.key.keysym.mod & KMOD_NUM)
					numlockptr = 1;
				else
					numlockptr = 0;
				
				// the -8 stuff is  garbage.. need a pure mac scancode
				// to ZSnes scancode LUT
				/*if (event.key.keysym.scancode - 8 >= 0)
				{*/
					printf ("scancode = 0x%04x\n", event.key.keysym.scancode);
					//if (pressed[event.key.keysym.scancode - 8] != 2)
				if (event.key.keysym.sym == SDLK_LSHIFT)
					pressed[0x2a]=1;
				else if (event.key.keysym.sym == SDLK_RSHIFT)
					pressed[0x36]=1;
				else if (event.key.keysym.sym == SDLK_LALT)
					pressed[0x38]=1;
				else if (event.key.keysym.sym == SDLK_RALT)
					pressed[0x1c2]=1; // how to process e038??
				else if (event.key.keysym.sym == SDLK_LCTRL)
					pressed[0x1d]=1;
				else if (event.key.keysym.sym == SDLK_RCTRL)
					pressed[0x100 + 0x1d]=1; // not on macbookpro bt fuck it
				else if (event.key.keysym.sym == SDLK_LMETA)
					pressed[0x1c0]=1; 
				else if (event.key.keysym.sym == SDLK_RMETA)
					pressed[0x1c1]=1; 
				else if (event.key.keysym.sym == SDLK_CAPSLOCK)
					pressed[0x3a]=1; 
				else
					pressed[key_scancode_mac_adapter[event.key.keysym.scancode]] = 1;
					ProcessKeyBuf(event.key.keysym.sym);
				//}
				break;
//db 'LCM','RCM','RAL','   ','   ','   ','   ','   '  ; 1c0h
			case SDL_KEYUP:
				if (event.key.keysym.sym == SDLK_LSHIFT ||
				    event.key.keysym.sym == SDLK_RSHIFT)
					shiftptr = 0;
				//if (event.key.keysym.scancode - 8 >= 0)
				if (event.key.keysym.sym == SDLK_LSHIFT)
					pressed[0x2a]=0;
				else if (event.key.keysym.sym == SDLK_RSHIFT)
					pressed[0x36]=0;
				else if (event.key.keysym.sym == SDLK_LALT)
					pressed[0x38]=0;
				else if (event.key.keysym.sym == SDLK_RALT)
					pressed[0x1c2]=0; // how to process e038??
				else if (event.key.keysym.sym == SDLK_LCTRL)
					pressed[0x1d]=0;
				else if (event.key.keysym.sym == SDLK_RCTRL)
					pressed[0x100 + 0x1d]=0; // not on macbookpro bt fuck it
				else if (event.key.keysym.sym == SDLK_LMETA)
					pressed[0x1c0]=0; 
				else if (event.key.keysym.sym == SDLK_RMETA)
					pressed[0x1c1]=0; 
				else if (event.key.keysym.sym == SDLK_CAPSLOCK)
					pressed[0x3a]=0;  
				else
					pressed[key_scancode_mac_adapter[event.key.keysym.scancode]] = 0;
				break;

			case SDL_MOUSEMOTION:
				if (FullScreen)
				{
					MouseX += event.motion.xrel;
					MouseY += event.motion.yrel;
				}
				else
				{
					MouseX = ((int) ((float) event.motion.x) * MouseXScale);
					MouseY = ((int) ((float) event.motion.y) * MouseYScale);
				}

				if (MouseX < MouseMinX) MouseX = MouseMinX;
				if (MouseX > MouseMaxX) MouseX = MouseMaxX;
				if (MouseY < MouseMinY) MouseY = MouseMinY;
				if (MouseY > MouseMaxY) MouseY = MouseMaxY;
				break;

			case SDL_MOUSEBUTTONDOWN:
				/*
				   button 2 = enter (i.e. select)
				   button 4 = mouse wheel up (treat as "up" key)
				   button 5 = mouse wheel down (treat as "down" key)
				 */
				switch (event.button.button)
				{
					case 4:
						ProcessKeyBuf(SDLK_UP);
						break;
					case 5:
						ProcessKeyBuf(SDLK_DOWN);
						break;
					case 2:
						ProcessKeyBuf(SDLK_RETURN);
						// Yes, this is intentional - DDOI
					default:
						MouseButton = MouseButton | event.button.button;
						break;
				}

				break;

			case SDL_MOUSEBUTTONUP:
				MouseButton =
					MouseButton & ~event.button.button;
				break;

		    case SDL_JOYHATMOTION: // POV hats act as direction pad
			    if (event.jhat.hat == 0) // only support the first POV hat for now
			    {
				    switch (event.jhat.value)
				    {
				        case SDL_HAT_CENTERED:
						    pressed[0x100 + event.jhat.which * 32 + 0] = 0;
							pressed[0x100 + event.jhat.which * 32 + 1] = 0;
							pressed[0x100 + event.jhat.which * 32 + 2] = 0;
							pressed[0x100 + event.jhat.which * 32 + 3] = 0;
							break;
					    case SDL_HAT_UP:
						    pressed[0x100 + event.jhat.which * 32 + 3] = 1;
							pressed[0x100 + event.jhat.which * 32 + 2] = 0;
							break;
					    case SDL_HAT_RIGHTUP:
						    pressed[0x100 + event.jhat.which * 32 + 0] = 1;
							pressed[0x100 + event.jhat.which * 32 + 3] = 1;
							pressed[0x100 + event.jhat.which * 32 + 1] = 0;
							pressed[0x100 + event.jhat.which * 32 + 2] = 0;
							break;
					    case SDL_HAT_RIGHT:
						    pressed[0x100 + event.jhat.which * 32 + 0] = 1;
							pressed[0x100 + event.jhat.which * 32 + 1] = 0;
							break;
					    case SDL_HAT_RIGHTDOWN:
						    pressed[0x100 + event.jhat.which * 32 + 0] = 1;
							pressed[0x100 + event.jhat.which * 32 + 2] = 1;
							pressed[0x100 + event.jhat.which * 32 + 1] = 0;
							pressed[0x100 + event.jhat.which * 32 + 3] = 0;
							break;
					    case SDL_HAT_DOWN:
						    pressed[0x100 + event.jhat.which * 32 + 2] = 1;
							pressed[0x100 + event.jhat.which * 32 + 3] = 0;
							break;
					    case SDL_HAT_LEFTDOWN:
						    pressed[0x100 + event.jhat.which * 32 + 1] = 1;
							pressed[0x100 + event.jhat.which * 32 + 2] = 1;
							pressed[0x100 + event.jhat.which * 32 + 0] = 0;
							pressed[0x100 + event.jhat.which * 32 + 3] = 0;
							break;
					    case SDL_HAT_LEFT:
						    pressed[0x100 + event.jhat.which * 32 + 1] = 1;
							pressed[0x100 + event.jhat.which * 32 + 0] = 0;
							break;
					    case SDL_HAT_LEFTUP:
						    pressed[0x100 + event.jhat.which * 32 + 1] = 1;
							pressed[0x100 + event.jhat.which * 32 + 3] = 1;
							pressed[0x100 + event.jhat.which * 32 + 0] = 0;
							pressed[0x100 + event.jhat.which * 32 + 2] = 0;
							break;
					}
				}
				break;

			/*
			   joystick trackball code untested; change the test values
			   if the motion is too sensitive (or not sensitive enough);
			   only the first trackball is supported for now. we could get
			   really general here, but this may break the format of 'pressed'
			 */
			case SDL_JOYBALLMOTION:
			    //CurrentJoy = event.jball.which;
				if (event.jball.ball == 0)
				{
					if (event.jball.xrel < -100)
					{
						pressed[0x100 + event.jball.which * 32 + 6] = 0;
						pressed[0x100 +	event.jball.which * 32 + 7] = 1;
					}
					if (event.jball.xrel > 100)
					{
						pressed[0x100 + event.jball.which * 32 + 6] = 1;
						pressed[0x100 +	event.jball.which * 32 + 7] = 0;
					}
					if (event.jball.yrel < -100)
					{
						pressed[0x100 + event.jball.which * 32 + 8] = 0;
						pressed[0x100 + event.jball.which * 32 + 9] = 1;
					}
					if (event.jball.yrel > 100)
					{
						pressed[0x100 + event.jball.which * 32 + 8] = 1;
						pressed[0x100 + event.jball.which * 32 + 9] = 0;
				}
				}
				break;

			case SDL_JOYAXISMOTION:
				for (j = 0; j < 3; j++)
				{
					if (event.jaxis.axis == j)
					{
						if (event.jaxis.value < -16384)
						{
							pressed[0x100 +
								event.jaxis.which *	32 + 2 * j + 1] = 1;
							pressed[0x100 +
								event.jaxis.which * 32 + 2 * j + 0] = 0;
						}
						else if (event.jaxis.value > 16384)
						{
							pressed[0x100 +
								event.jaxis.which * 32 + 2 * j + 0] = 1;
							pressed[0x100 +
								event.jaxis.which * 32 + 2 * j + 1] = 0;
						}
						else
						{
							pressed[0x100 +
								event.jaxis.which * 32 + 2 * j + 0] = 0;
							pressed[0x100 +
								event.jaxis.which * 32 + 2 * j + 1] = 0;
						}
					}
				}
				break;

			case SDL_JOYBUTTONDOWN:
				pressed[0x100 + event.jbutton.which * 32 + 16 +
					event.jbutton.button] = 1;
				break;

			case SDL_JOYBUTTONUP:
				pressed[0x100 + event.jbutton.which * 32 + 16 +
					event.jbutton.button] = 0;
				break;
			case SDL_QUIT:
				LinuxExit();
				break;
#ifdef __OPENGL__
			case SDL_VIDEORESIZE:
				if(cvidmode != 16) {
				    surface = SDL_SetVideoMode(WindowWidth, WindowHeight,
					    BitDepth, surface->flags & ~SDL_RESIZABLE);
					adjustMouseXScale();
					adjustMouseYScale();
				    break;
				}
				WindowWidth = SurfaceX = event.resize.w;
				WindowHeight = SurfaceY = event.resize.h;
				surface = SDL_SetVideoMode(WindowWidth,
				    WindowHeight, BitDepth, surface->flags);
				adjustMouseXScale();
				adjustMouseYScale();
				glViewport(0,0, WindowWidth, WindowHeight);
				glFlush();
				gl_clearwin();
				break;
#endif
			default:
				break;
		}
	}

	return TRUE;
}

void ProcessKeyBuf(int scancode)
{
	int accept = 0;
	int vkeyval = 0;

	if (((scancode >= 'A') && (scancode <= 'Z')) ||
	    ((scancode >= 'a') && (scancode <= 'z')) ||
	    (scancode == SDLK_ESCAPE) || (scancode == SDLK_SPACE) ||
	    (scancode == SDLK_BACKSPACE) || (scancode == SDLK_RETURN) ||
	    (scancode == SDLK_TAB)) /*||
	    (scancode == SDLK_LMETA) || (scancode == SDLK_RMETA) || 
	    (scancode == SDLK_LCTRL) || (scancode == SDLK_RCTRL) || 
	    (scancode == SDLK_LALT) || (scancode == SDLK_RALT))*/
	{
		accept = 1;
		vkeyval = scancode;
	}
	if ((scancode >= '0') && (scancode <= '9'))
	{
		accept = 1;
		vkeyval = scancode;
		if (shiftptr)
		{
			switch (scancode)
			{
				case '1': vkeyval = '!'; break;
				case '2': vkeyval = '@'; break;
				case '3': vkeyval = '#'; break;
				case '4': vkeyval = '$'; break;
				case '5': vkeyval = '%'; break;
				case '6': vkeyval = '^'; break;
				case '7': vkeyval = '&'; break;
				case '8': vkeyval = '*'; break;
				case '9': vkeyval = '('; break;
				case '0': vkeyval = ')'; break;
			}
		}
	}
	if ((scancode >= SDLK_KP0) && (scancode <= SDLK_KP9))
	{
		if (numlockptr)
		{
			accept = 1;
			vkeyval = scancode - SDLK_KP0 + '0';
		}
		else
		{

			switch (scancode)
			{
				case SDLK_KP9: vkeyval = 256 + 73; accept = 1; break;
				case SDLK_KP8: vkeyval = 256 + 72; accept = 1; break;
				case SDLK_KP7: vkeyval = 256 + 71; accept = 1; break;
				case SDLK_KP6: vkeyval = 256 + 77; accept = 1; break;
				case SDLK_KP5: vkeyval = 256 + 76; accept = 1; break;
				case SDLK_KP4: vkeyval = 256 + 75; accept = 1; break;
				case SDLK_KP3: vkeyval = 256 + 81; accept = 1; break;
				case SDLK_KP2: vkeyval = 256 + 80; accept = 1; break;
				case SDLK_KP1: vkeyval = 256 + 79; accept = 1; break;
			}
		}		// end no-numlock
	}			// end testing of keypad
	if (!shiftptr)
	{
		switch (scancode)
		{
			case SDLK_MINUS:        vkeyval = '-'; accept = 1; break;
			case SDLK_EQUALS:       vkeyval = '='; accept = 1; break;
			case SDLK_LEFTBRACKET:  vkeyval = '['; accept = 1; break;
			case SDLK_RIGHTBRACKET: vkeyval = ']'; accept = 1; break;
			case SDLK_SEMICOLON:    vkeyval = ';'; accept = 1; break;
			case SDLK_COMMA:        vkeyval = ','; accept = 1; break;
			case SDLK_PERIOD:       vkeyval = '.'; accept = 1; break;
			case SDLK_SLASH:        vkeyval = '/'; accept = 1; break;
			case SDLK_QUOTE:        vkeyval = '`'; accept = 1; break;
		}
	}
	else
	{
		switch (scancode)
		{
			case SDLK_MINUS:        vkeyval = '_'; accept = 1; break;
			case SDLK_EQUALS:       vkeyval = '+'; accept = 1; break;
			case SDLK_LEFTBRACKET:  vkeyval = '{'; accept = 1; break;
			case SDLK_RIGHTBRACKET: vkeyval = '}'; accept = 1; break;
			case SDLK_SEMICOLON:    vkeyval = ':'; accept = 1; break;
			case SDLK_QUOTE:        vkeyval = '"'; accept = 1; break;
			case SDLK_COMMA:        vkeyval = '<'; accept = 1; break;
			case SDLK_PERIOD:       vkeyval = '>'; accept = 1; break;
			case SDLK_SLASH:        vkeyval = '?'; accept = 1; break;
			case SDLK_BACKQUOTE:    vkeyval = '~'; accept = 1; break;
			case SDLK_BACKSLASH:    vkeyval = '|'; accept = 1; break;
		}
	}
	switch (scancode)
	{
		case SDLK_PAGEUP:      vkeyval = 256 + 73; accept = 1; break;
		case SDLK_UP:          vkeyval = 256 + 72; accept = 1; break;
		case SDLK_HOME:        vkeyval = 256 + 71; accept = 1; break;
		case SDLK_RIGHT:       vkeyval = 256 + 77; accept = 1; break;
		case SDLK_LEFT:        vkeyval = 256 + 75; accept = 1; break;
		case SDLK_PAGEDOWN:    vkeyval = 256 + 81; accept = 1; break;
		case SDLK_DOWN:        vkeyval = 256 + 80; accept = 1; break;
		case SDLK_END:         vkeyval = 256 + 79; accept = 1; break;
		case SDLK_KP_PLUS:     vkeyval = '+'; accept = 1; break;
		case SDLK_KP_MINUS:    vkeyval = '-'; accept = 1; break;
		case SDLK_KP_MULTIPLY: vkeyval = '*'; accept = 1; break;
		case SDLK_KP_DIVIDE:   vkeyval = '/'; accept = 1; break;
		case SDLK_KP_PERIOD:   vkeyval = '.'; accept = 1; break;
	}

	if (accept)
	{
		KeyBuffer[CurKeyPos] = vkeyval;
		CurKeyPos++;
		if (CurKeyPos == 16)
			CurKeyPos = 0;
	}
}

int InitSound(void)
{
	SDL_AudioSpec wanted;
	const int samptab[7] = { 1, 1, 2, 4, 2, 4, 4 };
	const int freqtab[7] = { 8000, 11025, 22050, 44100, 16000, 32000, 48000 };

	SDL_CloseAudio();

	if (!SoundEnabled)
	{
		return FALSE;
	}

	PrevSoundQuality = SoundQuality;
	PrevStereoSound = StereoSound;

	if (SoundQuality > 6)
		SoundQuality = 1;
	wanted.freq = freqtab[SoundQuality];

	if (StereoSound)
	{
		wanted.channels = 2;
	}
	else
	{
		wanted.channels = 1;
	}

	wanted.samples = samptab[SoundQuality] * 128 * wanted.channels;
	wanted.format = AUDIO_S16LSB;
	wanted.userdata = NULL;
	wanted.callback = UpdateSound;

	if (SDL_OpenAudio(&wanted, NULL) < 0)
	{
		fprintf(stderr, "Sound init failed!\n");
		fprintf(stderr, "freq: %d, channels: %d, samples: %d\n",
			wanted.freq, wanted.channels, wanted.samples);
		SoundEnabled = 0;
		return FALSE;
	}
	SDL_PauseAudio(0);

	return TRUE;
}

int ReInitSound(void)
{
	return InitSound();
}

BOOL InitJoystickInput(void)
{
	int i, max_num_joysticks;

	for (i = 0; i < 5; i++)
		JoystickInput[i] = NULL;

	// If it is possible to use SDL_NumJoysticks
	// before initialising SDL_INIT_JOYSTICK then
	// this call can be replaced with SDL_InitSubSystem
	SDL_InitSubSystem (SDL_INIT_JOYSTICK);
	max_num_joysticks = SDL_NumJoysticks();
	if (!max_num_joysticks)
	{
		printf("ZSNES could not find any joysticks.\n");
		SDL_QuitSubSystem(SDL_INIT_JOYSTICK);
		return FALSE;
	}
	SDL_JoystickEventState(SDL_ENABLE);

	if (max_num_joysticks > 5) max_num_joysticks = 5;
	for (i = 0; i < max_num_joysticks; i++)
	{
		JoystickInput[i] = SDL_JoystickOpen(i);
		printf("Joystick %i (%i Buttons): %s\n", i,
		       SDL_JoystickNumButtons(JoystickInput[i]),
		       SDL_JoystickName(i));
	}

	return TRUE;
}

BOOL InitInput()
{
	InitJoystickInput();
	return TRUE;
}

int saybitdepth()
{
  int MyBitsPerPixel;
  const SDL_VideoInfo *info;
  SDL_Init(SDL_INIT_VIDEO);
  info = SDL_GetVideoInfo();
  MyBitsPerPixel = info->vfmt->BitsPerPixel;
  switch (MyBitsPerPixel)
    {
    case 0: printf("Cannot detect bitdepth. On fbcon and svgalib this is normal.\nTrying to force 16 bpp.\n\n"); break;
    case 16: break;
    default: printf("You are running in %d bpp, but ZSNES is forcing 16 bpp.\nYou may experience poor performance and/or crashing.\n\n", MyBitsPerPixel); break;
    }
  return 0;
}

int startgame(void)
{
	int status;

	if (sdl_state != vid_null)
	{
		if (SDL_Init(SDL_INIT_AUDIO | SDL_INIT_TIMER |
	        SDL_INIT_VIDEO) < 0)
		{
			fprintf(stderr, "Could not initialize SDL: %s", SDL_GetError());
			return FALSE;
		}
		sdl_state = vid_none;
	}

	if (sdl_state == vid_soft) sw_end();
#ifdef __OPENGL__
	else if (sdl_state == vid_gl) gl_end();
	saybitdepth();
	if (UseOpenGL)
	{
		status = gl_start(WindowWidth, WindowHeight, BitDepth, FullScreen);
	}
	else
#endif
	{
		status = sw_start(WindowWidth, WindowHeight, BitDepth, FullScreen);
	}

	if (!status) return FALSE;
	sdl_state = (UseOpenGL ? vid_gl : vid_soft);
	return TRUE;
}

void LinuxExit(void)
{
	if (sdl_state != vid_null)
	{
		SDL_WM_GrabInput(SDL_GRAB_OFF);	// probably redundant
		SDL_Quit();
	}
	exit(0);
}

void endgame()
{
	LinuxExit();
}


void Start60HZ(void)
{
	update_ticks_pc2 = UPDATE_TICKS_UDP;
	if (romispal == 1)
	{
		update_ticks_pc = UPDATE_TICKS_GAMEPAL;
	}
	else
	{
		update_ticks_pc = UPDATE_TICKS_GAME;
	}

	start = SDL_GetTicks();
	start2 = SDL_GetTicks();
	T36HZEnabled = 0;
	T60HZEnabled = 1;
}

void Stop60HZ(void)
{
	T60HZEnabled = 0;
}

void Start36HZ(void)
{
	update_ticks_pc2 = UPDATE_TICKS_UDP;
	update_ticks_pc = UPDATE_TICKS_GUI;

	start = SDL_GetTicks();
	start2 = SDL_GetTicks();
	T60HZEnabled = 0;
	T36HZEnabled = 1;
}

void Stop36HZ(void)
{
	T36HZEnabled = 0;
}

void initwinvideo(void)
{
	DWORD newmode = 0;

	if (CurMode != cvidmode)
	{
		CurMode = cvidmode;
		newmode = 1;
		WindowWidth = 256;
		WindowHeight = 224;

		FullScreen = GUIWFVID[cvidmode];
#ifdef __OPENGL__
		UseOpenGL = 0;
		if (cvidmode > 3)
		   UseOpenGL = 1;
#else
		if (cvidmode > 3)
		  cvidmode = 2; // set it to the default 512x448 W
#endif

		switch (cvidmode)
		{
			//case 0:
			default:
				WindowWidth = 256;
				WindowHeight = 224;
				break;
			case 1:
				WindowWidth = 320;
				WindowHeight = 240;
				break;
			case 2:
			case 5:
			case 13:
				WindowWidth = 512;
				WindowHeight = 448;
				break;
			case 3:
			case 6:
			case 16:
				WindowWidth = 640;
				WindowHeight = 480;
				break;
			case 7:
				WindowWidth = 640;
				WindowHeight = 576;
				break;
			case 8:
				WindowWidth = 768;
				WindowHeight = 672;
				break;
			case 9:
				WindowWidth = 896;
				WindowHeight = 784;
				break;
			case 10:
				WindowWidth = 1024;
				WindowHeight = 896;
				break;
			case 11:
			case 14:
				WindowWidth = 800;
				WindowHeight = 600;
				break;
			case 12:
			case 15:
				WindowWidth = 1024;
				WindowHeight = 768;
				break;
		}
		adjustMouseXScale();
		adjustMouseYScale();
	}

	if (startgame() != TRUE)
	{
		/* Exit zsnes if SDL could not be initialized */
		if (sdl_state == vid_null)
			LinuxExit ();
		else
			return;
	}

	if (newmode == 1)
		clearwin();

	if (FirstVid == 1)
	{
		FirstVid = 0;

		InitSound();
		InitInput();
	}

	if (((PrevStereoSound != StereoSound)
	     || (PrevSoundQuality != SoundQuality)))
		ReInitSound();
}

void CheckTimers(void)
{
	int i;

	//QueryPerformanceCounter((LARGE_INTEGER*)&end2);
	end2 = SDL_GetTicks();

	while ((end2 - start2) >= update_ticks_pc2)
	{
		if (CounterA > 0)
			CounterA--;
		if (CounterB > 0)
			CounterB--;
		if (PacketCounter)
		{
			for (i = 0; i < 256; i++)
			{
				if (packettimeleft[i] > 0)
					packettimeleft[i]--;
			}
		}
		start2 += update_ticks_pc2;
	}

	if (T60HZEnabled)
{
		//QueryPerformanceCounter((LARGE_INTEGER*)&end);
		end = SDL_GetTicks();

		while ((end - start) >= update_ticks_pc)
		{
			/*
			   _asm{
			   pushad
			   call Game60hzcall
			   popad
			   }
			 */
			Game60hzcall();
			start += update_ticks_pc;
		}
	}

	if (T36HZEnabled)
	{
		//QueryPerformanceCounter((LARGE_INTEGER*)&end);
		end = SDL_GetTicks();

		while ((end - start) >= update_ticks_pc)
		{
			/*
			   _asm{
			   pushad
			   call GUI36hzcall
			   popad
			   }
			 */
			GUI36hzcall();
			start += update_ticks_pc;
		}
	}
}

void UpdateSound(void *userdata, Uint8 * stream, int len)
{
	const int SPCSize = 256;
	int DataNeeded;
	int i;
	Uint8 *ptr;

	len /= 2;		/* only 16bit here */

	ptr = stream;
	DataNeeded = len;

	/* take care of the things we left behind last time */
	if (BufferLeftOver)
	{
		DataNeeded -= BufferLeftOver;

		memcpy(ptr, &Buffer[BufferLeftOver],
		       (SPCSize - BufferLeftOver) * 2);

		ptr += (SPCSize - BufferLeftOver) * 2;
		BufferLeftOver = 0;
	}

	if (len & 255)
	{			/* we'll save the rest first */
		DataNeeded -= 256;
	}

	while (DataNeeded > 0)
	{
		SoundProcess();

		for (i = 0; i < SPCSize; i++)
		{
			if (T36HZEnabled)
			{
				Buffer[i] = 0;
			}
			else
			{
				if (DSPBuffer[i] > 32767)
					Buffer[i] = 32767;
				else if (DSPBuffer[i] < -32767)
					Buffer[i] = -32767;
				else
					Buffer[i] = DSPBuffer[i];
			}
		}

		memcpy(ptr, &Buffer[0], SPCSize * 2);
		ptr += SPCSize * 2;

		DataNeeded -= SPCSize;
	}

	if (DataNeeded)
	{
		DataNeeded += 256;
		BufferLeftOver = DataNeeded;

		SoundProcess();

		for (i = 0; i < SPCSize; i++)
		{
			if (T36HZEnabled)
			{
				Buffer[i] = 0;
			}
			else
			{
				if (DSPBuffer[i] > 32767)
					Buffer[i] = 32767;
				else if (DSPBuffer[i] < -32767)
					Buffer[i] = -32767;
				else
					Buffer[i] = DSPBuffer[i];
			}
		}

		memcpy(ptr, &Buffer[0], DataNeeded * 2);
	}
}

void UpdateVFrame(void)
{
	/* rcg06172001 get menu animations running correctly... */
	/*if (GUIOn2 == 1 && IsActivated == 0) SDL_WaitEvent(NULL);*/
	if (GUIOn2 == 1 && IsActivated == 0)
		SDL_Delay(100);  /* spare the CPU a little. */

	CheckTimers();
	Main_Proc();
}

void clearwin()
{
	/* If we're vid_null and we get here, there's a problem */
	/* elsewhere - DDOI */
	if (sdl_state == vid_none) return;

#ifdef __OPENGL__
	if (UseOpenGL)
		gl_clearwin();
	else
#endif
		sw_clearwin();
}

void drawscreenwin(void)
{
	/* Just in case - DDOI */
	if (sdl_state == vid_none) return;

#ifdef __OPENGL__
	if (UseOpenGL)
		gl_drawwin();
	else
#endif
		sw_drawwin();
}

int GetMouseX(void)
{
	return ((int) MouseX);
}
int GetMouseY(void)
{
	return ((int) MouseY);
}

int GetMouseMoveX(void)
{
	//   InputRead();
	//SDL_GetRelativeMouseState(&MouseMove2X, NULL);
	SDL_GetRelativeMouseState(&MouseMove2X, &MouseMove2Y);
	return (MouseMove2X);
}

int GetMouseMoveY(void)
{
	return (MouseMove2Y);
}
int GetMouseButton(void)
{
	return ((int) MouseButton);
}

void SetMouseMinX(int MinX)
{
	MouseMinX = MinX;
	adjustMouseXScale();
}
void SetMouseMaxX(int MaxX)
{
	MouseMaxX = MaxX;
	adjustMouseXScale();
}
void SetMouseMinY(int MinY)
{
	MouseMinY = MinY;
	adjustMouseYScale();
}
void SetMouseMaxY(int MaxY)
{
	MouseMaxY = MaxY;
	adjustMouseYScale();
}
void SetMouseX(int X)
{
	MouseX = X;
}
void SetMouseY(int Y)
{
	MouseY = Y;
}

void GetLocalTime()
{
	time_t current;
	struct tm *timeptr;

	time(&current);
	timeptr = localtime(&current);
	SystemTimewHour = timeptr->tm_hour;
	SystemTimewMinute = timeptr->tm_min;
	SystemTimewSecond = timeptr->tm_sec;
}
