{$S-,R-,V-,I-,B-,F-,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                    OPCRT.PAS 1.30                     *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpCrt;
  {-Alternate CRT interface unit. Replaces Turbo's CRT unit.}

{$IFDEF OPWinTP}
  !! ERROR: This unit is not compatible with Windows applications !!
{$ENDIF}

  {FPC port: the screen is a cell buffer (FPC Video unit's VideoBuf, one word
   per cell: low byte = CP437 character, high byte = DOS attribute). The
   real-mode assembly (OPCRT.ASM etc.) has been re-implemented in Pascal in
   the implementation section. The Crt-patching "UseCrt" mode is gone.}

interface

  {low-level frame stuff}
const
  frTL = 0;
  frBL = 1;
  frTR = 2;
  frBR = 3;
  frTT = 4;
  frBB = 5;
  frLL = 6;
  frRR = 7;
type
  FrameCharType = frTL..frRR;
  FrameArray    = array[FrameCharType] of Char;
  CursorType    = (cuNormal, cuFat, cuBlock, cuHidden, cuUnknown);

const
  {video mode constants}
  BW40    = 0;
  CO40    = 1;
  C40     = CO40;
  BW80    = 2;
  CO80    = 3;
  C80     = CO80;
  Mono    = 7;
  Font8x8 = 256;

  {color constants}
  Black        = 0;
  Blue         = 1;
  Green        = 2;
  Cyan         = 3;
  Red          = 4;
  Magenta      = 5;
  Brown        = 6;
  LightGray    = 7;
  DarkGray     = 8;
  LightBlue    = 9;
  LightGreen   = 10;
  LightCyan    = 11;
  LightRed     = 12;
  LightMagenta = 13;
  Yellow       = 14;
  White        = 15;
  Blink        = 128;

  {special flag used by MapMono}
  AutoMapMono  = $FF;
const
  {Set to True to allow programs to run as background tasks under
   DesqView/TaskView. Must be set False for TSR's.}
  DetectMultitasking : Boolean = False;
  BiosScroll : Boolean = True; {False to use OPCRT routines for clean scrolling}
const
  FrameChars : FrameArray = #$D5#$D4#$B8#$BE#$CD#$CD#$B3#$B3;
const
  InsertCursor   : CursorType = cuFat;
  OvertypeCursor : CursorType = cuNormal;
  CtrlCharCursor : CursorType = cuBlock;
type
  DisplayType = (MonoHerc, CGA, MCGA, EGA, VGA, PGC);
  HercCardType = (HercNone, HercPlain, HercPlus, HercInColor);
  FlexAttrs = array[0..3] of Byte; {attributes for FlexWrite}

  {record used to save/restore window coordinates}
  WindowCoordinates =
    record
      XL, YL, XH, YH : Byte;
    end;

{from Turbo's CRT unit}

var
  CheckBreak : Boolean;      {enable Ctrl-Break checking}
  CheckEOF : Boolean;        {enable Ctrl-Z checking}
  DirectVideo : Boolean;     {write directly to screen?}
  CheckSnow : Boolean;       {True to prevent snow on CGA's}
  TextAttr : Byte;           {current video attribute}
  WindMin : Word;            {Window XLow and YLow: 0..24, 0..79 format}
  WindMax : Word;            {Window XHigh and YHigh: 0..24, 0..79 format}
  LastMode : Word;           {current video mode in low byte / 8x8 flag in high byte}
const
  CrtCheck : Boolean = True; {for internal use (unused in FPC port)}

{unique to Object Professional version}

var
  CtrlBreakFlag : Boolean;   {set to true when ^Break pressed}
  CurrentPage : Byte;        {current video page}
  CurrentMode : Byte absolute LastMode; {current video mode}
  ScreenWidth : Word;        {current width of screen}
  ScreenHeight : Word;       {current height of screen}
  CurrentDisplay : DisplayType; {currently selected display adapter}
  EnhancedDisplay : DisplayType; {meaningful only if set to MCGA, VGA, or EGA}
  WhichHerc : HercCardType;  {type of Hercules card installed}
  InTextMode : Boolean;      {set to false when in graphics mode}
  NormalAttr : Byte;         {attribute for NormVideo}
  VideoSegment : Word;       {legacy token only ($B800); see VideoBuffer}
  BufLen : Word;             {maximum length of string for Read/Ln}
  MultiTaskingOn : Boolean;  {needed to support DesqView, TaskView}
  OneMS : Word;              {loop count used for a 1 ms delay}
  SaveCtrlC : Boolean;       {was ^C checking on when program started?}
  {for backward compatibility}
  CurrentWidth : Word absolute ScreenWidth; {current width of display}
  CurrentHeight : Word;      {current height of display - 1}
var
  {hooks for virtual screens in OPWINDOW}
  VirtualSegment : Word;     {legacy token only; assigning it does NOT redirect
                              output in the FPC port -- set VirtualBuffer}
  VirtualWidth : Word;       {alternate width of display}
  VirtualHeight : Word;      {alternate height of display}

  {FPC port additions: pointer-based replacements for VideoSegment and
   VirtualSegment. All FastXXX/MoveScreen/SaveWindow/RestoreWindow routines
   read and write cells at VirtualBuffer (row-major, VirtualWidth words per
   row, word = Ord(Char) or (Attr shl 8)). The physical screen buffer is
   VideoBuffer; the screen is refreshed (see FlushScreen) only when
   VirtualBuffer = VideoBuffer.}
  VideoBuffer : Pointer;
  VirtualBuffer : Pointer;
const
  DisplayOverride : ShortInt = -1; {use to override auto-detection of displays}

  UseEnhancedKbd : Boolean = False; {use to activate enhanced keyboard calls}

  {background character used by ClrScr, ScrollWindowUp/Down; gets reset to ' '
   automatically}
  TextChar : Char = ' ';
  HercExceptionReg : Byte = $27;

  {------------- miscellaneous default colors, etc. --------------}
type
  ColorChoice = (UseDefault, ForceColor, ForceMono);
const
  DefColorChoice : ColorChoice = UseDefault;
type
  ColorSetPtr = ^ColorSet;   {!!.20}
  ColorSet =
    object
      TextColor, TextMono : Byte;             {ordinary text}
      CtrlColor, CtrlMono : Byte;             {control characters}
      FrameColor, FrameMono : Byte;           {window frames}
      HeaderColor, HeaderMono : Byte;         {window headers}
      ShadowColor, ShadowMono : Byte;         {window shadows}
      HighlightColor, HighlightMono : Byte;   {found text, etc.}
      PromptColor, PromptMono : Byte;         {prompts}
      SelPromptColor, SelPromptMono : Byte;   {selected prompts}
      ProPromptColor, ProPromptMono : Byte;   {protected prompts}
      FieldColor, FieldMono : Byte;           {fields}
      SelFieldColor, SelFieldMono : Byte;     {selected fields}
      ProFieldColor, ProFieldMono : Byte;     {protected fields}
      ScrollBarColor, ScrollBarMono : Byte;   {scroll bars}
      SliderColor, SliderMono : Byte;         {slider in scroll bars}
      HotSpotColor, HotSpotMono : Byte;       {hot spots in frame corners}
      BlockColor, BlockMono : Byte;           {marked blocks}
      MarkerColor, MarkerMono : Byte;         {text markers}
      DelimColor, DelimMono : Byte;           {delimiters}
      SelDelimColor, SelDelimMono : Byte;     {selected delimiters}
      ProDelimColor, ProDelimMono : Byte;     {protected delimiters}
      SelItemColor, SelItemMono : Byte;       {selected pick and menu items}
      ProItemColor, ProItemMono : Byte;       {protected pick and menu items}
      HighItemColor, HighItemMono : Byte;     {highlight chars in pick and menu}
      AltItemColor, AltItemMono : Byte;       {alternate pick items}
      AltSelItemColor, AltSelItemMono : Byte; {alternate selected pick items}
      FlexAHelpColor, FlexAHelpMono : Byte;   {help flex highlight for ^A}
      FlexBHelpColor, FlexBHelpMono : Byte;   {help flex highlight for ^B}
      FlexCHelpColor, FlexCHelpMono : Byte;   {help flex highlight for ^C}
      UnselXrefColor, UnselXrefMono : Byte;   {unselected help xref}
      SelXrefColor, SelXrefMono : Byte;       {selected help xref}
      MouseColor, MouseMono : Byte;           {mouse colors}

      procedure SetTextAttr(Color, Mono : Byte);
        {-Set attributes for ordinary text}
      procedure SetCtrlAttr(Color, Mono : Byte);
        {-Set attributes for control characters}
      procedure SetFrameAttr(Color, Mono : Byte);
        {-Set attributes for window frames}
      procedure SetHeaderAttr(Color, Mono : Byte);
        {-Set attributes for window headers}
      procedure SetShadowAttr(Color, Mono : Byte);
        {-Set attributes for window shadows}
      procedure SetHighlightAttr(Color, Mono : Byte);
        {-Set attributes used to highlight found text}
      procedure SetPromptAttr(Color, Mono : Byte);
        {-Set attributes for entry field prompts}
      procedure SetSelectedPromptAttr(Color, Mono : Byte);
        {-Set attributes for selected entry field prompts}
      procedure SetProtectedPromptAttr(Color, Mono : Byte);
        {-Set attributes for protected entry field prompts}
      procedure SetFieldAttr(Color, Mono : Byte);
        {-Set attributes for unselected entry fields}
      procedure SetSelectedFieldAttr(Color, Mono : Byte);
        {-Set attributes for selected entry field fields}
      procedure SetProtectedFieldAttr(Color, Mono : Byte);
        {-Set attributes for protected entry fields}
      procedure SetScrollBarAttr(Color, Mono : Byte);
        {-Set attributes for scroll bars}
      procedure SetSliderAttr(Color, Mono : Byte);
        {-Set attributes for sliders in scroll bars}
      procedure SetHotSpotAttr(Color, Mono : Byte);
        {-Sets attributes for mouse hot spots}
      procedure SetBlockAttr(Color, Mono : Byte);
        {-Set attributes for marked blocks}
      procedure SetMarkerAttr(Color, Mono : Byte);
        {-Set attributes for text markers}
      procedure SetDelimAttr(Color, Mono : Byte);
        {-Set attributes for unselected entry field delimiters}
      procedure SetSelectedDelimAttr(Color, Mono : Byte);
        {-Set attributes for selected entry field delimiters}
      procedure SetProtectedDelimAttr(Color, Mono : Byte);
        {-Set attributes for protected entry field delimiters}
      procedure SetSelectedItemAttr(Color, Mono : Byte);
        {-Set attributes for selected pick and menu items}
      procedure SetProtectedItemAttr(Color, Mono : Byte);
        {-Set attributes for protected pick and menu items}
      procedure SetHighlightItemAttr(Color, Mono : Byte);
        {-Set attributes for highlighted selection characters for menu items}
      procedure SetAltItemAttr(Color, Mono : Byte);          {!!.01}
        {-Set attributes for alternate pick items}
      procedure SetAltSelItemAttr(Color, Mono : Byte);       {!!.01}
        {-Set attributes for alternate selected pick items}
      procedure SetFlexAHelpAttr(Color, Mono : Byte);
        {-Set attributes for help text surrounded by ^A}
      procedure SetFlexBHelpAttr(Color, Mono : Byte);
        {-Set attributes for help text surrounded by ^B}
      procedure SetFlexCHelpAttr(Color, Mono : Byte);
        {-Set attributes for help text surrounded by ^C}
      procedure SetUnselXrefAttr(Color, Mono : Byte);
        {-Set attributes for unselected cross-references in help text}
      procedure SetSelXrefAttr(Color, Mono : Byte);
        {-Set attributes for selected cross-references in help text}
      procedure SetMouseAttr(Color, Mono : Byte);
        {-Set attributes for mouse cursor}
    end;

const
  DefaultPasswordChar = ^G;
  DefaultPadChar = ' ';
  DefaultColorSet : ColorSet = (
    TextColor       : $07; TextMono       : $07;
    CtrlColor       : $07; CtrlMono       : $07;
    FrameColor      : $0F; FrameMono      : $0F;
    HeaderColor     : $0F; HeaderMono     : $0F;
    ShadowColor     : $07; ShadowMono     : $07;
    HighlightColor  : $70; HighlightMono  : $70;
    PromptColor     : $07; PromptMono     : $07;
    SelPromptColor  : $07; SelPromptMono  : $07;
    ProPromptColor  : $07; ProPromptMono  : $07;
    FieldColor      : $0F; FieldMono      : $0F;
    SelFieldColor   : $70; SelFieldMono   : $70;
    ProFieldColor   : $07; ProFieldMono   : $07;
    ScrollBarColor  : $07; ScrollBarMono  : $07;
    SliderColor     : $07; SliderMono     : $07;
    HotSpotColor    : $70; HotSpotMono    : $07;

    BlockColor      : $0F; BlockMono      : $0F;
    MarkerColor     : $70; MarkerMono     : $70;
    DelimColor      : $0F; DelimMono      : $0F;
    SelDelimColor   : $70; SelDelimMono   : $70;
    ProDelimColor   : $07; ProDelimMono   : $07;
    SelItemColor    : $70; SelItemMono    : $70;
    ProItemColor    : $00; ProItemMono    : $01;
    HighItemColor   : $0F; HighItemMono   : $0F;
    AltItemColor    : $0F; AltItemMono    : $0F;
    AltSelItemColor : $70; AltSelItemMono : $70;
    FlexAHelpColor  : $0F; FlexAHelpMono  : $0F;
    FlexBHelpColor  : $01; FlexBHelpMono  : $01;
    FlexCHelpColor  : $70; FlexCHelpMono  : $70;
    UnselXrefColor  : $09; UnselXrefMono  : $09;
    SelXrefColor    : $70; SelXrefMono    : $70;
    MouseColor      : $4F; MouseMono      : $70
  );

  function MakeHiddenAttr(A : Byte) : Byte;
    {-Make foreground and background colors the same}

type
  ColorMapTable = array[0..255] of Byte;
const
  ColorMap : ColorMapTable = (
      {00   01   02   03   04   05   06   07   08   09   0A   0B   0C   0D   0E   0F}
 {00} $00, $01, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $0F, $0F,
 {10} $70, $01, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $0F, $0F,
 {20} $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70,
 {30} $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70,
 {40} $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70,
 {50} $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70,
 {60} $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70,
 {70} $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70, $70,
 {80} $80, $81, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $8F, $8F,
 {90} $F0, $81, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $8F, $8F,
 {A0} $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0,
 {B0} $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0,
 {C0} $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0,
 {D0} $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0,
 {E0} $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0,
 {F0} $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
     );

procedure TextMode(Mode : Word);
  {-Switch to/set text mode}

procedure Window(XLow, YLow, XHigh, YHigh : Byte);
  {-Set current window coordinates}

procedure ClrScr;
  {-Clear the current window}

procedure ClrEol;
  {-Clear the remainder of the current screen line}

procedure InsLine;
  {-Insert a new line at the position of the cursor}

procedure DelLine;
  {-Delete current screen line}

procedure GoToXY(X, Y : Byte);
  {-Move cursor to column X, row Y, relative to Window}

function WhereX : Byte;
  {-Return column coordinate of cursor, relative to Window}

function WhereY : Byte;
  {-Return row coordinate of cursor, relative to Window}

procedure TextColor(Color : Byte);
  {-Set foreground color for screen writes}

procedure TextBackground(Color : Byte);
  {-Set background color for screen writes}

procedure LowVideo;
  {-Select low intensity}

procedure HighVideo;
  {-Select high intensity}

procedure NormVideo;
  {-Select video attribute used at start of program}

function KeyPressed : Boolean;
  {-Return true if a key has been pressed}

function ReadKey : Char;
  {-Read a character from the keyboard}

procedure AssignCrt(var F : Text);
  {-Routes input and output through our routines}

procedure Delay(MS : Word);
  {-Delay for MS milliseconds}

procedure Sound(Hz : Word);
  {-Turn on the sound at the designated frequency}

procedure NoSound;
  {-Turn off the sound}

  {****** extensions to Turbo's CRT unit ******}

function GetCrtMode : Byte;
 {-Get the current video mode. Also reinitializes internal variables. May
   reset: CurrentMode, ScreenWidth, ScreenHeight, CurrentPage, and
   VideoSegment.}

procedure GotoXYAbs(X, Y : Byte);
  {-Move cursor to column X, row Y. No error checking done.}

function WhereXY : Word;
 {-Return absolute row and column coordinates of cursor. High byte has current
   row (Y), low byte has current column (X).}

function WhereYAbs : Byte;
  {-Return absolute row coordinate of cursor}

function WhereXAbs : Byte;
  {-Return absolute column coordinate of cursor}

procedure WhereXYdirect(var X, Y : Byte);
  {-Read the current position of the cursor directly from the CRT controller}

procedure SetVisiblePage(PageNum : Byte);
  {-Set current video page}

procedure SetActivePage(PageNo : Byte);
 {-Selects the video page that will be written to with subsequent operations
   on the screen. Does not affect Write/Ln or Read/Ln.}

function GetPageSegment(PageNo : Byte) : Word;
  {-Get the video segment corresponding to the specified video page}

function GetPagePointer(PageNo : Byte) : Pointer;
  {-Get a pointer to the start of the specified video page}

procedure ClearPage(PageNo : Byte);
  {-Clear the specified video page with TextChar and TextAttr}

procedure ScrollWindowUp(XLo, YLo, XHi, YHi, Lines : Byte);
  {-Scrolls the designated window up the specified number of lines.}

procedure ScrollWindowDown(XLo, YLo, XHi, YHi, Lines : Byte);
  {-Scrolls the designated window down the specified number of lines.}

function CursorTypeSL : Word;
  {-Returns a word. High byte has starting scan line, low byte has ending.}

function CursorStartLine : Byte;
  {-Returns the starting scan line of the cursor}

function CursorEndLine : Byte;
  {-Returns the ending scan line of the cursor.}

procedure SetCursorSize(Startline, EndLine : Byte);
  {-Sets the cursor's starting and ending scan lines.}

procedure NormalCursor;
  {-Set normal scan lines for cursor based on current video mode}

procedure FatCursor;
  {-Set larger scan lines for cursor based on current video mode}

procedure BlockCursor;
  {-Set scan lines for a block cursor}

procedure HiddenCursor;
  {-Hide the cursor}

procedure SetCursorType(CT : CursorType);
  {-Sets the cursor shape to the specified type}

function ClassifyCursorType : CursorType;
  {-Classify cursor type based on scan lines}

function ReadCharAtCursor : Char;
  {-Returns character at the current cursor location on the selected page.}

function ReadAttrAtCursor : Byte;
  {-Returns attribute at the current cursor location on the selected page.}

procedure GetCursorState(var XY, ScanLines : Word);
  {-Return the current position and size of the cursor}

procedure RestoreCursorState(XY, ScanLines : Word);
  {-Reset the cursor to a position and size saved with GetCursorState}

procedure FastWrite(St : string; Row, Col : Word; Attr : Byte);
  {-Write St at Row,Col in Attr (video attribute) without snow}

procedure FastText(St : string; Row, Col : Word);
  {-Write St at Row,Col without changing the underlying video attribute.}

procedure FastVert(St : string; Row, Col : Word; Attr : Byte);
  {-Write St vertically at Row,Col in Attr (video attribute)}

procedure FastFill(Number : Word; Ch : Char; Row, Col : Word; Attr : Byte);
  {-Fill Number chs at Row,Col in Attr (video attribute) without snow}

procedure FastFillVert(Number : Word; Ch : Char; Row, Col : Word; Attr : Byte); {!!.03}
  {-Fill Number chs vertically at Row,Col in Attr (video attribute)} {!!.03}

procedure FastCenter(St : string; Row, Attr : Byte);
  {-Write St centered on window Row in Attr (video attribute) without snow}

procedure FastFlush(St : string; Row, Attr : Byte);
  {-Write St flush right on window Row in Attr (video attribute) without snow}

procedure FastRead(Number : Byte; Row, Col : Word; var St : string);
  {-Read Number characters from the screen into St starting at Row,Col}

procedure ReadAttribute(Number : Byte; Row, Col : Word; var St : string);
  {-Read Number attributes from the screen into St starting at Row,Col}

procedure WriteAttribute(St : String; Row, Col : Word);
  {-Write string of attributes St at Row,Col without changing characters}

procedure ChangeAttribute(Number : Word; Row, Col : Word; Attr : Byte);
  {-Change Number video attributes to Attr starting at Row,Col}

procedure MoveScreen(var Source, Dest; Length : Word);
  {-Move Length words from Source to Dest without snow}

procedure FastWriteAttr(St : String; Row, Col : Word; AttrSt : String);
  {-Write St at Row,Col using attributes in AttrSt}

procedure FlexWrite(St : string; Row, Col : Word; var FAttrs : FlexAttrs);
  {-Write St at Row,Col with flexible color handling}

function FlexLen(S : string) : Byte;
  {-Return actual (visible) length of a flex string}

procedure FastWriteCtrl(St : String; Row, Col : Word; Attr, Ctrl : Byte);
  {-Write St at Row,Col in Attr (video attribute) without snow.
    Control characters displayed in Ctrl as upper-case letters}

function SaveWindow(XLow, YLow, XHigh, YHigh : Byte; Allocate : Boolean;
                    var Covers : Pointer) : Boolean;
  {-Allocate buffer space if requested and save window contents}

procedure RestoreWindow(XLow, YLow, XHigh, YHigh : Byte;
                        Deallocate : Boolean; var Covers : Pointer);
  {-Restore screen contents and deallocate buffer space if requested}

procedure ClearWindow(XLow, YLow, XHigh, YHigh : Word; Ch : Char; A : Byte);
  {-Clear a window using the specified character and attribute}

procedure FrameWindow(LeftCol, TopRow, RightCol, BotRow : Word;
                      FAttr, HAttr : Byte;
                      Header : string);
  {-Draws a frame around a window}

procedure StoreWindowCoordinates(var WC : WindowCoordinates);
  {-Store the window coordinates for the active window}

procedure RestoreWindowCoordinates(WC : WindowCoordinates);
  {-Restore previously saved window coordinates}

function MapColor(C : Byte) : Byte;
  {-Map a video attribute for visibility on mono/bw displays}

function UseColor : Boolean;
  {-Returns True if color video attributes should be used}

function ColorMono(Color, Mono : Byte) : Byte;
  {-Choose between a color and a monochrome video attribute}

function MapMono(Color, Mono : Byte) : Byte;
  {-Return a mapped color video attribute if Mono = $FF}

procedure SetBlink(On : Boolean);
  {-Enable text mode attribute blinking if On is True}

procedure SetCrtBorder(Attr : Byte);
  {-Set border to background color if card type and mode allow}

function Font8x8Selected : Boolean;
  {-Return True if EGA or VGA is active and in 8x8 font}

procedure SelectFont8x8(On : Boolean);
  {-Toggle 8x8 font on or off}

function HercPresent : Boolean;
  {-Return true if a Hercules graphics card is present}

procedure SwitchInColorCard(ColorOn : Boolean);
  {-Activate or deactivate colors on a Hercules InColor card}

function HercGraphicsMode : Boolean;
  {-Return True if a Hercules card is in graphics mode}

function HercModeTestWorks : Boolean;
  {-Return True if HercGraphicsMode will work}

procedure SetHercMode(GraphMode : Boolean; GraphPage : Byte);
 {-Set Hercules card to graphics mode or text mode, and activate specified
   graphics page (if switching to graphics mode).}

function ReadKeyWord : Word;
 {-Waits for keypress, then returns scan and character codes together}

function CheckKbd(var KeyCode : Word) : Boolean;
  {-Returns True (and the key codes) if a keystroke is waiting}

function KbdFlags : Byte;
  {-Returns keyboard status flags as a bit-coded byte}

function EnhancedKbdInstalled : Boolean;
  {-Returns True if an enhanced keyboard is installed}

procedure StuffKey(W : Word);
  {-Stuff one key into the keyboard buffer}

procedure StuffString(S : string);
  {-Stuff the contents of S into the keyboard buffer}

procedure ReInitCrt;
  {-Reinitialize CRT unit's internal variables. For TSR's or programs with
    DOS shells. May reset: CurrentMode, ScreenWidth, ScreenHeight,
    WindMin/WindMax, CurrentPage, CurrentDisplay, CheckSnow, and VideoSegment.}

procedure DelayCalibrate;
  {-Perform delay calibration}

  {FPC port additions}

procedure FlushScreen;
  {-Copy pending screen changes (and cursor state) to the real console.
    Called automatically by KeyPressed/ReadKey/ReadKeyWord/CheckKbd/Delay,
    Write/Read through the CRT text file and at exit. Call it yourself
    before long computations or when waiting without polling the keyboard.}

var
  PollHook : procedure;  {FPC port: called while waiting for keys; OpMouse
                          uses it to drain mouse events}

procedure ScreenModified;
  {-Note that the screen buffer was changed directly (for example by the
    mouse cursor) so the next FlushScreen copies it to the console}

procedure DoneCrt;
  {-Restore the console (keyboard, video mode, code page). Called
    automatically from an exit procedure; safe to call more than once.}

function CrtHasConsole : Boolean;
  {-True if a real console is attached (False when stdin/stdout are redirected
    and OPCRT works on a private in-memory screen only)}

const
  ImmediateFlush : Boolean = False;
    {set True to update the console after every screen primitive (slow)}

  {==========================================================================}

implementation

uses
  {$IFDEF UNIX}
  BaseUnix, termio,
  {$ENDIF}
  SysUtils, Video, Keyboard, OpKeyHk;

const
  MaxPages = 8;
  KeyQSize = 16;

type
  PCells = ^TCells;
  TCells = array[0..16777215] of Word;  {cell = Ord(Char) or (Attr shl 8)}
  BufPtr = ^BufferArray;
  BufferArray = array[0..65534] of Char;

var
  SaveExitProc : Pointer;
  NextChar : Byte;
  OwnBuf : Pointer;           {private screen when there is no console}
  ConsoleOK : Boolean;        {Video unit is active}
  KbdOK : Boolean;            {Keyboard unit is active}
  Dirty : Boolean;            {screen/cursor changed since last flush}
  Finished : Boolean;         {DoneCrt has run}
  PhysW, PhysH : Word;        {size of the physical screen}
  CurX, CurY : Word;          {absolute 0-based cursor position}
  CursorSL : Word;            {emulated cursor scan lines (start shl 8 + end)}
  KeyQ : array[0..KeyQSize-1] of Word;
  KeyQHead, KeyQCount : Integer;
  PageStore : array[0..MaxPages-1] of Pointer;
  VisiblePage, ActivePageNo : Byte;
  EofCount : Integer;
  {$IFDEF WINDOWS}
  SavedOutCP, SavedInCP : LongWord;
  CPSaved : Boolean;
  {$ENDIF}

{$IFDEF WINDOWS}
function GetStdHandle(nStdHandle : LongWord) : PtrUInt;
  stdcall; external 'kernel32' name 'GetStdHandle';
function GetConsoleMode(H : PtrUInt; var Mode : LongWord) : LongInt;
  stdcall; external 'kernel32' name 'GetConsoleMode';
function GetConsoleOutputCP : LongWord;
  stdcall; external 'kernel32' name 'GetConsoleOutputCP';
function SetConsoleOutputCP(CP : LongWord) : LongInt;
  stdcall; external 'kernel32' name 'SetConsoleOutputCP';
function GetConsoleCP : LongWord;
  stdcall; external 'kernel32' name 'GetConsoleCP';
function SetConsoleCP(CP : LongWord) : LongInt;
  stdcall; external 'kernel32' name 'SetConsoleCP';
function WinBeep(Freq, Dur : LongWord) : LongInt;
  stdcall; external 'kernel32' name 'Beep';
{$ENDIF}

  function StdIsConsole(StdOut : Boolean) : Boolean;
    {-True if stdin/stdout is attached to a real console/terminal}
  {$IFDEF WINDOWS}
  var
    H : PtrUInt;
    M : LongWord;
  begin
    if StdOut then
      H := GetStdHandle($FFFFFFF5)   {STD_OUTPUT_HANDLE = -11}
    else
      H := GetStdHandle($FFFFFFF6);  {STD_INPUT_HANDLE = -10}
    StdIsConsole := (H <> 0) and (H <> High(PtrUInt)) and
                    (GetConsoleMode(H, M) <> 0);
  end;
  {$ELSE}
  begin
    if StdOut then
      StdIsConsole := (IsATTY(1) = 1)
    else
      StdIsConsole := (IsATTY(0) = 1);
  end;
  {$ENDIF}

  procedure DoBeep;
  begin
    {$IFDEF WINDOWS}
    if ConsoleOK then
      if WinBeep(800, 100) = 0 then ;
    {$ELSE}
    if ConsoleOK then
      if fpWrite(1, #7, 1) < 0 then ;
    {$ENDIF}
  end;

  {----------------------- screen change tracking -----------------------}

  procedure ScreenChanged;
    {-Note a change of the physical screen or cursor}
  begin
    Dirty := True;
    if ImmediateFlush then
      FlushScreen;
  end;

  procedure VTouch;
    {-Note a change made through VirtualBuffer}
  begin
    if VirtualBuffer = VideoBuffer then
      ScreenChanged;
  end;

  procedure ApplyCursor;
  var
    CT : Word;
    Lines : Integer;
  begin
    if (Hi(CursorSL) and $20) <> 0 then
      CT := crHidden
    else begin
      Lines := Integer(Lo(CursorSL)) - Hi(CursorSL) + 1;
      if Lines <= 2 then
        CT := crUnderline
      else if Lines <= 5 then
        CT := crHalfBlock
      else
        CT := crBlock;
    end;
    Video.SetCursorType(CT);
    Video.SetCursorPos(CurX, CurY);
  end;

{$IFDEF WINDOWS}
const
  Cp437Uni : array[0..255] of Word = (
    $0000, $263A, $263B, $2665, $2666, $2663, $2660, $2022,
    $25D8, $25CB, $25D9, $2642, $2640, $266A, $266B, $263C,
    $25BA, $25C4, $2195, $203C, $00B6, $00A7, $25AC, $21A8,
    $2191, $2193, $2192, $2190, $221F, $2194, $25B2, $25BC,
    $0020, $0021, $0022, $0023, $0024, $0025, $0026, $0027,
    $0028, $0029, $002A, $002B, $002C, $002D, $002E, $002F,
    $0030, $0031, $0032, $0033, $0034, $0035, $0036, $0037,
    $0038, $0039, $003A, $003B, $003C, $003D, $003E, $003F,
    $0040, $0041, $0042, $0043, $0044, $0045, $0046, $0047,
    $0048, $0049, $004A, $004B, $004C, $004D, $004E, $004F,
    $0050, $0051, $0052, $0053, $0054, $0055, $0056, $0057,
    $0058, $0059, $005A, $005B, $005C, $005D, $005E, $005F,
    $0060, $0061, $0062, $0063, $0064, $0065, $0066, $0067,
    $0068, $0069, $006A, $006B, $006C, $006D, $006E, $006F,
    $0070, $0071, $0072, $0073, $0074, $0075, $0076, $0077,
    $0078, $0079, $007A, $007B, $007C, $007D, $007E, $2302,
    $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7,
    $00EA, $00EB, $00E8, $00EF, $00EE, $00EC, $00C4, $00C5,
    $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9,
    $00FF, $00D6, $00DC, $00A2, $00A3, $00A5, $20A7, $0192,
    $00E1, $00ED, $00F3, $00FA, $00F1, $00D1, $00AA, $00BA,
    $00BF, $2310, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $2561, $2562, $2556,
    $2555, $2563, $2551, $2557, $255D, $255C, $255B, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $2567,
    $2568, $2564, $2565, $2559, $2558, $2552, $2553, $256B,
    $256A, $2518, $250C, $2588, $2584, $258C, $2590, $2580,
    $03B1, $00DF, $0393, $03C0, $03A3, $03C3, $00B5, $03C4,
    $03A6, $0398, $03A9, $03B4, $221E, $03C6, $03B5, $2229,
    $2261, $00B1, $2265, $2264, $2320, $2321, $00F7, $2248,
    $00B0, $2219, $00B7, $221A, $207F, $00B2, $25A0, $00A0);

type
  TWinCharInfo = record
    Ch : Word;
    Attr : Word;
  end;
  TWinCoord = record
    X, Y : SmallInt;
  end;
  TWinRect = record
    L, T, R, B : SmallInt;
  end;

function WriteConsoleOutputW(H : PtrUInt; Buf : Pointer; Size, Coord : TWinCoord;
  var Region : TWinRect) : LongInt;
  stdcall; external 'kernel32' name 'WriteConsoleOutputW';

  procedure WinUpdateScreen;
    {-Write the cell buffer as Unicode so CP437 glyphs show in any terminal}
  var
    Buf : array of TWinCharInfo;
    Cells : PCells;
    N, I : LongInt;
    Sz, Org : TWinCoord;
    Rg : TWinRect;
  begin
    N := LongInt(PhysW)*PhysH;
    SetLength(Buf, N);
    Cells := PCells(VideoBuffer);
    for I := 0 to N-1 do begin
      Buf[I].Ch := Cp437Uni[Cells^[I] and $FF];
      Buf[I].Attr := Cells^[I] shr 8;
    end;
    Sz.X := PhysW; Sz.Y := PhysH;
    Org.X := 0; Org.Y := 0;
    Rg.L := 0; Rg.T := 0; Rg.R := PhysW-1; Rg.B := PhysH-1;
    if WriteConsoleOutputW(GetStdHandle($FFFFFFF5), @Buf[0], Sz, Org, Rg) = 0 then
      Video.UpdateScreen(True);
  end;
{$ENDIF}
  procedure FlushScreen;
    {-Copy pending screen changes (and cursor state) to the real console}
  begin
    if not Dirty then
      Exit;
    Dirty := False;
    if ConsoleOK then begin
      {$IFDEF WINDOWS}
      WinUpdateScreen;
      {$ELSE}
      Video.UpdateScreen(False);
      {$ENDIF}
      ApplyCursor;
    end;
  end;

  function CrtHasConsole : Boolean;
  begin
    CrtHasConsole := ConsoleOK;
  end;

  function MakeHiddenAttr(A : Byte) : Byte;
    {-Make foreground and background colors the same}
  begin
    MakeHiddenAttr := (A and $F0) or ((A and $F0) shr 4);
  end;

  {$I opcrt.in1}    {Hercules stuff (stubs), alternate video page routines}

  {----------------------- cursor position/shape -----------------------}

  procedure SetCur(X, Y : LongInt);
    {-Move the cursor (absolute, 0-based), clipped to the screen}
  begin
    if X < 0 then X := 0;
    if Y < 0 then Y := 0;
    if X >= PhysW then X := PhysW-1;
    if Y >= PhysH then Y := PhysH-1;
    CurX := X;
    CurY := Y;
    ScreenChanged;
  end;

  procedure GotoXYAbs(X, Y : Byte);
    {-Move cursor to column X, row Y. No error checking done.}
  begin
    SetCur(LongInt(X)-1, LongInt(Y)-1);
  end;

  function WhereXY : Word;
    {-Return absolute row and column coordinates of cursor.}
  begin
    WhereXY := ((CurY+1) shl 8) or (CurX+1);
  end;

  function WhereXAbs : Byte;
  begin
    WhereXAbs := CurX+1;
  end;

  function WhereYAbs : Byte;
  begin
    WhereYAbs := CurY+1;
  end;

  procedure WhereXYdirect(var X, Y : Byte);
    {-Read the current position of the cursor directly from the CRT controller}
  begin
    {FPC port: no CRT controller; returns the emulated cursor position}
    X := CurX+1;
    Y := CurY+1;
  end;

  procedure SetCursorSize(StartLine, EndLine : Byte);
    {-Sets the cursor's starting and ending scan lines.}
  begin
    CursorSL := (Word(StartLine) shl 8) or EndLine;
    ScreenChanged;
  end;

  function CursorTypeSL : Word;
  begin
    CursorTypeSL := CursorSL;
  end;

  function CursorStartLine : Byte;
  begin
    CursorStartLine := Hi(CursorSL);
  end;

  function CursorEndLine : Byte;
  begin
    CursorEndLine := Lo(CursorSL);
  end;

  procedure NormalCursor;
    {-Set normal scan lines for cursor based on current video mode}
  var
    ScanLines : Word;
  begin
    if (Hi(LastMode) <> 0) then
      ScanLines := $0507
    else
      if CurrentMode = 7 then
        ScanLines := $0B0C
      else
        ScanLines := $0607;
    SetCursorSize(Hi(ScanLines), Lo(ScanLines));
  end;

  procedure FatCursor;
    {-Set larger scan lines for cursor based on current video mode}
  var
    ScanLines : Word;
  begin
    if (Hi(LastMode) <> 0) then
      ScanLines := $0307
    else if CurrentMode = 7 then
      ScanLines := $090C
    else
      ScanLines := $0507;
    SetCursorSize(Hi(ScanLines), Lo(ScanLines));
  end;

  procedure BlockCursor;
    {-Set scan lines for a block cursor}
  var
    EndLine : Byte;
  begin
    if (Hi(LastMode) <> 0) or (CurrentMode <> 7) then
      EndLine := $07
    else
      EndLine := $0C;
    SetCursorSize(0, EndLine);
  end;

  procedure HiddenCursor;
    {-Hide the cursor}
  begin
    SetCursorSize($20, 0);
  end;

  procedure SetCursorType(CT : CursorType);
    {-Sets the cursor shape to the specified type}
  begin
    case CT of
      cuNormal : NormalCursor;
      cuFat    : FatCursor;
      cuBlock  : BlockCursor;
      else       HiddenCursor;
    end;
  end;

  function ClassifyCursorType : CursorType;
    {-Classify cursor type based on scan lines}
  var
    CT : Word;
  begin
    CT := CursorTypeSL;
    if CT = $2000 then
      ClassifyCursorType := cuHidden
    else if Hi(LastMode) <> 0 then
      case CT of
        $0507 : ClassifyCursorType := cuNormal;
        $0307 : ClassifyCursorType := cuFat;
        $0007 : ClassifyCursorType := cuBlock;
        else    ClassifyCursorType := cuUnknown;
      end
    else if CurrentMode = 7 then
      case CT of
        $0B0C : ClassifyCursorType := cuNormal;
        $090C : ClassifyCursorType := cuFat;
        $000C : ClassifyCursorType := cuBlock;
        else    ClassifyCursorType := cuUnknown;
      end
    else
      case CT of
        $0607 : ClassifyCursorType := cuNormal;
        $0507 : ClassifyCursorType := cuFat;
        $0007 : ClassifyCursorType := cuBlock;
        else    ClassifyCursorType := cuUnknown;
      end;
  end;

  procedure GetCursorState(var XY, ScanLines : Word);
    {-Return the current position and size of the cursor}
  begin
    XY := WhereXY;
    ScanLines := CursorTypeSL;
  end;

  procedure RestoreCursorState(XY, ScanLines : Word);
    {-Reset the cursor to a position and size saved with GetCursorState}
  begin
    SetCursorSize(Hi(ScanLines), Lo(ScanLines));
    GotoXYAbs(Lo(XY), Hi(XY));
  end;

  {----------------------- scrolling -----------------------}

  procedure ScrollRaw(Up : Boolean; X1, Y1, X2, Y2, Lines : LongInt;
                      Attr : Byte; Ch : Char);
    {-Scroll a window of the physical screen (0-based coordinates). Lines = 0
      or more than the window height clears the whole window.}
  var
    Cells : PCells;
    Rows, Cols, R, C : LongInt;
    Blank : Word;
  begin
    if X1 < 0 then X1 := 0;
    if Y1 < 0 then Y1 := 0;
    if X2 >= PhysW then X2 := PhysW-1;
    if Y2 >= PhysH then Y2 := PhysH-1;
    if (X1 > X2) or (Y1 > Y2) then
      Exit;
    Rows := Y2-Y1+1;
    Cols := X2-X1+1;
    if (Lines <= 0) or (Lines > Rows) then
      Lines := Rows;
    Blank := (Word(Attr) shl 8) or Ord(Ch);
    Cells := PCells(VideoBuffer);
    if Up then begin
      for R := Y1 to Y2-Lines do
        Move(Cells^[(R+Lines)*PhysW+X1], Cells^[R*PhysW+X1], Cols*2);
      for R := Y2-Lines+1 to Y2 do
        for C := X1 to X2 do
          Cells^[R*PhysW+C] := Blank;
    end
    else begin
      for R := Y2 downto Y1+Lines do
        Move(Cells^[(R-Lines)*PhysW+X1], Cells^[R*PhysW+X1], Cols*2);
      for R := Y1 to Y1+Lines-1 do
        for C := X1 to X2 do
          Cells^[R*PhysW+C] := Blank;
    end;
    ScreenChanged;
  end;

  procedure ScrollUpPrim(X1, Y1, X2, Y2, Lines : LongInt; Attr : Byte);
  begin
    ScrollRaw(True, X1, Y1, X2, Y2, Lines, Attr, TextChar);
    TextChar := ' ';
  end;

  procedure ScrollDownPrim(X1, Y1, X2, Y2, Lines : LongInt; Attr : Byte);
  begin
    ScrollRaw(False, X1, Y1, X2, Y2, Lines, Attr, TextChar);
    TextChar := ' ';
  end;

  procedure ScrollWindowUp(XLo, YLo, XHi, YHi, Lines : Byte);
    {-Scrolls the designated window up the specified number of lines.}
  begin
    if YLo = YHi then
      Lines := 0;
    ScrollUpPrim(XLo-1, YLo-1, XHi-1, YHi-1, Lines, TextAttr);
  end;

  procedure ScrollWindowDown(XLo, YLo, XHi, YHi, Lines : Byte);
    {-Scrolls the designated window down the specified number of lines.}
  begin
    if YLo = YHi then
      Lines := 0;
    ScrollDownPrim(XLo-1, YLo-1, XHi-1, YHi-1, Lines, TextAttr);
  end;

  procedure ClrEol;
    {-Clear the remainder of the current screen line}
  begin
    ScrollUpPrim(CurX, CurY, Lo(WindMax), CurY, 0, TextAttr);
  end;

  procedure InsLine;
    {-Insert a new line at the position of the cursor}
  var
    Lines : Integer;
  begin
    Lines := 1;
    if CurY = Hi(WindMax) then
      Lines := 0;
    ScrollDownPrim(Lo(WindMin), CurY, Lo(WindMax), Hi(WindMax), Lines, TextAttr);
  end;

  procedure DelLine;
    {-Delete current screen line}
  var
    Lines : Integer;
  begin
    Lines := 1;
    if CurY = Hi(WindMax) then
      Lines := 0;
    ScrollUpPrim(Lo(WindMin), CurY, Lo(WindMax), Hi(WindMax), Lines, TextAttr);
  end;

  function ReadCharAtCursor : Char;
    {-Returns character at the current cursor location on the selected page.}
  begin
    ReadCharAtCursor := Chr(PCells(VideoBuffer)^[LongInt(CurY)*PhysW+CurX] and $FF);
  end;

  function ReadAttrAtCursor : Byte;
    {-Returns attribute at the current cursor location on the selected page.}
  begin
    ReadAttrAtCursor := PCells(VideoBuffer)^[LongInt(CurY)*PhysW+CurX] shr 8;
  end;

  {----------------------- windows, text attributes -----------------------}

  procedure FullWindow;
    {-Set the window to the whole screen}
  var
    W, H : Word;
  begin
    W := PhysW-1;
    H := PhysH-1;
    if W > 255 then W := 255;
    if H > 255 then H := 255;
    WindMin := 0;
    WindMax := (H shl 8) or W;
  end;

  procedure Window(XLow, YLow, XHigh, YHigh : Byte);
    {-Set current window coordinates}
  begin
    if (XLow < 1) or (YLow < 1) or (XLow > XHigh) or (YLow > YHigh) or
       (XHigh > ScreenWidth) or (YHigh > ScreenHeight) then
      Exit;
    WindMin := ((YLow-1) shl 8) or (XLow-1);
    WindMax := ((YHigh-1) shl 8) or (XHigh-1);
    SetCur(XLow-1, YLow-1);
  end;

  procedure ClrScr;
    {-Clear the current window}
  begin
    ScrollUpPrim(Lo(WindMin), Hi(WindMin), Lo(WindMax), Hi(WindMax), 0, TextAttr);
    SetCur(Lo(WindMin), Hi(WindMin));
  end;

  procedure GoToXY(X, Y : Byte);
    {-Move cursor to column X, row Y, relative to Window}
  var
    AX, AY : Integer;
  begin
    if (X < 1) or (Y < 1) then
      Exit;
    AX := X-1+Lo(WindMin);
    AY := Y-1+Hi(WindMin);
    if (AX > Lo(WindMax)) or (AY > Hi(WindMax)) then
      Exit;
    SetCur(AX, AY);
  end;

  function WhereX : Byte;
    {-Return column coordinate of cursor, relative to Window}
  begin
    WhereX := Integer(CurX)-Lo(WindMin)+1;
  end;

  function WhereY : Byte;
    {-Return row coordinate of cursor, relative to Window}
  begin
    WhereY := Integer(CurY)-Hi(WindMin)+1;
  end;

  procedure TextColor(Color : Byte);
    {-Set foreground color for screen writes}
  begin
    if (Color and $F0) <> 0 then
      Color := (Color and $0F) or Blink;
    TextAttr := (TextAttr and $70) or Color;
  end;

  procedure TextBackground(Color : Byte);
    {-Set background color for screen writes}
  begin
    TextAttr := (TextAttr and $8F) or ((Color and $07) shl 4);
  end;

  procedure LowVideo;
    {-Select low intensity}
  begin
    TextAttr := TextAttr and $77;
  end;

  procedure HighVideo;
    {-Select high intensity}
  begin
    TextAttr := TextAttr or $08;
  end;

  procedure NormVideo;
    {-Select video attribute used at start of program}
  begin
    TextAttr := NormalAttr;
  end;

  {----------------------- keyboard -----------------------}

  function EvToWord(Ev : TKeyEvent) : Word;
    {-Convert a Keyboard unit event to the DOS key word (scan shl 8 + char).
      Returns 0 for events that are not keystrokes (key release, shift only).}
  var
    Fl : Byte;
    W : Word;
  begin
    EvToWord := 0;
    Fl := (Ev shr 24) and $FF;
    if (Fl and kbReleased) <> 0 then
      Exit;
    W := Ev and $FFFF;
    case Fl and $03 of
      kbPhys :
        EvToWord := W;     {FPC delivers (scancode shl 8) or ascii already}
      kbASCII, kbUniCode :
        if W < 256 then
          EvToWord := W;   {no scan code known}
      kbFnKey :
        case W of
          kbdF1..kbdF10 : EvToWord := (Word($3B) + (W-kbdF1)) shl 8;
          kbdF11        : EvToWord := $8500;
          kbdF12        : EvToWord := $8600;
          kbdHome       : EvToWord := $4700;
          kbdUp         : EvToWord := $4800;
          kbdPgUp       : EvToWord := $4900;
          kbdLeft       : EvToWord := $4B00;
          kbdRight      : EvToWord := $4D00;
          kbdEnd        : EvToWord := $4F00;
          kbdDown       : EvToWord := $5000;
          kbdPgDn       : EvToWord := $5100;
          kbdInsert     : EvToWord := $5200;
          kbdDelete     : EvToWord := $5300;
        end;
    end;
  end;

  function PeekKey(var W : Word) : Boolean;
    {-True (and the key word, not consumed) if a keystroke is waiting}
  var
    Ev : TKeyEvent;
    X : Word;
  begin
    PeekKey := False;
    if @PollHook <> nil then
      PollHook;
    if KeyQCount > 0 then begin
      W := KeyQ[KeyQHead];
      PeekKey := True;
      Exit;
    end;
    if not KbdOK then
      Exit;
    repeat
      Ev := Keyboard.PollKeyEvent;
      if Ev = 0 then
        Exit;
      X := EvToWord(Ev);
      if X <> 0 then begin
        W := X;
        PeekKey := True;
        Exit;
      end;
      Ev := Keyboard.GetKeyEvent;   {discard non-key event}
    until False;
  end;

  procedure DropKey;
    {-Consume the key reported by PeekKey}
  var
    Ev : TKeyEvent;
  begin
    if KeyQCount > 0 then begin
      KeyQHead := (KeyQHead+1) mod KeyQSize;
      Dec(KeyQCount);
    end
    else if KbdOK then
      Ev := Keyboard.GetKeyEvent;
  end;

  procedure ScreenModified;
  begin
    Dirty := True;
  end;

  function NativeReadKeyWord : Word;
    {-Native blocking read, bypassing the key hook}
  var
    W : Word;
    Ev : TKeyEvent;
    B : Byte;
  begin
    FlushScreen;
    repeat
      if KeyQCount > 0 then begin
        NativeReadKeyWord := KeyQ[KeyQHead];
        DropKey;
        Exit;
      end;
      if KbdOK then begin
        if (Keyboard.PollKeyEvent = 0) and (@PollHook <> nil) then begin
          PollHook;
          FlushScreen;
          SysUtils.Sleep(1);
          Continue;
        end;
        Ev := Keyboard.GetKeyEvent;
        W := EvToWord(Ev);
        if W <> 0 then begin
          NativeReadKeyWord := W;
          Exit;
        end;
      end
      else begin
        {FPC port: no console keyboard; read bytes from redirected stdin.
         At end of input return Esc, and stop the program if that goes on.}
        if SysUtils.FileRead(0, B, 1) <= 0 then begin
          Inc(EofCount);
          if EofCount > 1000 then
            Halt(1);
          NativeReadKeyWord := $011B;
        end
        else
          NativeReadKeyWord := B;
        Exit;
      end;
    until False;
  end;

  function NativeCheckKbd(var KeyCode : Word) : Boolean;
    {-Native peek, bypassing the key hook}
  begin
    FlushScreen;
    if (not KbdOK) and (KeyQCount = 0) then begin
      {no console keyboard: report a key so that polling loops end}
      KeyCode := $011B;
      NativeCheckKbd := True;
    end
    else
      NativeCheckKbd := PeekKey(KeyCode);
  end;

  function ReadKeyWord : Word;
     {-Waits for keypress, then returns scan and character codes together}
  var
    K : Word;
  begin
    if @KeyHook <> nil then begin
      KeyHook(False, K);
      ReadKeyWord := K;
    end
    else
      ReadKeyWord := NativeReadKeyWord;
  end;

  function CheckKbd(var KeyCode : Word) : Boolean;
     {-Returns True (and the key codes) if a keystroke is waiting}
  begin
    if @KeyHook <> nil then
      CheckKbd := KeyHook(True, KeyCode)
    else
      CheckKbd := NativeCheckKbd(KeyCode);
  end;

  function KeyPressed : Boolean;
    {-Return true if a key has been pressed}
  var
    W : Word;
  begin
    if NextChar <> 0 then
      KeyPressed := True
    else
      KeyPressed := CheckKbd(W);
  end;

  function KbdFlags : Byte;
    {-Returns keyboard status flags as a bit-coded byte}
  var
    S, F : Byte;
  begin
    F := 0;
    if KbdOK then begin
      S := Keyboard.GetKeyEventShiftState(Keyboard.PollShiftStateEvent);
      {Keyboard reports no left/right distinction on every platform}
      if (S and kbRightShift) <> 0 then F := F or $01;
      if (S and kbLeftShift) <> 0 then F := F or $02;
      if (S and kbCtrl) <> 0 then F := F or $04;
      if (S and kbAlt) <> 0 then F := F or $08;
    end;
    {FPC port: Caps/Num/Scroll lock and Insert states are not available}
    KbdFlags := F;
  end;

  function EnhancedKbdInstalled : Boolean;
    {-Returns True if an enhanced keyboard is installed}
  begin
    EnhancedKbdInstalled := True;
  end;

  procedure StuffKey(W : Word);
    {-Stuff one key into the keyboard buffer}
  begin
    {FPC port: private queue consulted before the real keyboard}
    if KeyQCount < KeyQSize then begin
      KeyQ[(KeyQHead+KeyQCount) mod KeyQSize] := W;
      Inc(KeyQCount);
    end;
  end;

  procedure StuffString(S : string);
    {-Stuff the contents of S into the keyboard buffer}
  var
    I : Byte;
  begin
    {allow at most 15 characters}
    if Length(S) > 15 then
      S[0] := #15;

    {stuff each key}
    for I := 1 to Length(S) do
      StuffKey(Ord(S[I]));
  end;

  procedure BreakCheck;
    {-Halt if Ctrl-Break was pressed}
  var
    W : Word;
  begin
    if CtrlBreakFlag then begin
      CtrlBreakFlag := False;
      while PeekKey(W) do
        DropKey;
      {FPC port: the Keyboard unit never reports Ctrl-Break, so this is only
       reachable if some other code sets CtrlBreakFlag}
      FlushScreen;
      Halt(255);
    end;
  end;

  function ReadKey : Char;
    {-Read a character from the keyboard}
  var
    W : Word;
  begin
    if NextChar <> 0 then begin
      ReadKey := Chr(NextChar);
      NextChar := 0;
      Exit;
    end;
    W := ReadKeyWord;
    if Lo(W) = 0 then begin
      if Hi(W) = 0 then
        ReadKey := ^C
      else begin
        NextChar := Hi(W);
        ReadKey := #0;
      end;
    end
    else
      ReadKey := Chr(Lo(W));
    BreakCheck;
  end;

  {----------------------- text file driver -----------------------}

  procedure WriteChar(C : Char);
    {-Write a character at the cursor, interpreting CR, LF, BS and bell}
  var
    Cells : PCells;
    L, R, B : Integer;
  begin
    L := Lo(WindMin);
    R := Lo(WindMax);
    B := Hi(WindMax);
    case C of
      #7  : DoBeep;
      #8  : if CurX > L then Dec(CurX);
      #10 : Inc(CurY);
      #13 : CurX := L;
      else begin
        Cells := PCells(VideoBuffer);
        if (CurX < PhysW) and (CurY < PhysH) then
          Cells^[LongInt(CurY)*PhysW+CurX] := (Word(TextAttr) shl 8) or Ord(C);
        Inc(CurX);
        if CurX > R then begin
          CurX := L;
          Inc(CurY);
        end;
      end;
    end;
    if CurY > B then begin
      CurY := B;
      ScrollRaw(True, L, Hi(WindMin), R, B, 1, TextAttr, ' ');
    end;
    ScreenChanged;
  end;

  function CrtWrite(var F : TextRec) : Longint;
  var
    I : LongInt;
  begin
    for I := 0 to F.BufPos-1 do
      WriteChar(F.BufPtr^[I]);
    F.BufPos := 0;
    TextChar := ' ';
    BreakCheck;
    FlushScreen;
    CrtWrite := 0;
  end;

  function CrtRead(var F : TextRec) : Longint;
  var
    Pos, Max : LongInt;
    C : Char;
    Done : Boolean;

    procedure Erase1;
    begin
      Dec(Pos);
      WriteChar(#8);
      WriteChar(' ');
      WriteChar(#8);
    end;

  begin
    Max := F.BufSize-2;
    if Max > BufLen then
      Max := BufLen;
    Pos := 0;
    Done := False;
    repeat
      NextChar := 0;
      C := ReadKey;
      case C of
        #0 : ;                        {extended key: ignored}
        #8, ^S :
          if Pos > 0 then
            Erase1;
        #27, ^A, #127 :
          while Pos > 0 do
            Erase1;
        #13 :
          begin
            F.BufPtr^[Pos] := #13;
            F.BufPtr^[Pos+1] := #10;
            Inc(Pos, 2);
            WriteChar(#13);
            WriteChar(#10);
            Done := True;
          end;
        #26 :
          if CheckEOF then begin
            Pos := 0;
            Done := True;
          end;
        ' '..#126, #128..#255 :
          if Pos < Max then begin
            F.BufPtr^[Pos] := C;
            Inc(Pos);
            WriteChar(C);
          end;
      end;
      FlushScreen;
    until Done;
    F.BufPos := 0;
    F.BufEnd := Pos;
    CrtRead := 0;
  end;

  function CrtClose(var F : TextRec) : Longint;
  begin
    CrtClose := 0;
  end;

  function CrtOpen(var F : TextRec) : Longint;
  begin
    if F.Mode = fmInput then begin
      F.InOutFunc := @CrtRead;
      F.FlushFunc := nil;
    end
    else begin
      F.Mode := fmOutput;
      F.InOutFunc := @CrtWrite;
      F.FlushFunc := @CrtWrite;
    end;
    F.CloseFunc := @CrtClose;
    CrtOpen := 0;
  end;

  procedure AssignCrt(var F : Text);
    {-Routes input and output through our routines}
  begin
    Assign(F, '');
    TextRec(F).OpenFunc := @CrtOpen;
    BufLen := 126;
  end;

  {----------------------- mode / adapter -----------------------}

  procedure GetCrtModePrim;
    {-Refresh mode-dependent variables}
  begin
    if not (Lo(LastMode) in [BW40, CO40, BW80, CO80, Mono]) then
      LastMode := CO80;
    ScreenWidth := PhysW;
    ScreenHeight := PhysH;
    VirtualWidth := PhysW;
    VirtualHeight := PhysH;
    CurrentHeight := PhysH-1;
    CurrentPage := VisiblePage;
    ActivePageNo := VisiblePage;
    InTextMode := True;
    if CurrentMode = Mono then
      VideoSegment := $B000
    else
      VideoSegment := $B800;
    VirtualSegment := VideoSegment;
    VirtualBuffer := VideoBuffer;
    MultiTaskingOn := False;
  end;

  procedure AdapterCheck;
    {-Set display type variables}
  begin
    {FPC port: no adapter detection; report a VGA unless overridden}
    LastMode := Lo(LastMode);
    CurrentDisplay := VGA;
    EnhancedDisplay := VGA;
    if DisplayOverride >= 0 then begin
      if DisplayOverride > Ord(PGC) then
        CurrentDisplay := VGA
      else
        CurrentDisplay := DisplayType(DisplayOverride);
      if CurrentDisplay < MCGA then begin
        if CurrentMode = Mono then
          CurrentDisplay := MonoHerc
        else
          CurrentDisplay := CGA;
        EnhancedDisplay := MonoHerc;
      end
      else
        EnhancedDisplay := CurrentDisplay;
    end;
    if (PhysH > 25) and (PhysW <= 80) then
      LastMode := LastMode or Font8x8;
  end;

  function GetCrtMode : Byte;
    {-Get the current video mode. Also reinitializes internal variables.}
  begin
    GetCrtModePrim;
    GetCrtMode := CurrentMode;
  end;

  procedure ReInitCrt;
    {-Reinitialize CRT unit's internal variables.}
  begin
    GetCrtModePrim;
    AdapterCheck;
    WhichHerc := WhichHercCard;
    CheckSnow := False;
    FullWindow;
  end;

  procedure TextMode(Mode : Word);
    {-Switch to/set text mode}
  begin
    {FPC port: the real console mode cannot be switched. The mode number and
     8x8 flag are recorded and the screen is cleared, but the screen size
     stays that of the console.}
    if Lo(Mode) in [BW40, CO40, BW80, CO80, Mono] then
      LastMode := Lo(Mode)
    else
      LastMode := CO80;
    ReInitCrt;
    if (Mode and Font8x8) <> 0 then
      SelectFont8x8(True);
    TextAttr := $07;
    NormalAttr := $07;
    TextChar := ' ';
    ScrollRaw(True, 0, 0, PhysW-1, PhysH-1, 0, TextAttr, ' ');
    NormalCursor;
    SetCur(0, 0);
  end;

  function Font8x8Selected : Boolean;
    {-Return True if EGA or VGA is active and in 8x8 font}
  begin
    Font8x8Selected := (LastMode and Font8x8) <> 0;
  end;

  procedure SelectFont8x8(On : Boolean);
    {-Toggle 8x8 font on or off}
  begin
    {FPC port: stubbed because the font cannot be changed; only the flag
     that selects the cursor scan lines is kept}
    if On then
      LastMode := LastMode or Font8x8
    else
      LastMode := LastMode and not Font8x8;
  end;

  procedure SetBlink(On : Boolean);
    {-Enable text mode attribute blinking if On is True}
  begin
    {FPC port: stubbed because the console decides how attribute bit 7 is
     shown (blink or intense background)}
  end;

  procedure SetCrtBorder(Attr : Byte);
    {-Set border to background color if card type and mode allow}
  begin
    {FPC port: stubbed because there is no border}
  end;

  procedure Sound(Hz : Word);
    {-Turn on the sound at the designated frequency}
  begin
    {FPC port: stubbed because there is no portable speaker access}
  end;

  procedure NoSound;
    {-Turn off the sound}
  begin
    {FPC port: stubbed because there is no portable speaker access}
  end;

  procedure Delay(MS : Word);
    {-Delay for MS milliseconds}
  begin
    FlushScreen;
    if MS > 0 then
      SysUtils.Sleep(MS);
  end;

  procedure DelayCalibrate;
    {-Perform delay calibration}
  begin
    {FPC port: Delay uses the OS timer; OneMS is only a nominal value}
    OneMS := 1000;
  end;

  {----------------------- fast screen writing -----------------------}

  function Lim : LongInt;
    {-Number of cells that may be written through VirtualBuffer}
  begin
    if VirtualBuffer = VideoBuffer then
      Lim := LongInt(PhysW) * PhysH
    else
      Lim := $1000000;
  end;

  function Idx0(Row, Col : Word) : LongInt;
  begin
    Idx0 := (LongInt(Row)-1) * VirtualWidth + Col - 1;
  end;

  procedure PutCell(I : LongInt; W : Word);
  begin
    if (I >= 0) and (I < Lim) then
      PCells(VirtualBuffer)^[I] := W;
  end;

  function GetCell(I : LongInt) : Word;
  begin
    if (I >= 0) and (I < Lim) then
      GetCell := PCells(VirtualBuffer)^[I]
    else
      GetCell := $0720;
  end;

  procedure FastWrite(St : string; Row, Col : Word; Attr : Byte);
    {-Write St at Row,Col in Attr (video attribute) without snow}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 1 to Length(St) do
      PutCell(I+J-1, (Word(Attr) shl 8) or Ord(St[J]));
    VTouch;
  end;

  procedure FastText(St : string; Row, Col : Word);
    {-Write St at Row,Col without changing the underlying video attribute.}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 1 to Length(St) do
      PutCell(I+J-1, (GetCell(I+J-1) and $FF00) or Ord(St[J]));
    VTouch;
  end;

  procedure WriteAttribute(St : String; Row, Col : Word);
    {-Write string of attributes St at Row,Col without changing characters}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 1 to Length(St) do
      PutCell(I+J-1, (GetCell(I+J-1) and $00FF) or (Word(Ord(St[J])) shl 8));
    VTouch;
  end;

  procedure FastVert(St : string; Row, Col : Word; Attr : Byte);
    {-Write St vertically at Row,Col in Attr (video attribute)}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 1 to Length(St) do
      PutCell(I+(J-1)*VirtualWidth, (Word(Attr) shl 8) or Ord(St[J]));
    VTouch;
  end;

  procedure FastFill(Number : Word; Ch : Char; Row, Col : Word; Attr : Byte);
    {-Fill Number chs at Row,Col in Attr (video attribute) without snow}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 0 to LongInt(Number)-1 do
      PutCell(I+J, (Word(Attr) shl 8) or Ord(Ch));
    VTouch;
  end;

  procedure FastFillVert(Number : Word; Ch : Char; Row, Col : Word; Attr : Byte);
    {-Fill Number chs vertically at Row,Col in Attr (video attribute)}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 0 to LongInt(Number)-1 do
      PutCell(I+J*VirtualWidth, (Word(Attr) shl 8) or Ord(Ch));
    VTouch;
  end;

  procedure ChangeAttribute(Number : Word; Row, Col : Word; Attr : Byte);
    {-Change Number video attributes to Attr starting at Row,Col}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 0 to LongInt(Number)-1 do
      PutCell(I+J, (GetCell(I+J) and $00FF) or (Word(Attr) shl 8));
    VTouch;
  end;

  procedure FastCenter(St : string; Row, Attr : Byte);
    {-Write St centered on window Row in Attr (video attribute) without snow}
  var
    Col : Integer;
  begin
    Col := ((Integer(Lo(WindMin)) + Lo(WindMax) + 1) shr 1) - (Length(St) shr 1) + 1;
    FastWrite(St, Word(Row) + Hi(WindMin), Word(Col), Attr);
  end;

  procedure FastFlush(St : string; Row, Attr : Byte);
    {-Write St flush right on window Row in Attr (video attribute) without snow}
  var
    Col : Integer;
  begin
    Col := Integer(Lo(WindMax)) + 1 - Length(St) + 1;
    FastWrite(St, Word(Row) + Hi(WindMin), Word(Col), Attr);
  end;

  procedure FastRead(Number : Byte; Row, Col : Word; var St : string);
    {-Read Number characters from the screen into St starting at Row,Col}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    St[0] := Chr(Number);
    for J := 1 to Number do
      St[J] := Chr(GetCell(I+J-1) and $FF);
  end;

  procedure ReadAttribute(Number : Byte; Row, Col : Word; var St : string);
    {-Read Number attributes from the screen into St starting at Row,Col}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    St[0] := Chr(Number);
    for J := 1 to Number do
      St[J] := Chr(GetCell(I+J-1) shr 8);
  end;

  procedure MoveScreen(var Source, Dest; Length : Word);
    {-Move Length words from Source to Dest without snow}
  var
    D : PtrUInt;
  begin
    if Length = 0 then
      Exit;
    Move(Source, Dest, LongInt(Length) * 2);
    D := PtrUInt(@Dest);
    if (D >= PtrUInt(VideoBuffer)) and
       (D < PtrUInt(VideoBuffer) + PtrUInt(PageBytes)) then
      ScreenChanged;
  end;

  procedure FastWriteAttr(St : String; Row, Col : Word; AttrSt : String);
    {-Write St at Row,Col using attributes in AttrSt}
  var
    I, J : LongInt;
    A : Byte;
  begin
    I := Idx0(Row, Col);
    A := $07;
    for J := 1 to Length(St) do begin
      if J <= Length(AttrSt) then
        A := Ord(AttrSt[J]);
      PutCell(I+J-1, (Word(A) shl 8) or Ord(St[J]));
    end;
    VTouch;
  end;

  procedure FlexWrite(St : string; Row, Col : Word; var FAttrs : FlexAttrs);
    {-Write St at Row,Col with flexible color handling}
  var
    I, J, N : LongInt;
    C : Byte;
    ChStack : array[0..255] of Byte;
    AtStack : array[0..255] of Byte;
    Sp : Integer;
  begin
    I := Idx0(Row, Col);
    Sp := 0;
    ChStack[0] := 0;
    AtStack[0] := FAttrs[0];
    N := 0;
    for J := 1 to Length(St) do begin
      C := Ord(St[J]);
      if (C >= 1) and (C <= 3) then begin
        {^A..^C toggle an attribute; repeating the active one pops it}
        if (ChStack[Sp] = C) and (Sp > 0) then
          Dec(Sp)
        else begin
          Inc(Sp);
          ChStack[Sp] := C;
          AtStack[Sp] := FAttrs[C];
        end;
      end
      else begin
        PutCell(I+N, (Word(AtStack[Sp]) shl 8) or C);
        Inc(N);
      end;
    end;
    VTouch;
  end;

  function FlexLen(S : string) : Byte;
    {-Return actual (visible) length of a flex string}
  var
    J, N : Integer;
  begin
    N := 0;
    for J := 1 to Length(S) do
      if (S[J] = #0) or (S[J] > #3) then
        Inc(N);
    FlexLen := N;
  end;

  procedure FastWriteCtrl(St : String; Row, Col : Word; Attr, Ctrl : Byte);
    {-Write St at Row,Col in Attr (video attribute) without snow.
      Control characters displayed in Ctrl as upper-case letters}
  var
    I, J : LongInt;
  begin
    I := Idx0(Row, Col);
    for J := 1 to Length(St) do
      if St[J] < ' ' then
        PutCell(I+J-1, (Word(Ctrl) shl 8) or (Ord(St[J]) + 64))
      else
        PutCell(I+J-1, (Word(Attr) shl 8) or Ord(St[J]));
    VTouch;
  end;

  function SaveWindow(XLow, YLow, XHigh, YHigh : Byte; Allocate : Boolean;
                      var Covers : Pointer) : Boolean;
    {-Allocate buffer space if requested and save window contents}
  var
    CoversP : BufPtr absolute Covers;
    WordsPerRow : Word;
    BufBytes : LongInt;
    SrcPos : LongInt;
    DestPos : LongInt;
    Row : Word;
  begin
    {assume success}
    SaveWindow := True;

    {compute number of words to move per row}
    WordsPerRow := Succ(XHigh-XLow);

    if Allocate then begin
      {compute bytes needed for screen buffer}
      BufBytes := (LongInt(WordsPerRow)*Succ(YHigh-YLow)) shl 1;

      {make sure enough memory is available}
      GetMem(CoversP, BufBytes);
    end;

    {save current contents to the screen buffer}
    DestPos := 0;
    SrcPos := (Pred(YLow)*LongInt(VirtualWidth)+Pred(XLow)) shl 1;
    for Row := YLow to YHigh do begin
      MoveScreen(PByte(PtrUInt(VirtualBuffer)+SrcPos)^, CoversP^[DestPos],
                 WordsPerRow);
      Inc(SrcPos, LongInt(VirtualWidth) shl 1);
      Inc(DestPos, LongInt(WordsPerRow) shl 1);
    end;
  end;

  procedure RestoreWindow(XLow, YLow, XHigh, YHigh : Byte;
                          Deallocate : Boolean; var Covers : Pointer);
    {-Restore screen contents and deallocate buffer space if requested}
  var
    CoversP : BufPtr absolute Covers;
    WordsPerRow : Word;
    SrcPos : LongInt;
    DestPos : LongInt;
    Row : Word;
  begin
    {compute number of words to move per row}
    WordsPerRow := Succ(XHigh-XLow);

    {Restore current contents to the screen buffer}
    DestPos := 0;
    SrcPos := (Pred(YLow)*LongInt(VirtualWidth)+Pred(XLow)) shl 1;
    for Row := YLow to YHigh do begin
      MoveScreen(CoversP^[DestPos], PByte(PtrUInt(VirtualBuffer)+SrcPos)^,
                 WordsPerRow);
      Inc(SrcPos, LongInt(VirtualWidth) shl 1);
      Inc(DestPos, LongInt(WordsPerRow) shl 1);
    end;
    VTouch;

    {deallocate buffer space if requested}
    if Deallocate then begin
      FreeMem(CoversP, (LongInt(WordsPerRow)*Succ(YHigh-YLow)) shl 1);
      CoversP := nil;
    end;
  end;

  procedure ClearWindow(XLow, YLow, XHigh, YHigh : Word; Ch : Char; A : Byte);
    {-Clear a window using the specified character and attribute}
  var
    Row, Width : Word;
  begin
    Width := Succ(XHigh-XLow);
    for Row := YLow to YHigh do
      FastFill(Width, Ch, Row, XLow, A);
  end;

  procedure FrameWindow(LeftCol, TopRow, RightCol, BotRow : Word;
                        FAttr, HAttr : Byte; Header : string);
    {-Draws a frame around a window}
  var
    HeaderLen : Byte absolute Header;
    Row, Width, HeaderPos : Word;
  begin
    {calculate width of window}
    if RightCol <= LeftCol then     {!!.03}
      Width := 0                    {!!.03}
    else                            {!!.03}
      Width := RightCol-LeftCol-1;

    {draw the upper border}
    FastFill(1,     FrameChars[frTL], TopRow, LeftCol, FAttr);
    if Width > 0 then               {!!.03}
      FastFill(Width, FrameChars[frTT], TopRow, LeftCol+1, FAttr);
    FastFill(1,     FrameChars[frTR], TopRow, RightCol, FAttr);

    {draw the header}
    if HeaderLen > 0 then begin
      if HeaderLen > Width then
        HeaderLen := Width;
      HeaderPos := (Width-HeaderLen) shr 1;
      FastWrite(Header, TopRow, LeftCol+HeaderPos+1, HAttr);
    end;

    {draw the vertical bars}
    for Row := Succ(TopRow) to Pred(BotRow) do begin
      FastFill(1, FrameChars[frLL], Row, LeftCol, FAttr);
      FastFill(1, FrameChars[frRR], Row, RightCol, FAttr);
    end;

    {draw the bottom border}
    FastFill(1,     FrameChars[frBL], BotRow, LeftCol, FAttr);
    if Width > 0 then      {!!.03}
      FastFill(Width, FrameChars[frBB], BotRow, LeftCol+1, FAttr);
    FastFill(1,     FrameChars[frBR], BotRow, RightCol, FAttr);
  end;

  function MapColor(C : Byte) : Byte;
    {-Map a video attribute for visibility on mono/bw displays}
  begin
    if UseColor then
      MapColor := C
    else
      MapColor := ColorMap[C];
  end;

  function UseColor : Boolean;
    {-Returns True if color video attributes should be used}
  begin
    if (DefColorChoice <> UseDefault) then
      UseColor := (DefColorChoice = ForceColor)
    else case CurrentMode of
      0, 2 :
        UseColor := False;
      7 :
        UseColor := (WhichHerc = HercInColor);
      else
        UseColor := True;
    end;
  end;

  function ColorMono(Color, Mono : Byte) : Byte;
    {-Choose between a color and a monochrome video attribute}
  begin
    if UseColor then
      ColorMono := Color
    else
      ColorMono := Mono;
  end;

  function MapMono(Color, Mono : Byte) : Byte;
    {-Return a mapped video attribute if Mono = $FF}
  begin
    if Mono = AutoMapMono then
      MapMono := ColorMap[Color]
    else
      MapMono := Mono;
  end;

  procedure StoreWindowCoordinates(var WC : WindowCoordinates);
    {-Store the window coordinates for the active window}
  type
    XY = record
           X, Y : Byte;
         end;
  begin
    with WC do begin
      XL := Succ(XY(WindMin).X);
      YL := Succ(XY(WindMin).Y);
      XH := Succ(XY(WindMax).X);
      YH := Succ(XY(WindMax).Y);
    end;
  end;

  procedure RestoreWindowCoordinates(WC : WindowCoordinates);
    {-Restore previously saved window coordinates}
  begin
    with WC do
      Window(XL, YL, XH, YH);
  end;

  procedure ColorSet.SetTextAttr(Color, Mono : Byte);
    {-Set attribute for ordinary text}
  begin
    TextColor := Color;
    TextMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetCtrlAttr(Color, Mono : Byte);
    {-Set attribute for control characters}
  begin
    CtrlColor := Color;
    CtrlMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetFrameAttr(Color, Mono : Byte);
    {-Set attribute for frames}
  begin
    FrameColor := Color;
    FrameMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetHeaderAttr(Color, Mono : Byte);
    {-Set attribute for headers}
  begin
    HeaderColor := Color;
    HeaderMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetShadowAttr(Color, Mono : Byte);
    {-Set attribute for shadows}
  begin
    ShadowColor := Color;
    ShadowMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetHighlightAttr(Color, Mono : Byte);
    {-Set attribute for highlighted text}
  begin
    HighlightColor := Color;
    HighlightMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetPromptAttr(Color, Mono : Byte);
    {-Set attribute for prompts}
  begin
    PromptColor := Color;
    PromptMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetSelectedPromptAttr(Color, Mono : Byte);
    {-Set attribute for prompts}
  begin
    SelPromptColor := Color;
    SelPromptMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetProtectedPromptAttr(Color, Mono : Byte);
    {-Set attribute for protected prompts}
  begin
    ProPromptColor := Color;
    ProPromptMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetFieldAttr(Color, Mono : Byte);
    {-Set attribute for unselected fields}
  begin
    FieldColor := Color;
    FieldMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetSelectedFieldAttr(Color, Mono : Byte);
    {-Set attribute for selected fields}
  begin
    SelFieldColor := Color;
    SelFieldMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetProtectedFieldAttr(Color, Mono : Byte);
    {-Set attribute for protected/disabled fields}
  begin
    ProFieldColor := Color;
    ProFieldMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetScrollBarAttr(Color, Mono : Byte);
    {-Set attribute for scroll bars}
  begin
    ScrollBarColor := Color;
    ScrollBarMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetSliderAttr(Color, Mono : Byte);
    {-Set attribute for sliders in scroll bars}
  begin
    SliderColor := Color;
    SliderMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetHotSpotAttr(Color, Mono : Byte);
    {-Set attribute for hot spots in frame corners}
  begin
    HotSpotColor := Color;
    HotSpotMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetBlockAttr(Color, Mono : Byte);
    {-Set attribute for marked blocks}
  begin
    BlockColor := Color;
    BlockMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetMarkerAttr(Color, Mono : Byte);
    {-Set attribute for text markers}
  begin
    MarkerColor := Color;
    MarkerMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetDelimAttr(Color, Mono : Byte);
    {-Set attribute for unselected delimiters}
  begin
    DelimColor := Color;
    DelimMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetSelectedDelimAttr(Color, Mono : Byte);
    {-Set attribute for selected delimiters}
  begin
    SelDelimColor := Color;
    SelDelimMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetProtectedDelimAttr(Color, Mono : Byte);
    {-Set attribute for protected/disabled delimiters}
  begin
    ProDelimColor := Color;
    ProDelimMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetSelectedItemAttr(Color, Mono : Byte);
    {-Set attribute for selected pick and menu items}
  begin
    SelItemColor := Color;
    SelItemMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetProtectedItemAttr(Color, Mono : Byte);
    {-Set attribute for protected pick and menu items}
  begin
    ProItemColor := Color;
    ProItemMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetHighlightItemAttr(Color, Mono : Byte);
    {-Set attribute for protected pick and menu items}
  begin
    HighItemColor := Color;
    HighItemMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetAltItemAttr(Color, Mono : Byte);    {!!.01}
    {-Set attributes for alternate pick items}
  begin
    AltItemColor := Color;
    AltItemMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetAltSelItemAttr(Color, Mono : Byte); {!!.01}
    {-Set attributes for alternate selected pick items}
  begin
    AltSelItemColor := Color;
    AltSelItemMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetFlexAHelpAttr(Color, Mono : Byte);
    {-Set attribute for help text surrounded by ^A}
  begin
    FlexAHelpColor := Color;
    FlexAHelpMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetFlexBHelpAttr(Color, Mono : Byte);
    {-Set attribute for help text surrounded by ^B}
  begin
    FlexBHelpColor := Color;
    FlexBHelpMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetFlexCHelpAttr(Color, Mono : Byte);
    {-Set attribute for help text surrounded by ^C}
  begin
    FlexCHelpColor := Color;
    FlexCHelpMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetUnselXrefAttr(Color, Mono : Byte);
    {-Set attribute for unselected help cross-references}
  begin
    UnselXrefColor := Color;
    UnselXrefMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetSelXrefAttr(Color, Mono : Byte);
    {-Set attribute for selected help cross-references}
  begin
    SelXrefColor := Color;
    SelXrefMono := MapMono(Color, Mono);
  end;

  procedure ColorSet.SetMouseAttr(Color, Mono : Byte);
    {-Set attribute for mouse cursor}
  begin
    MouseColor := Color;
    MouseMono := MapMono(Color, Mono);
  end;


  procedure InitCrt;
    {-Initialize CRT variables}
  begin
    NextChar := 0;
    CtrlBreakFlag := False;
    CurX := 0;
    CurY := 0;
    CursorSL := $0607;
    ReInitCrt;
    TextAttr := $07;
    NormalAttr := $07;
  end;

  procedure InitConsole;
  var
    I : Integer;
  begin
    ConsoleOK := False;
    KbdOK := False;
    PhysW := 80;
    PhysH := 25;
    if StdIsConsole(True) and StdIsConsole(False) then begin
      Video.InitVideo;
      if (Video.ErrorCode = errOk) and (Video.VideoBuf <> nil) then begin
        ConsoleOK := True;
        PhysW := Video.ScreenWidth;
        PhysH := Video.ScreenHeight;
        VideoBuffer := Pointer(Video.VideoBuf);
        {$IFDEF WINDOWS}
        {the Video unit writes ANSI text, so use code page 437 to show the
         library's CP437 characters correctly}
        SavedOutCP := GetConsoleOutputCP;
        SavedInCP := GetConsoleCP;
        CPSaved := True;
        if SetConsoleOutputCP(437) = 0 then ;
        if SetConsoleCP(437) = 0 then ;
        {$ENDIF}
      end;
    end;
    if StdIsConsole(False) then begin
      Keyboard.InitKeyboard;
      KbdOK := True;
    end;
    if not ConsoleOK then begin
      {no usable console: work on a private 80x25 buffer}
      GetMem(OwnBuf, LongInt(PhysW)*PhysH*2);
      for I := 0 to LongInt(PhysW)*PhysH-1 do
        PCells(OwnBuf)^[I] := $0720;
      VideoBuffer := OwnBuf;
    end;
    VirtualBuffer := VideoBuffer;
  end;

  procedure DoneCrt;
    {-Restore the console. Called automatically at program exit.}
  var
    I : Integer;
  begin
    if Finished then
      Exit;
    Finished := True;
    Dirty := True;
    FlushScreen;
    if ConsoleOK then begin
      CurX := 0;
      CurY := PhysH-1;
      CursorSL := $0607;
      Dirty := True;
      FlushScreen;
    end;
    if KbdOK then begin
      Keyboard.DoneKeyboard;
      KbdOK := False;
    end;
    if ConsoleOK then begin
      ConsoleOK := False;
      {$IFDEF WINDOWS}
      if CPSaved then begin
        if SetConsoleOutputCP(SavedOutCP) = 0 then ;
        if SetConsoleCP(SavedInCP) = 0 then ;
      end;
      {$ENDIF}
      Video.DoneVideo;
    end;
    {the buffers are left allocated so late screen writes stay harmless}
  end;

  procedure CrtExitProc;
  begin
    ExitProc := SaveExitProc;
    DoneCrt;
  end;

begin
  RawCheckKbdProc := RawCheckKbdFunc(@NativeCheckKbd);
  RawReadKeyWordProc := RawReadKeyWordFunc(@NativeReadKeyWord);
  CheckBreak := True;
  CheckEOF := False;
  DirectVideo := True;
  CheckSnow := False;
  SaveCtrlC := False;
  LastMode := CO80;
  Finished := False;
  KeyQHead := 0;
  KeyQCount := 0;
  EofCount := 0;
  VisiblePage := 0;
  ActivePageNo := 0;
  Dirty := False;
  InitConsole;
  SaveExitProc := ExitProc;
  ExitProc := @CrtExitProc;
  InitCrt;
  DelayCalibrate;
  if ConsoleOK then begin
    AssignCrt(Input);
    Reset(Input);
    AssignCrt(Output);
    Rewrite(Output);
  end;
end.
