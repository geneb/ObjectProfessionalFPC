
{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$IFDEF Dpmi}                                                         {!!.20}
  !! This unit cannot be used in protected mode !!                    {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F-,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                    OPTSR.PAS 1.30                     *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpTsr;
  {-TSR management routines}
  { FPC port: stubbed because TSRs (resident popups, interrupt hooks, INT 21h/31h)
    have no equivalent on Windows/Linux.  OpInt is no longer used here. }

interface

uses
  Dos, OpInline;

type
  IfcPtr = ^IfcRecord;
  IfcRecord =
    record                   {** don't change order **}
      NamePtr : ^string;
      Version : Word;
      CmdEntryPtr : Pointer;
      PrevIfc,
      NextIfc : IfcPtr;
    end;
  PopupProc = procedure(var Regs : Registers);
const
  MaxPopups = 8;             {maximum number of popup routines}
  SideKickLoaded : Boolean = False; {if True, SideKick is loaded}
  Int5Handle = 1;            {ISR handles used by our interrupt handlers}
  Int8Handle = 2;
  Int9Handle = 3;
  Int10Handle = 4;
  Int13Handle = 5;
  Int14Handle = 6;
  Int16Handle = 7;
  Int17Handle = 8;
  Int25Handle = 9;
  Int26Handle = 10;
  Int28Handle = 11;
var
  ThisIfc : IfcRecord;

  {Flags for popups in use}
  PopupInUse : array[1..MaxPopups] of Boolean;

  {pointers to variables hidden in OPTSR.OBJ}
  PopTickerPtr : ^Word;        {Points to var. indicating if we are trying to pop up}
  PopupsEnabledPtr : ^Boolean; {Points to flag indicating if popups are enabled}
  PopupToCallPtr : ^Byte;      {Points to var. with the handle of a popup to call}
const
  ReleaseEms : Boolean = False;

function ParagraphsToKeep : Word;
  {-Returns # of paragraphs currently used for code, data, stack, and heap.}

function MaxParagraphsToKeep : Word;
  {-Maximum number of paragraphs to keep when going resident}

procedure StayRes(ParasToKeep : Word; ExitCode : Byte);
  {-Terminate and stay resident, freeing up all our memory except ParasToKeep.
    Returns only if unable to go resident.}

procedure GrabKeyboard; {!!.01}
  {-Enable option to regrab keyboard interrupt if necessary}

procedure PopupsOn;
  {-Turns popups on}

procedure PopupsOff;
  {-Turns popups off}

function DefinePopProc(var Handle : Byte;
                       Routine : PopupProc;
                       StackPtr : Pointer) : Boolean;
 {-Defines a routine that can be triggered by calling SetPopTicker. Returns
   false if no more Popup handles are available.}

procedure DeletePopProc(Handle : Byte);
 {-Deletes a popup routine defined with DefinePopProc.  Its handle may then
   be used for other popups.}

function DefinePop(HotKey : Word; Routine : PopupProc;
                   StackPtr : Pointer; DosWait : Boolean) : Boolean;
 {-Defines a popup routine associated with a particular hotkey. Returns
   False if no more Popup handles are available.}

procedure DeletePop(HotKey : Word);
  {-Deletes the popup routine associated with HotKey.  Its handle may then
    be used for other popups.}

function ChangeHotKey(OldHotKey, NewHotKey : Word) : Boolean;
  {-Change a popup's hotkey from OldHotKey to NewHotKey}

function AddHotKey(PrimaryHotKey, SecondaryHotKey : Word) : Boolean;
  {-Add a second hot key for the popup with the specified primary hot key}

procedure SetPopTicker(Handle : Byte; TimeOut : Word);
 {-Sets the pop ticker for the indicated procedure, clears interrupts,
   then returns.  No range checking is performed.}

procedure RemovePops;
 {-Removes all popup routines from the system and releases all associated
   interrupt vectors}

procedure InitPops;
  {-Must be called before any other popup specific routines}

function DisableTSR : Boolean;
  {-Disable TSR by restoring interrupt vectors and releasing memory. This
    does *not* halt the program. Returns False if it's not safe.}

function SafeToDisable : Boolean;
  {-Returns True if it is safe to disable the TSR}

procedure InstallModule(var ModuleName : string; CmdEntryRoutine : Pointer);
 {-Installs this program as a resident module that can be located and
   accessed by other programs.}

procedure UninstallModule;
  {-Uninstalls the module from the linked list of modules}

function ModulePtrByName(var ModuleName : string) : IfcPtr;
  {-Returns a pointer to the IfcRecord for the module named ModuleName or Nil}

function ModuleInstalled(var ModuleName : string) : Boolean;
  {-Returns true if ModuleName is installed.}

function DosBusyFlag : Byte;
  {-Returns current value of DOS busy flag}

function DosCriticalFlag : Byte;
  {-Returns current value of DOS critical flag}

function GetReturnVec(IntNum : Byte) : Pointer;         {!!.03}
  {-Get interrupt vector in ISR table}

procedure SetVecOnReturn(IntNum : Byte; ISR : Pointer);         {!!.03}
  {-Set interrupt vector in ISR table (takes effect when popup returns)}

procedure SuppressMouseHandling;                                {!!.13}
  {-Stops TSR routines from turning the mouse cursor on or off automatically}

function GetPSP : Word;
  {-Returns current PSP}

procedure SetPSP(PSP : Word);
  {-Sets current PSP}

  {==========================================================================}

implementation

{ FPC port: stubbed because a DOS TSR (hooking INT 05/08/09/10/13/14/16/17/25/
  26/28, going resident with INT 21h/31h, hot-key popups driven from the
  keyboard interrupt, DOS busy/critical flags, PSP switching) cannot exist on
  Windows/Linux.  Kept as real portable code: the popup/hot key tables and the
  module-list bookkeeping.  Nothing can ever trigger a popup.  StayRes returns
  (= "unable to go resident"); SafeToDisable/DisableTSR return False; the
  paragraph functions return 0; DosBusyFlag/DosCriticalFlag return 0. }

const
  WentResident : Boolean = False;
  IfcInstalled : Boolean = False;
  Initialized : Boolean = False;
  MaxScanCode = $58;         {highest scan code we can use -- do not change}
  IfcVersion = $400;         {version number of interface}
  IRET : Byte = $CF;
type
  OurVectorType =
    record
      Int02 : Pointer;
      Int1B : Pointer;
      Int21 : Pointer;
      Int23 : Pointer;
      Int24 : Pointer;
    end;
var
  {Addresses of popup routines}
  PopupAddrs : array[1..MaxPopups] of PopupProc;

  {Stacks for popup routines}
  PopupStacks : array[1..MaxPopups] of Pointer;

  {Flags to indicate popups that need access to DOS}
  DosWaitFlags : array[1..MaxPopups] of Boolean;

  {Table linking scan codes to their associated popups}
  PopupKeys : array[0..MaxScanCode] of Byte;

  {contains the high byte of each popup's hotkey}
  ShiftKeys : array[0..MaxScanCode] of Byte;

  {replacements for the variables hidden in OPTSR.OBJ}
  LocalPopTicker : Word;
  LocalPopupsEnabled : Boolean;
  LocalPopupToCall : Byte;
  PrivateVectors : OurVectorType;

  function IsNilProc(var P) : Boolean;
  begin
    IsNilProc := Pointer(P) = nil;
  end;

  function GetPSP : Word;
    {-Returns current PSP}
  begin
    { FPC port: stubbed because there is no PSP }
    GetPSP := 0;
  end;

  procedure SetPSP(PSP : Word);
    {-Sets current PSP}
  begin
    { FPC port: stubbed because there is no PSP }
  end;

  function ParagraphsToKeep : Word;
    {-Returns # of paragraphs currently used for code, data, stack, and heap.}
  begin
    { FPC port: stubbed because there is no PSP/heap paragraph layout }
    ParagraphsToKeep := 0;
  end;

  function MaxParagraphsToKeep : Word;
    {-Maximum number of paragraphs to keep when going resident}
  begin
    { FPC port: stubbed because there is no PSP/heap paragraph layout }
    MaxParagraphsToKeep := 0;
  end;

  procedure PopupsOn;
    {-Turns popups on}
  begin
    PopupsEnabledPtr^ := True;
  end;

  procedure PopupsOff;
    {-Turns popups off}
  begin
    PopupsEnabledPtr^ := False;
  end;

  function ChangeHotKey(OldHotKey, NewHotKey : Word) : Boolean;
    {-Change a hotkey from OldHotKey to NewHotKey}
  var
    Handle : Byte;
    OldScan, NewScan : Byte;
  begin
    OldScan := Lo(OldHotKey);
    NewScan := Lo(NewHotKey);
    ChangeHotKey := False;
    case NewScan of
      1..MaxScanCode : {ok} ;
      else Exit;
    end;
    case OldScan of
      1..MaxScanCode :
        if (PopupKeys[OldScan] <> 0) and
        ((OldScan = NewScan) or (PopupKeys[NewScan] = 0)) then begin
          {get rid of the current assignment}
          Handle := PopupKeys[OldScan];
          PopupKeys[OldScan] := 0;
          ShiftKeys[OldScan] := 0;

          PopupKeys[NewScan] := Handle;
          ShiftKeys[NewScan] := Hi(NewHotKey);
          ChangeHotKey := True;
        end;
    end;
  end;

  function AddHotKey(PrimaryHotKey, SecondaryHotKey : Word) : Boolean;
    {-Add a second hot key for the popup with the specified primary hot key}
  var
    PScan, SScan : Byte;
  begin
    PScan := Lo(PrimaryHotKey);
    SScan := Lo(SecondaryHotKey);
    AddHotKey := False;
    case SScan of
      1..MaxScanCode :
        if (PScan <= MaxScanCode) and
           (PopupKeys[PScan] <> 0) and (PopupKeys[SScan] = 0) then begin
          PopupKeys[SScan] := PopupKeys[PScan];
          ShiftKeys[SScan] := Hi(SecondaryHotKey);
          AddHotKey := True;
        end;
    end;
  end;

  procedure DeletePop(HotKey : Word);
    {-Deletes the popup routine associated with HotKey. Its handle may then
      be used for other popups.}
  var
    Handle : Byte;
    I : Word;
  begin
    case Lo(HotKey) of
      1..MaxScanCode :
        begin
          Handle := PopupKeys[Lo(HotKey)];
          if (Handle <> 0) then begin
            PopupAddrs[Handle] := nil;
            for I := 1 to MaxScanCode do
              if PopupKeys[I] = Handle then begin
                PopupKeys[I] := 0;
                ShiftKeys[I] := 0;
              end;
          end;
        end;
    end;
  end;

  function DefinePopProc(var Handle : Byte;
                         Routine : PopupProc;
                         StackPtr : Pointer) : Boolean;
    {-Defines a routine that can be triggered by calling SetPopTicker. Returns
      false if no more Popup handles are available.}
  var
    B : Byte;
  begin
    {search for an available handle}
    for B := 1 to MaxPopups do
      if IsNilProc(PopupAddrs[B]) then begin
        Handle := B;
        PopupAddrs[B] := Routine;
        PopupStacks[B] := StackPtr;
        PopupInUse[B] := False;

        {assume that waiting is necessary}
        DosWaitFlags[B] := True;

        DefinePopProc := True;
        Exit;
      end;

    {if we get to here we failed}
    DefinePopProc := False;
  end;

  procedure DeletePopProc(Handle : Byte);
    {-Deletes a popup routine defined with DefinePopProc.  Its handle may then
      be used for other popups.}
  begin
    case Handle of
      1..MaxPopups : PopupAddrs[Handle] := nil;
    end;
  end;

  function DefinePop(HotKey : Word; Routine : PopupProc;
                     StackPtr : Pointer; DosWait : Boolean) : Boolean;
    {-Defines a popup routine associated with a particular hotkey. Returns
      False if no more Popup handles are available.}
  var
    B : Byte;
  begin
    {assume failure}
    DefinePop := False;

    case Lo(HotKey) of
      1..MaxScanCode :
        if PopupKeys[Lo(HotKey)] = 0 then
          if DefinePopProc(B, Routine, StackPtr) then begin
            DosWaitFlags[B] := DosWait;
            ShiftKeys[Lo(HotKey)] := Hi(HotKey);
            PopupKeys[Lo(HotKey)] := B;
            DefinePop := True;
          end;
    end;
  end;

  procedure SetPopTicker(Handle : Byte; TimeOut : Word);
    {-Sets the pop ticker for the indicated procedure, clears interrupts,
      then returns.  No range checking is performed.}
  begin
    if PopupsEnabledPtr^ then
      if (not IsNilProc(PopupAddrs[Handle])) and not PopupInUse[Handle] then begin
        if PopTickerPtr^ <> 0 then
          PopupInUse[PopupToCallPtr^] := False;
        PopupInUse[Handle] := True;
        PopupToCallPtr^ := Handle;
        PopTickerPtr^ := TimeOut;
      end;
  end;

  procedure RemovePops;
    {-Disables all popups and releases all interrupt vectors.}
  begin
    PopupsOff;
    { FPC port: no interrupt vectors were captured, nothing to restore }
    Initialized := False;
  end;

  procedure GrabKeyboard; {!!.01}
    {-Enable option to regrab keyboard interrupt if necessary}
  begin
    { FPC port: stubbed because there is no keyboard/timer interrupt to grab }
  end;

  procedure StayRes(ParasToKeep : Word; ExitCode : Byte);
    {-Terminate and stay resident, freeing up all our memory except ParasToKeep.
      Returns only if unable to go resident.}
  begin
    { FPC port: stubbed because a TSR (INT 21h/31h) is impossible on
      Windows/Linux; returns as the original does when going resident fails }
    WentResident := False;
  end;

  procedure InitPops;
    {-Must be called before any other popup specific routines.}
  begin
    {don't do this twice}
    if Initialized then
      Exit;

    { FPC port: no SideKick to detect and no interrupt vectors to hook }
    SideKickLoaded := False;

    {Initialize our tables}
    FillChar(PopupAddrs, SizeOf(PopupAddrs), 0);
    FillChar(PopupStacks, SizeOf(PopupStacks), 0);
    FillChar(PopupInUse, SizeOf(PopupInUse), 0);
    FillChar(PopupKeys, SizeOf(PopupKeys), 0);
    FillChar(ShiftKeys, SizeOf(ShiftKeys), 0);
    FillChar(DosWaitFlags, SizeOf(DosWaitFlags), 0);

    LocalPopTicker := 0;
    LocalPopupsEnabled := False;
    LocalPopupToCall := 0;
    PopTickerPtr := @LocalPopTicker;
    PopupsEnabledPtr := @LocalPopupsEnabled;
    PopupToCallPtr := @LocalPopupToCall;

    Initialized := True;
  end;

  function GetLastModulePtr : Pointer;
    {-Return a pointer to the last OPRO TSR loaded before us}
  begin
    { FPC port: stubbed because the module chain was discovered through an
      INT 16h signature call and the 40:F0 intra-applications area; with no
      resident modules the original returns Nil }
    GetLastModulePtr := nil;
  end;

  procedure InstallModule(var ModuleName : string; CmdEntryRoutine : Pointer);
    {-Installs this program as a resident module that can be located and
      accessed by other programs.}
  var
    P : IfcPtr;
  begin
    if not IfcInstalled then
      with ThisIfc do begin
        {see if anyone else is home}
        P := IfcPtr(GetLastModulePtr);
        if P <> nil then begin
          P^.NextIfc := @ThisIfc;
          PrevIfc := P;
        end
        else
          PrevIfc := nil;

        NamePtr := @ModuleName;
        NextIfc := nil;
        Version := IfcVersion;
        if CmdEntryRoutine = nil then
          CmdEntryPtr := @IRET
        else
          CmdEntryPtr := CmdEntryRoutine;

        IfcInstalled := True;
      end;
  end;

  procedure UninstallModule;
    {-Uninstalls the module from the linked list of modules.}
  begin
    if IfcInstalled then
      with ThisIfc do begin
        {fix the linked list of modules}
        if PrevIfc <> nil then
          PrevIfc^.NextIfc := NextIfc;
        if NextIfc <> nil then
          NextIfc^.PrevIfc := PrevIfc;
        IfcInstalled := False;
      end;
  end;

  function ModulePtrByName(var ModuleName : string) : IfcPtr;
    {-Returns a pointer to the IfcRecord for the module named ModuleName or Nil.}
  var
    P : IfcPtr;
  begin
    P := IfcPtr(GetLastModulePtr);
    ModulePtrByName := nil;

    {search backward through the list}
    while (P <> nil) do
      with P^ do
        if NamePtr^ = ModuleName then begin
          ModulePtrByName := P;
          Exit;
        end
        else
          P := P^.PrevIfc;
  end;

  function ModuleInstalled(var ModuleName : string) : Boolean;
    {-Returns true if ModuleName is installed.}
  begin
    ModuleInstalled := ModulePtrByName(ModuleName) <> nil;
  end;

  function SafeToDisable : Boolean;
    {-Returns True if it is safe to disable the TSR}
  begin
    { FPC port: stubbed because the program can never go resident }
    SafeToDisable := False;
  end;

  function DisableTSR : Boolean;
    {-Disable TSR by restoring interrupt vectors and releasing memory. This
      does *not* halt the program. Returns False if it's not safe.}
  begin
    { FPC port: stubbed because the program can never go resident }
    DisableTSR := False;
  end;

  function DosBusyFlag : Byte;
    {-Returns current value of DOS busy flag}
  begin
    { FPC port: stubbed because there is no InDOS flag; DOS is never busy }
    DosBusyFlag := 0;
  end;

  function DosCriticalFlag : Byte;
    {-Returns current value of DOS critical flag}
  begin
    { FPC port: stubbed because there is no DOS critical-error flag }
    DosCriticalFlag := 0;
  end;

  function GetReturnVec(IntNum : Byte) : Pointer;         {!!.03}
    {-Get interrupt vector in ISR table}
  begin
    with PrivateVectors do
      case IntNum of
        $02 : GetReturnVec := Int02;
        $1B : GetReturnVec := Int1B;
        $21 : GetReturnVec := Int21;
        $23 : GetReturnVec := Int23;
        $24 : GetReturnVec := Int24;
        else  GetReturnVec := nil;
      end;
  end;

  procedure SetVecOnReturn(IntNum : Byte; ISR : Pointer);         {!!.03}
    {-Set interrupt vector in ISR table (takes effect when popup returns)}
  begin
    with PrivateVectors do
      case IntNum of
        $02 : Int02 := ISR;
        $1B : Int1B := ISR;
        $21 : Int21 := ISR;
        $23 : Int23 := ISR;
        $24 : Int24 := ISR;
      end;
  end;

  procedure SuppressMouseHandling;
  begin
    { FPC port: stubbed because there is no resident mouse-cursor handling }
  end;

begin
  {initialize interface record}
  FillChar(ThisIfc, SizeOf(ThisIfc), 0);
  FillChar(PrivateVectors, SizeOf(PrivateVectors), 0);

  {prepare for popups}
  InitPops;
end.
