{$I opdefine.inc}

{*********************************************************}
{*                   OPMOUSE.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1988, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpMouse;
  {-Mouse interface routines. Designed for use in text mode only.

    FPC port notes: the INT $33 driver interface (OPMOUSE.ASM/OPMOUSE2.ASM)
    is re-implemented on FPC's Mouse unit. Mouse events are polled (at
    MousePressed, MouseKeyWord, MouseWhere*, MouseGotoXY, MouseButton* and
    friends) and the user event routine (MouseRoutine) is called from that
    polling point instead of from an interrupt. All coordinates keep their
    original meaning (1-based character cells, relative to the mouse window
    unless "abs").

    The mouse cursor is drawn the way the text mode driver did it: by
    modifying the cell under the pointer in OPCRT's physical screen buffer
    (VideoBuffer). The original cell is restored when the pointer moves or is
    hidden.

    FPC port: stubbed because there is no driver to talk to:
      - HardMouseCursor: the hardware cursor shape cannot be set per mouse;
        it is emulated with the default software cursor (attribute inversion,
        $FFFF/$7700) and a start line >= $20 hides the cursor
      - GetMickeyCount/SetMickeyToPixelRatio: mickeys are estimated from
        character cell movement; the ratio has no effect on pointer speed
      - GetMousePage/SetMousePage: single page only
      - MouseStateBufferSize/SaveMouseState/RestoreMouseState: no driver
        state exists, so the size is 0 and save/restore do nothing}

interface

uses
  OpCrt;

var
  MouseInstalled : Boolean;  {True if a mouse is installed}
  MouseButtons : Byte;       {Number of mouse buttons (0, 2, 3)}
  MouseCursorOn : Boolean;   {True if mouse cursor is visible}

type
  ButtonStatus = (
    NoButton, LeftButton, RightButton, BothButtons,
    {the following values are possible only on a 3-button mouse}
    CenterButton, LeftAndCenterButtons, RightAndCenterButtons, All3Buttons);

const
  DisableEventHandler  = $00;
  MouseMoved           = $01;
  LeftButtonPressed    = $02;
  LeftButtonReleased   = $04;
  RightButtonPressed   = $08;
  RightButtonReleased  = $10;
  CenterButtonPressed  = $20;
  CenterButtonReleased = $40;
  AllMouseEvents       = $7F;
type
  MouseEventType = DisableEventHandler..AllMouseEvents;

const
  DefaultScreenMask = $FFFF;
  DefaultCursorMask = $7700;

type
  MouseState =
    record
      BufSize : Word;
      Buffer : array[1..400] of Byte;
    end;
  MouseStatePtr = ^MouseState;

var
  {current window coordinates for mouse}
  MouseXLo : Byte;           {0-based}
  MouseYLo : Byte;           {0-based}
  MouseXHi : Byte;           {1-based}
  MouseYHi : Byte;           {1-based}

const
  {if True, MouseKeyWord waits for the button to be released before returning
   its key code}
  WaitForButtonRelease : Boolean = True;

  {pseudo-scan codes returned by MouseKeyWord--DO NOT CHANGE THESE}
  MouseLft    = $EF00;       {left button}
  MouseRt     = $EE00;       {right button}
  MouseBoth   = $ED00;       {both buttons}
  MouseCtr    = $EC00;       {center button}
  MouseLftCtr = $EB00;       {left and center buttons}
  MouseRtCtr  = $EA00;       {right and center buttons}
  MouseThree  = $E900;       {all three buttons}
var
  MouseKeyWordX : Byte;      {mouse coordinates at time of call to MouseKeyWord}
  MouseKeyWordY : Byte;

const
  MouseRoutine : Pointer = nil;
  MouseRoutineEvent : MouseEventType = DisableEventHandler;

  MouseEvent : MouseEventType = DisableEventHandler;
  MouseStatus : ButtonStatus = NoButton;
  MouseLastX : Byte = 1;
  MouseLastY : Byte = 1;

function MousePressed : Boolean;
  {-Return True if a mouse button is currently being pressed}

function MouseKeyWord : Word;
  {-Return a pseudo-scan code based on which mouse button is being pressed}

function KeyOrButtonPressed : Boolean;
  {-Return True if a key or mouse button has been pressed}

function ReadKeyOrButton : Word;
  {-Return next key or mouse button}

procedure EnableEventHandling;
  {-Enable the event handler needed for MousePressed and MouseKeyWord}

procedure DisableEventHandling;
  {-Disable the event handler installed by EnableEventHandling}

procedure InitializeMouse;
  {-Reinitializes mouse and sets MouseInstalled}

procedure ShowMouse;
  {-Show the mouse cursor.}

procedure HideMouse;
  {-Hide the mouse cursor}

procedure MouseWhereXY(var MouseX, MouseY : Byte; var Status : ButtonStatus);
  {-Return mouse position and button status}

function MouseWhereX : Byte;
  {-Return current X coordinate for mouse}

function MouseWhereY : Byte;
  {-Return current Y coordinate for mouse}

procedure MouseWhereXYabs(var MouseX, MouseY : Byte; var Status : ButtonStatus);
  {-Return mouse position (absolute) and button status}

function MouseWhereXabs : Byte;
  {-Return current X coordinate (absolute) for mouse}

function MouseWhereYabs : Byte;
  {-Return current Y coordinate (absolute) for mouse}

procedure MouseGotoXY(MouseX, MouseY : Byte);
  {-Set mouse position}

function MouseButtonPressed(Button : ButtonStatus; var Count : Word;
                            var LastX, LastY : Byte) : Boolean;
  {-Returns True if the Button to check has been pressed. If so, Count has the
    number of times it has been pressed, and LastX/LastY have its position the
    last time it was pressed.}

function MouseButtonReleased(Button : ButtonStatus; var Count : Word;
                             var LastX, LastY : Byte) : Boolean;
  {-Returns True if the Button to check has been released. If so, Count has the
    number of times it has been released, and LastX/LastY have its position the
    last time it was released.}

procedure MouseWindow(XLow, YLow, XHigh, YHigh : Byte);
  {-Sets window coordinates to be observed by the mouse}

procedure FullMouseWindow;
  {-Sets mouse window coordinates to full screen}

procedure StoreMouseCoordinates(var WC : WindowCoordinates);
  {-Store the mouse window coordinates in WC}

procedure RestoreMouseCoordinates(WC : WindowCoordinates);
  {-Restore previously saved mouse window coordinates}

function MouseInWindow(XLo, YLo, XHi, YHi : Byte) : Boolean;
  {-Return True if mouse is within the specified window}

procedure SoftMouseCursor(ScreenMask, CursorMask : Word);
  {-Set mouse to use a software cursor}

procedure HardMouseCursor(StartLine, EndLine : Word);
  {-Set mouse to use the hardware cursor. StartLine and EndLine specify the
    shape of the cursor.}

procedure NormalMouseCursor;
  {-Set normal scan lines for mouse cursor based on current video mode}

procedure FatMouseCursor;
  {-Set larger scan lines for mouse cursor based on current video mode}

procedure BlockMouseCursor;
  {-Set scan lines for a block mouse cursor}

procedure HiddenMouseCursor;
  {-Hide the mouse cursor}

procedure GetMickeyCount(var Horizontal, Vertical : Integer);
  {-Returns the horizontal and vertical mickey count since the last call to
    this function. Negative numbers indicate movement up or to the left;
    positive numbers indicate movement down or to the right.}

procedure SetMickeyToPixelRatio(Horizontal, Vertical : Integer);
  {-Sets the mickey-to-pixel ratio. Default setting is 8,16. A setting of
    16,32 slows down the mouse considerably. A setting of 4,8 makes the
    mouse fly.}

procedure SetMouseEventHandler(EventMask : MouseEventType; UserRoutine : Pointer);
  {-Sets the address of a routine to be called when the specified mouse
    events occur. FPC port: the routine (a plain "procedure;") is called
    from the polling points listed in the unit header, not from an
    interrupt. Information about the Event is passed to UserRoutine using the
    global variables MouseEvent, MouseStatus, MouseLastX, and MouseLastY}

  {-- The remaining routines may not be implemented by all mouse drivers!! --}

function GetMousePage : Byte;
  {-Returns the video page where the mouse is being displayed}
  {-- May not be implemented in all mouse drivers!! --}

procedure SetMousePage(Page : Byte);
  {-Sets the video page where the mouse will be displayed}
  {-- May not be implemented in all mouse drivers!! --}

  {-- the following routines are intended primarily for use in TSR's --}

function MouseStateBufferSize : Word;
  {-Returns amount of memory needed to save the state of the mouse driver}

procedure SaveMouseState(var MSP : MouseStatePtr; Allocate : Boolean);
  {-Save the state of the mouse driver, allocating the buffer if requested.}

procedure RestoreMouseState(var MSP : MouseStatePtr; Deallocate : Boolean);
  {-Restore the state of the mouse driver and Deallocate the buffer if
    requested}

procedure HideMousePrim(var MouseState : Boolean);
  {-Save state of mouse cursor in MouseState and hide it}

procedure ShowMousePrim(MouseState : Boolean);
  {-Hide or unhide the mouse cursor}

  {==========================================================================}

implementation

uses
  SysUtils,
  Mouse;

type
  CellArray = array[0..65534] of Word;
  CellPtr = ^CellArray;
  EventProc = procedure;

var
  SaveExitProc : Pointer;
  EventHandlerInstalled : Boolean;
  MouseStarted : Boolean;      {Mouse unit initialized}
  InPoll : Boolean;            {guards against re-entry from MouseRoutine}

  CurX, CurY : Integer;        {pointer position, 0-based absolute cell}
  Buttons : Byte;              {current button bits: 1 left, 2 right, 4 center}
  PressCnt, ReleaseCnt : array[0..2] of Word;
  PressX, PressY, ReleaseX, ReleaseY : array[0..2] of Byte;

  CursorSoft : Boolean;        {software cursor (else emulated hardware)}
  ScrMask, CurMask : Word;
  HardStart : Word;
  Drawn : Boolean;             {cursor currently drawn into the buffer}
  DrawnIdx : Longint;
  DrawnCell, SavedCell : Word;

  MickX, MickY : Integer;      {cell movement since GetMickeyCount}
  RatioX : Integer;
  RatioY : Integer;

  function CellCount : Longint;
  begin
    CellCount := Longint(ScreenWidth)*Longint(ScreenHeight);
  end;

  procedure EraseCursor;
    {-Put back the cell under the cursor, unless the program overwrote it}
  var
    Cells : CellPtr;
  begin
    if Drawn then begin
      Drawn := False;
      Cells := CellPtr(VideoBuffer);
      if (Cells <> nil) and (DrawnIdx < CellCount) then
        if Cells^[DrawnIdx] = DrawnCell then
          Cells^[DrawnIdx] := SavedCell;
    end;
  end;

  procedure DrawCursor;
    {-Draw the cursor by modifying the cell under the pointer}
  var
    Cells : CellPtr;
    Idx : Longint;
    Old, New : Word;
  begin
    if Drawn or not MouseCursorOn or not MouseInstalled then
      Exit;
    Cells := CellPtr(VideoBuffer);
    if Cells = nil then
      Exit;
    Idx := Longint(CurY)*Longint(ScreenWidth)+CurX;
    if (Idx < 0) or (Idx >= CellCount) then
      Exit;
    Old := Cells^[Idx];
    if CursorSoft then
      New := (Old and ScrMask) xor CurMask
    else if HardStart >= $20 then
      New := Old
    else
      New := (Old and DefaultScreenMask) xor DefaultCursorMask;
    if New <> Old then begin
      Cells^[Idx] := New;
      Drawn := True;
      DrawnIdx := Idx;
      DrawnCell := New;
      SavedCell := Old;
    end;
  end;

  procedure Redraw;
  begin
    EraseCursor;
    DrawCursor;
    FlushScreen;
  end;

  procedure ClampPos(var X, Y : Integer);
  begin
    if X >= MouseXHi then
      X := MouseXHi-1;
    if X < MouseXLo then
      X := MouseXLo;
    if Y >= MouseYHi then
      Y := MouseYHi-1;
    if Y < MouseYLo then
      Y := MouseYLo;
  end;

  procedure MoveTo(X, Y : Integer);
    {-Move the pointer, redrawing the cursor}
  begin
    ClampPos(X, Y);
    if (X <> CurX) or (Y <> CurY) then begin
      Inc(MickX, X-CurX);
      Inc(MickY, Y-CurY);
      EraseCursor;
      CurX := X;
      CurY := Y;
      DrawCursor;
      FlushScreen;
    end;
  end;

  function RelX : Byte;
  begin
    RelX := CurX-MouseXLo+1;
  end;

  function RelY : Byte;
  begin
    RelY := CurY-MouseYLo+1;
  end;

  procedure HandleEvent(var E : TMouseEvent);
    {-Port of MouseEventHandler: update state and call the user routine}
  var
    NewB, Bit, Ev, Shown : Byte;
    I, NX, NY : Integer;
    P : EventProc;
  begin
    Ev := 0;
    NX := E.x;
    NY := E.y;
    ClampPos(NX, NY);
    if (NX <> CurX) or (NY <> CurY) then begin
      Ev := MouseMoved;
      MoveTo(NX, NY);
    end;

    NewB := E.Buttons and 7;
    for I := 0 to 2 do begin
      Bit := 1 shl I;
      if ((NewB and Bit) <> 0) and ((Buttons and Bit) = 0) then begin
        Inc(PressCnt[I]);
        PressX[I] := RelX;
        PressY[I] := RelY;
        Ev := Ev or (2 shl (2*I));
      end
      else if ((NewB and Bit) = 0) and ((Buttons and Bit) <> 0) then begin
        Inc(ReleaseCnt[I]);
        ReleaseX[I] := RelX;
        ReleaseY[I] := RelY;
        Ev := Ev or (4 shl (2*I));
      end;
    end;
    Buttons := NewB;

    if (Ev <> 0) and EventHandlerInstalled then begin
      {clear the MouseMoved bit unless this is a move-only event}
      Shown := Ev;
      if Shown <> MouseMoved then
        Shown := Shown and $FE;
      MouseEvent := Shown;
      MouseStatus := ButtonStatus(Buttons);
      MouseLastX := RelX;
      MouseLastY := RelY;
      if ((Ev and MouseRoutineEvent) <> 0) and (MouseRoutine <> nil) then begin
        P := EventProc(MouseRoutine);
        P;
      end;
    end;
  end;

  procedure PollEvents;
    {-Drain the Mouse unit's event queue}
  var
    E : TMouseEvent;
  begin
    if not MouseInstalled or not MouseStarted or InPoll then
      Exit;
    InPoll := True;
    while Mouse.PollMouseEvent(E) do begin
      Mouse.GetMouseEvent(E);
      HandleEvent(E);
    end;
    InPoll := False;
  end;

  procedure WaitTick;
    {-Replacement for INT $28: yield while waiting for a mouse event}
  begin
    FlushScreen;
    SysUtils.Sleep(1);
    PollEvents;
  end;

  procedure ShowMouseLow;
  begin
    if MouseInstalled then begin
      MouseCursorOn := True;
      Redraw;
    end;
  end;

  procedure HideMouseLow;
  begin
    if MouseInstalled then begin
      EraseCursor;
      MouseCursorOn := False;
      FlushScreen;
    end;
  end;

  procedure ResetState;
  var
    I : Integer;
  begin
    EraseCursor;
    MouseCursorOn := False;
    EventHandlerInstalled := False;
    MouseRoutine := nil;
    MouseRoutineEvent := DisableEventHandler;
    MouseEvent := DisableEventHandler;
    MouseStatus := NoButton;
    for I := 0 to 2 do begin
      PressCnt[I] := 0;
      ReleaseCnt[I] := 0;
      PressX[I] := 1;
      PressY[I] := 1;
      ReleaseX[I] := 1;
      ReleaseY[I] := 1;
    end;
    Buttons := 0;
    CursorSoft := True;
    ScrMask := DefaultScreenMask;
    CurMask := DefaultCursorMask;
    HardStart := 0;
    MickX := 0;
    MickY := 0;
    RatioX := 8;
    RatioY := 16;
    MouseXLo := 0;
    MouseYLo := 0;
    MouseXHi := ScreenWidth;
    MouseYHi := ScreenHeight;
    CurX := ScreenWidth div 2;
    CurY := ScreenHeight div 2;
    MouseLastX := RelX;
    MouseLastY := RelY;
  end;

  procedure InitializeMouse;
    {-Reinitializes mouse and sets MouseInstalled}
  var
    N : Word;
  begin
    if not MouseStarted then begin
      MouseInstalled := False;
      MouseButtons := 0;
      if CrtHasConsole then begin
        N := Mouse.DetectMouse;
        if N > 0 then begin
          Mouse.InitMouse;
          MouseStarted := True;
          MouseInstalled := True;
          if N > 3 then
            N := 3;
          MouseButtons := N;
        end;
      end;
    end;
    if MouseInstalled then
      ResetState;
  end;

  function MousePressed : Boolean;
    {-Return True if a mouse button is currently being pressed}
  begin
    if not(MouseInstalled and EventHandlerInstalled) then
      MousePressed := False
    else begin
      PollEvents;
      MousePressed := MouseStatus <> NoButton;
    end;
  end;

  function MouseKeyWord : Word;
    {-Return a pseudo scan code based on which key is being pressed}
  const
    ScanTable : array[LeftButton..All3Buttons] of Word = (MouseLft, MouseRt,
      MouseBoth, MouseCtr, MouseLftCtr, MouseRtCtr, MouseThree);
    BitsTable : array[ButtonStatus] of Byte = (0, 1, 1, 2, 1, 2, 2, 3);
  var
    Status, TempStatus : ButtonStatus;
    SaveBitsOn, BitsOn : Byte;
  begin
    {return bogus key code if no mouse or event handler not installed}
    if not(MouseInstalled and EventHandlerInstalled) then begin
      MouseKeyWord := $FFFF;
      Exit;
    end;

    {wait for a button to be pressed}
    PollEvents;
    Status := MouseStatus;
    while Status = NoButton do begin
      WaitTick;
      Status := MouseStatus;
    end;

    if WaitForButtonRelease then begin
      {save the current number of buttons that are on}
      SaveBitsOn := BitsTable[Status];

      {wait for the button(s) now being pressed to be released}
      TempStatus := MouseStatus;
      while (Byte(TempStatus) and Byte(Status)) <> 0 do begin
        {see if an additional button has been pressed}
        BitsOn := BitsTable[TempStatus];
        if BitsOn > SaveBitsOn then begin
          {another button was pressed--we want it too}
          Status := TempStatus;
          SaveBitsOn := BitsOn;
        end;

        WaitTick;
        TempStatus := MouseStatus;
      end;
    end;

    {return pseudo-scan code}
    MouseKeyWord := ScanTable[Status];

    {save current mouse coordinates}
    MouseKeyWordX := MouseLastX;
    MouseKeyWordY := MouseLastY;
  end;

  procedure ShowMouse;
    {-Show the mouse cursor.}
  begin
    if not MouseCursorOn then
      ShowMouseLow;
  end;

  procedure HideMouse;
    {-Hide the mouse cursor}
  begin
    if MouseCursorOn then
      HideMouseLow;
  end;

  procedure HideMousePrim(var MouseState : Boolean);
    {-Save state of mouse cursor in MouseState and hide it}
  begin
    MouseState := MouseCursorOn;
    if MouseCursorOn then
      HideMouseLow;
  end;

  procedure ShowMousePrim(MouseState : Boolean);
    {-Hide or unhide the mouse cursor}
  begin
    if MouseState then
      ShowMouse
    else
      HideMouse;
  end;

  procedure MouseWhereXY(var MouseX, MouseY : Byte; var Status : ButtonStatus);
    {-Return mouse position and button status}
  begin
    if MouseInstalled then begin
      PollEvents;
      Status := ButtonStatus(Buttons);
      MouseX := RelX;
      MouseY := RelY;
    end;
  end;

  function MouseWhereX : Byte;
    {-Return current X coordinate for mouse}
  begin
    if MouseInstalled then begin
      PollEvents;
      MouseLastX := RelX;
      MouseWhereX := MouseLastX;
    end
    else
      MouseWhereX := 0;
  end;

  function MouseWhereY : Byte;
    {-Return current Y coordinate for mouse}
  begin
    if MouseInstalled then begin
      PollEvents;
      MouseLastY := RelY;
      MouseWhereY := MouseLastY;
    end
    else
      MouseWhereY := 0;
  end;

  procedure MouseGotoXY(MouseX, MouseY : Byte);
    {-Set mouse position}
  begin
    if not MouseInstalled then
      Exit;
    PollEvents;
    if (MouseX < 1) or (MouseY < 1) then
      Exit;
    {check against the current window}
    if (Word(MouseY)+MouseYLo > MouseYHi) or (Word(MouseX)+MouseXLo > MouseXHi) then
      Exit;
    MoveTo(Pred(Word(MouseX)+MouseXLo), Pred(Word(MouseY)+MouseYLo));
    MouseLastX := RelX;
    MouseLastY := RelY;
  end;

  function ButtonIndex(Button : ButtonStatus) : Integer;
    {-Map LeftButton/RightButton/CenterButton to 0..2, else -1}
  begin
    case Button of
      LeftButton : ButtonIndex := 0;
      RightButton : ButtonIndex := 1;
      CenterButton : ButtonIndex := 2;
    else
      ButtonIndex := -1;
    end;
  end;

  function MouseButtonPressed(Button : ButtonStatus; var Count : Word;
                              var LastX, LastY : Byte) : Boolean;
    {-Returns True if the Button to check has been pressed.}
  var
    I : Integer;
  begin
    Count := 0;
    MouseButtonPressed := False;
    if not MouseInstalled then
      Exit;
    PollEvents;
    I := ButtonIndex(Button);
    if I < 0 then
      Exit;
    Count := PressCnt[I];
    LastX := PressX[I];
    LastY := PressY[I];
    PressCnt[I] := 0;
    MouseButtonPressed := Count <> 0;
  end;

  function MouseButtonReleased(Button : ButtonStatus; var Count : Word;
                               var LastX, LastY : Byte) : Boolean;
    {-Returns True if the Button to check has been released.}
  var
    I : Integer;
  begin
    Count := 0;
    MouseButtonReleased := False;
    if not MouseInstalled then
      Exit;
    PollEvents;
    I := ButtonIndex(Button);
    if I < 0 then
      Exit;
    Count := ReleaseCnt[I];
    LastX := ReleaseX[I];
    LastY := ReleaseY[I];
    ReleaseCnt[I] := 0;
    MouseButtonReleased := Count <> 0;
  end;

  procedure MouseWindow(XLow, YLow, XHigh, YHigh : Byte);
    {-Sets window coordinates to be observed by the mouse}
  begin
    if not MouseInstalled then
      Exit;
    {validate all parameters BEFORE setting any window coordinates}
    if (XLow < 1) or (YLow < 1) or (XHigh < 1) or (YHigh < 1) then
      Exit;
    if (XLow > XHigh) or (XHigh > ScreenWidth) then
      Exit;
    if (YLow > YHigh) or (YHigh > ScreenHeight) then
      Exit;

    MouseXLo := XLow-1;
    MouseYLo := YLow-1;
    MouseXHi := XHigh;
    MouseYHi := YHigh;

    {the driver keeps the pointer inside the new window}
    MoveTo(CurX, CurY);
  end;

  procedure SoftMouseCursor(ScreenMask, CursorMask : Word);
    {-Set mouse to use a software cursor}
  begin
    if not MouseInstalled then
      Exit;
    CursorSoft := True;
    ScrMask := ScreenMask;
    CurMask := CursorMask;
    if MouseCursorOn then
      Redraw;
  end;

  procedure HardMouseCursor(StartLine, EndLine : Word);
    {-Set mouse to use the hardware cursor (emulated, see unit header)}
  begin
    if not MouseInstalled then
      Exit;
    CursorSoft := False;
    HardStart := StartLine;
    if MouseCursorOn then
      Redraw;
  end;

  function GetMousePage : Byte;
    {FPC port: stubbed because there is only one text page}
  begin
    GetMousePage := 0;
  end;

  procedure SetMousePage(Page : Byte);
    {FPC port: stubbed because there is only one text page}
  begin
  end;

  procedure GetMickeyCount(var Horizontal, Vertical : Integer);
    {-Returns the mickey count since the last call (estimated from cells)}
  begin
    Horizontal := 0;
    Vertical := 0;
    if not MouseInstalled then
      Exit;
    PollEvents;
    Horizontal := MickX*RatioX;
    Vertical := MickY*RatioY;
    MickX := 0;
    MickY := 0;
  end;

  procedure SetMickeyToPixelRatio(Horizontal, Vertical : Integer);
    {FPC port: stubbed because the pointer speed is set by the OS; the ratio
     only scales the values returned by GetMickeyCount}
  begin
    if MouseInstalled then begin
      RatioX := Horizontal;
      RatioY := Vertical;
    end;
  end;

  procedure FullMouseWindow;
    {-Sets mouse window coordinates to full screen}
  begin
    MouseWindow(1, 1, ScreenWidth, ScreenHeight);
  end;

  procedure NormalMouseCursor;
    {-Set normal scan lines for mouse cursor based on current video mode}
  var
    ScanLines : Word;
  begin
    if Font8x8Selected then
      ScanLines := $0507
    else if CurrentMode = 7 then
      ScanLines := $0B0C
    else
      ScanLines := $0607;
    HardMouseCursor(Hi(ScanLines), Lo(ScanLines));
  end;

  procedure FatMouseCursor;
    {-Set larger scan lines for mouse cursor based on current video mode}
  var
    ScanLines : Word;
  begin
    if Font8x8Selected then
      ScanLines := $0307
    else if CurrentMode = 7 then
      ScanLines := $090C
    else
      ScanLines := $0507;
    HardMouseCursor(Hi(ScanLines), Lo(ScanLines));
  end;

  procedure BlockMouseCursor;
    {-Set scan lines for a block mouse cursor}
  var
    EndLine : Byte;
  begin
    if Font8x8Selected or (CurrentMode <> 7) then
      EndLine := $07
    else
      EndLine := $0C;
    HardMouseCursor(0, EndLine);
  end;

  procedure HiddenMouseCursor;
    {-Hide the mouse cursor}
  begin
    HardMouseCursor($20, 0);
  end;

  procedure StoreMouseCoordinates(var WC : WindowCoordinates);
    {-Store the mouse window coordinates in WC}
  begin
    with WC do begin
      XL := Succ(MouseXLo);
      YL := Succ(MouseYLo);
      XH := MouseXHi;
      YH := MouseYHi;
    end;
  end;

  procedure RestoreMouseCoordinates(WC : WindowCoordinates);
    {-Restore previously saved window coordinates}
  begin
    with WC do
      MouseWindow(XL, YL, XH, YH);
  end;

  function MouseInWindow(XLo, YLo, XHi, YHi : Byte) : Boolean;
    {-Return True if mouse is within the specified window}
  var
    mX, mY : Byte;
    Status : ButtonStatus;
  begin
    if not MouseInstalled then
      MouseInWindow := False
    else begin
      {get current position of mouse and see if it's inside the window}
      MouseWhereXY(mX, mY, Status);
      MouseInWindow := (mX >= XLo) and (mX <= XHi) and (mY >= YLo) and (mY <= YHi);
    end;
  end;

  function MouseStateBufferSize : Word;
    {FPC port: stubbed because there is no driver state to save}
  begin
    MouseStateBufferSize := 0;
  end;

  procedure SaveMouseState(var MSP : MouseStatePtr; Allocate : Boolean);
    {FPC port: stubbed because there is no driver state to save}
  begin
    if Allocate then
      MSP := nil;
  end;

  procedure RestoreMouseState(var MSP : MouseStatePtr; Deallocate : Boolean);
    {FPC port: stubbed because there is no driver state to restore}
  begin
    if (MSP <> nil) and Deallocate then begin
      FreeMem(MSP, MSP^.BufSize);
      MSP := nil;
    end;
  end;

  procedure EnableEventHandling;
    {-Enable the event handler needed for MousePressed and MouseKeyWord}
  begin
    if MouseInstalled and not EventHandlerInstalled then
      EventHandlerInstalled := True;
  end;

  procedure SetMouseEventHandler(EventMask : MouseEventType; UserRoutine : Pointer);
    {-Sets the address of a routine to be called when the specified mouse
      events occur}
  begin
    {make sure a mouse is installed}
    if not MouseInstalled then
      Exit;

    if EventMask = DisableEventHandler then
      MouseRoutine := nil
    else
      MouseRoutine := UserRoutine;
    if MouseRoutine = nil then
      MouseRoutineEvent := DisableEventHandler
    else
      MouseRoutineEvent := EventMask;

    {enable the event handler if it isn't already}
    EnableEventHandling;
  end;

  procedure DisableEventHandling;
    {-Disable the event handler installed by EnableEventHandling}
  begin
    if EventHandlerInstalled then begin
      EventHandlerInstalled := False;

      {reset variables}
      MouseRoutine := nil;
      MouseRoutineEvent := DisableEventHandler;
      MouseEvent := DisableEventHandler;
      MouseStatus := NoButton;
    end;
  end;

  function KeyOrButtonPressed : Boolean;
    {-Return True if a key or mouse button has been pressed}
  begin
    KeyOrButtonPressed := KeyPressed or MousePressed;
  end;

  function ReadKeyOrButton : Word;
    {-Return next key or mouse button}
  var
    I : Word;
  begin
    I := $FFFF;
    repeat
      if KeyPressed then
        I := ReadKeyWord
      else if MousePressed then
        I := MouseKeyWord
      else
        WaitTick;
    until I <> $FFFF;
    ReadKeyOrButton := I;
  end;

  procedure MouseWhereXYabs(var MouseX, MouseY : Byte; var Status : ButtonStatus);
    {-Return mouse position (absolute) and button status}
  begin
    MouseWhereXY(MouseX, MouseY, Status);
    Inc(MouseX, MouseXLo);
    Inc(MouseY, MouseYLo);
  end;

  function MouseWhereXabs : Byte;
    {-Return current X coordinate (absolute) for mouse}
  begin
    MouseWhereXabs := MouseWhereX+MouseXLo;
  end;

  function MouseWhereYabs : Byte;
    {-Return current Y coordinate (absolute) for mouse}
  begin
    MouseWhereYabs := MouseWhereY+MouseYLo;
  end;

  procedure ExitHandler;
    {-Reinitialize and hide mouse on exit}
  begin
    {restore previous exit handler}
    ExitProc := SaveExitProc;

    if MouseInstalled then begin
      EraseCursor;
      MouseCursorOn := False;
      EventHandlerInstalled := False;
      MouseRoutine := nil;
      if MouseStarted then begin
        Mouse.DoneMouse;
        MouseStarted := False;
      end;
    end;
  end;

begin
  Drawn := False;
  InPoll := False;
  MouseStarted := False;
  MouseInstalled := False;
  MouseButtons := 0;
  MouseCursorOn := False;
  EventHandlerInstalled := False;

  {initialize the mouse if one is installed (sets MouseInstalled)}
  InitializeMouse;

  {no need to install exit handler if not installed}
  if MouseInstalled then begin
    FullMouseWindow;
    SaveExitProc := ExitProc;
    ExitProc := @ExitHandler;
  end;
end.
