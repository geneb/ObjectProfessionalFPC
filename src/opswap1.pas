
{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$IFDEF Dpmi}                                                         {!!.20}
  !! This unit cannot be used in protected mode !!                    {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F-,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                   OPSWAP1.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1989, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpSwap1;
  { FPC port: stubbed because TSR program swapping (interrupt hooks, EMS/XMS/disk
    swapping of the DOS program image) has no equivalent on Windows/Linux.
    See the note at the start of the implementation section. }

interface

uses
  Dos,
  OpInline;

const
  MaxPopups = 8;             {maximum number of user popups}
  MaxIsrs = 15;              {maximum number of ISRs}
  MaxScanCode = $58;         {highest scan code we can use -- do not change}
  {.Z+}
  NumIsrTable = 13;

  isrInt5      = 1;
  isrInt8      = 2;
  isrInt9      = 3;
  isrInt13     = 4;
  isrInt16     = 5;
  isrInt25     = 6;
  isrInt26     = 7;
  isrInt28     = 8;
  isrInt10     = 9;
  isrInt14     = 10;
  isrInt17     = 11;
  isrNOP       = 12;
  isrCmd       = 13;
  {.Z-}
  SwapFileMaxLen  = 67;
  EMSError     = 4;          {error code to indicate EMS error}
  DiskError    = 5;          {error code to indicate disk error}

  {OPSWAP option flags}      {!!.01}
  {changed to word            !!.02}
  SafeMouse    = $0001;      {use code to safely disable any mouse event
                              handlers when popping up in swapping mode}
  MSQuickFix   = $0002;      {uses special code to correct problem with
                              Microsoft Quick IDEs (only has meaning in
                              non-swapping mode}
  SingleSwap   = $0004;      {use single swap file}          {!!.02}
  EmsFlag      = $0008;      {using EMS}                     {!!.02}
  XmsFlag      = $0010;      {using XMS}                     {!!.02}
  SaveUarts    = $0020;      {saving/disabling UARTs while popped} {!!.13}

  SwappingEnabled : Boolean = False;      {True when swapping is active}
  SideKickLoaded : Boolean = False; {if True, SideKick is loaded}

  SwapUseEMS : Boolean = True;      {if False, EMS will not be used
                                     for swap even if available}
{$IFDEF SupportXms}
  SwapUseXms : Boolean = False;     {if False, XMS will not be used   !!.02}
  EmsOverXms : Boolean = True;      {if False, XMS will be checked    !!.02
                                     for sufficient space before EMS  !!.02}
{$ENDIF}
  ReleaseEms : Boolean = False;

type
  PopupProc = procedure;
  BytePtr   = ^Byte;

  {the following types are used internally by OsSwap}
  PopArray = array[1..MaxPopups] of PopupProc;
  StackArray = array[1..MaxPopups] of Pointer;
  PopBoolArray = array[1..MaxPopups] of Boolean;
  KeyArray = array[0..MaxScanCode] of Byte;
  Str20 = String[20];
  IsrRecord =
    record
      IntNum : Byte;         {Interrupt vector number}
      OrigAddr : Pointer;    {Original vector}
      NewAddr : Pointer;     {New vector}
      Captured : Boolean;    {Used for error checking}
    end;

  {global array of ISR records}
  IsrArrayType= array[1..MaxIsrs] of IsrRecord;
  CSSwapDataPtr = ^CSSwapDataType;
  IfcPtr = ^IfcRecord;
  IfcRecord =
    record                   {** don't change order **}
      NamePtr : ^string;
      Version : Word;
      CmdEntryPtr : PopupProc;
      PrevIfc,
      NextIfc : IfcPtr;
      CSDataPtr : CSSwapDataPtr;
      UserData  : Pointer;
    end;
  AsciiZ = Array[0..SwapFileMaxLen] of Char;

  {The following data type represents a data area within the code segment
   of the OPSwap unit.}
  CSSwapDataType =
    record
      PopupAddrs : PopArray;
      PopupStacks : StackArray;
      PopupInUse : PopBoolArray;
      PopUpKeys : KeyArray;
      ShiftKeys : KeyArray;
      IsrArray : IsrArrayType;
      PopTicker : Word;
      PopupToCall : Byte;
      PopupsEnabled : Boolean;
      DosVersion : Word;
      (* UsedEMS : Boolean; !!.02 *)
      PagesInEMS : Word;
      BytesSwapped : LongInt;
      EMSHandle : Word;
      FrameSeg : Word;
      FileHandle : Word;
      NewPrefixSeg : Word;
      EMSAllocated : Boolean;
      FileAllocated : Boolean;
      SwapMsgOn : Boolean;
      SwapMsgAttr : Byte;
      SwapMsgRow  : Byte;
      ThisIFC : IFCRecord;
      ModuleName : Str20;
      IFCInstalled : Boolean;
      Disable : Boolean;
      SwapEnabled : Boolean;
      SwapFile1,
      SwapFile2 : AsciiZ;
      IsrTable : Array[1..NumIsrTable] of Word;
      Vectors : Array[0..255] of Pointer;
      UartInts : Array[0..3] of Word; {!!.13}
      CmdEntryHandle : Byte;
      UserExitProc : PopupProc;
      LastEntrySS : Word;
      LastEntrySP : Word;
      LastEntryIP : Word;
      LastEntryCS : Word;
      NewInt3F    : Pointer;
      SwapFlags   : Word;            {!!.02}
      MouseSavePtr    : Pointer;
      MouseSaveFlags  : Word;
      FileAttr        : Word;        {!!.02}
      DosInUsePtr     : BytePtr;
      AllOfMem        : Word;        {!!.02}
      StartMCB        : Word;        {!!.02}
      XmsControlCS    : Pointer;     {!!.02}
    end;

  Dummy5 = array[1..5] of Word;
  {The IntRegisters type (from OpInt)}
  IntRegisters =
    record
      case Byte of
        1 : (BP, ES, DS, DI, SI, DX, CX, BX, AX, IP, CS, Flags : Word);
        2 : (Dummy : Dummy5; DL, DH, CL, CH, BL, BH, AL, AH : Byte);
    end;

const
  NilPointer       : Pointer = Nil;   {a pointer initialized to Nil}

var
  CSSwapData       : CSSwapDataPtr;   {a global pointer to the data in the
                                       OpSwap code segment}
  SaveSSeg         : Word;            {save our stack segment}
{$IFNDEF Heap6}                                                          {!!.10}
  TopOfHeap        : Pointer;         {pointer to the top of the TP heap}{!!.10}
{$ENDIF}                                                                 {!!.10}
  IntercomPtr      : function(Func : Byte) : Pointer; {for internal use}
  NoExternalIfc    : PopupProc absolute NilPointer; {a do nothing CmdEntryPtr}

{.Z+}
procedure InitCSSwapData;
  {-initialize the data in the code segment of OpSwap - for internal use}

procedure InitPops;
  {-Must be called before any other popup specific routines.}
{.Z-}

function AllocateStack(var P : Pointer; SizeInBytes : Word) : Boolean;
  {-Allocates a stack of size SizeInBytes}

procedure DeallocateStack(P : Pointer);
  {-Frees an allocated stack}

procedure PopupsOn;
  {-Turns popups on}

procedure PopupsOff;
  {-Turns popups off}

function ChangeHotKey(OldHotKey, NewHotKey : Word) : Boolean;
  {-Change a popup's hotkey from OldHotKey to NewHotKey}

function AddHotKey(PrimaryHotKey, SecondaryHotKey : Word) : Boolean;
  {-Add a second hot key for the popup with the specified primary hot key}

function DefinePop(HotKey : Word; Routine : PopupProc;
                   StackPtr : Pointer) : Boolean;
 {-Defines a popup routine associated with a particular hotkey. Returns
   False if no more Popup handles are available.}

procedure RestoreAllVectors;
  {-Restores all captured interrupt vectors}

function SwapSize(ParasToKeep : Word) : LongInt;
  {-Return the size in bytes of the area of memory to be swapped}

function WillSwapUseEms(ParasToKeep : Word) : Boolean;
  {-Returns True if OpSwap will use EMS memory for swapping}

{$IFDEF SupportXms}
function WillSwapUseXms(ParasToKeep : Word) : Boolean;        {!!.02}
  {-Returns True if OpSwap will use XMS memory for swapping}
{$ENDIF}

function ParagraphsToKeep : Word;
  {-Returns # of paragraphs currently used for code, data, stack, and heap}

function MaxParagraphsToKeep : Word;
  {-Maximum number of paragraphs to keep when going resident}

procedure StayResSwap(ParasToKeep : Word;
                      ExitCode : Byte;
                      SwapFileName1,
                      SwapFileName2 : String;
                      UseSwapping : Boolean);
 {-Terminate and stay resident.
   If UseSwapping is False, then the TSR does not use the swapping techniques
   and behaves like a normal TSR written with OpTSR (or TpTSR) }

function DisableTSR : Boolean;
 {-Disable TSR by restoring interrupt vectors and releasing memory. This
   does *not* halt the program. Returns false if it's not safe.}

function SafeToDisable : Boolean;
  {-Returns True if it is safe to disable the TSR}

procedure DisablePopup;
  {-An external interface procedure that attempts to disable the popup and
    reports the results in the UserData field of the IfcRecord. UserData is
    set to 1 on success.}

procedure InstallModule(var ModName : string; CmdEntryPtr : PopupProc);
 {-Installs this program as a resident module that can be located and
   accessed by other programs.}

procedure UninstallModule;
  {-Uninstalls the module from the linked list of modules.}

procedure SetSwapMsgAttr(Attr : Byte);
  {-Sets the attribute used by Swap manager for swap message}

procedure SetSwapMsgOn(On : Boolean);
  {-Turns Swap message on or off}

procedure SetSwapMsgRow(Row : Byte);
  {-Sets the row where swapping messages are to appear}

procedure SetUserExitProc(UserExitProc : PopupProc);
  {-Sets a pointer to a far procedure that is to be called before disabling
    the TSR}

function ModulePtrByName(var ModuleName : string) : IfcPtr;
  {-Returns a pointer to the IfcRecord for the module named ModuleName or Nil.}

function ModuleInstalled(var ModuleName : string) : Boolean;
  {-Returns true if ModuleName is installed.}

procedure EmulateInt(var Regs : IntRegisters; IntAddr : Pointer);
  {-Emulates an interrupt by filling the CPU registers with the values in Regs,
    clearing interrupts, pushing the flags, and calling far to IntAddr.}

function DosBusyFlag : Byte;
  {-Returns current value of DOS busy flag}

procedure SetVecOnReturn(IntNum : Byte; ISR : Pointer);
  {-Set int vector in ISR table (takes affect when popup returns)}

procedure SetQuickFixMode(On : Boolean); {!!.01}
  {-Enable or disable special fix for MS Quick (Basic, C) IDE problem. This
    option only has meaning when operating in non-swapping mode. When On is
    True, all ISR's will be swapped to the state they were in when the TSR
    loaded.}

procedure SetSingleSwapFile(On : Boolean);           {!!.02}
  {-If On is true, then uses single swap file. This cuts swapping disk
    space requirements in half. When using a single swap file, a small buffer
    is used in the resident kernel as an I/O buffer. This may reduce swap
    performance significantly compared to the default two swap file technique.

    This routine also has meaning when applied to XMS swapping. If the swap
    will be done to XMS, and SetSingleSwapFile has been called, then the XMS
    swap will be performed in a manner similar to that described above for
    single disk file swapping. This cuts the amount of XMS memory needed in
    half.

    The setting of single swap mode is relevant only when swapping to disk or
    XMS. If swapping to EMS, it is ignored.

    This routine must be called before StayResSwap, SwapSize,
    WillSwapUseEms, or WillSwapUseXms. Any calls made to SetSingleSwapFile
    routine after going resident will be ignored.

    Single swap file mode is recommended for use only on RAM disks. RAM disks
    will offer adequate performance despite the small I/O buffer since only
    memory access is required to read and write the swap file. The 50%
    reduction in swap file size is also very beneficial on a RAM disk.

    The size of the temporary buffer is dicated by the EQUate BufSize in
    OPSWAP.ASM. When in single swap file mode, BufSize bytes (plus a small
    amount of code overhead) are added to the always resident kernel. When
    operating in the default two swap file mode or when swapping to EMS or XMS
    memory, this extra space is not taken in the resident kernel (it is still
    a part of the program, so it is contained in the memory image written to
    the swap file or EMS).}

procedure SetSwapFileAttr(Hidden : Boolean);   {!!.02}
  {-If Hidden is True, then swap files will be created with attribute 6
    (hidden+ system), otherwise they will be created with attribute 0
    (normal)}

function WasCommandActive : Boolean;                           {!!.02}
  {-Returns True if COMMAND.COM was active at time of last popup}

procedure SetSaveComPorts(Enable : Boolean);
  {-Enables/disables saving of UART interrupt states while popped}

procedure InterruptsOn;
  {-Turn interrupts on}
  { FPC port: no longer an inline STI; now a do-nothing procedure }

procedure InterruptsOff;
  {-Turn interrupts off}
  { FPC port: no longer an inline CLI; now a do-nothing procedure }

  {==========================================================================}

implementation

{ FPC port: stubbed because the program swapping / TSR machinery cannot exist
  on Windows/Linux (it hooks interrupt vectors 05/08/09/10/13/14/16/17/25/26/28,
  copies the program image to EMS/XMS/disk, edits MCBs and the PSP, and ends
  with INT 21h function 31h).  What is kept as real, portable code: the
  hot key / popup definition tables, flag setters, stack allocation helpers and
  the module list bookkeeping, all operating on a heap-allocated
  CSSwapDataType that replaces the original code-segment data area.  Nothing
  can ever trigger a popup.  StayResSwap simply returns (the documented
  "failed to go resident" outcome); SwapSize, ParagraphsToKeep,
  MaxParagraphsToKeep return 0; WillSwapUseEms/Xms, SafeToDisable and
  DisableTSR return False. }

const
  WentResident : Boolean = False;
  IfcVersion = $400;         {version number of interface}

  CmdEntryHandle = 14;

  Initialized : Boolean = False;  {internal semaphore to flag need to init}
  TSRInitialized : Boolean = False;
  HiddenAttr  = 6;           {file attribute for hidden/system file}  {!!.02}
  NormalAttr  = 0;           {file attribute for normal file}         {!!.02}
  CommandBit  = $8000;       {bit set in SwapFlags if COMMAND active} {!!.02}

type
  StackRecord =
    record
      Size : Word;
      Address : Pointer;
    end;
  StackRecPtr = ^StackRecord;

var
  LocalSwapData : CSSwapDataType;     {replaces the data area in the code segment}

  procedure InterruptsOn;
    {-Turn interrupts on}
  begin
    { FPC port: stubbed because user programs cannot enable/disable interrupts }
  end;

  procedure InterruptsOff;
    {-Turn interrupts off}
  begin
    { FPC port: stubbed because user programs cannot enable/disable interrupts }
  end;

  procedure EmulateInt(var Regs : IntRegisters; IntAddr : Pointer);
    {-Emulates an interrupt}
  begin
    { FPC port: stubbed because there are no far-called real mode ISRs }
  end;

  function DosBusyFlag : Byte;
    {-Returns current value of DOS busy flag}
  begin
    { FPC port: stubbed because there is no InDOS flag; DOS is never busy }
    DosBusyFlag := 0;
  end;

  procedure SetUserExitProc(UserExitProc : PopupProc);
    {-Sets a pointer to a far procedure that is to be called before disabling
      the TSR}
  begin
    CSSwapData^.UserExitProc := UserExitProc;
  end;

  procedure InitCSSwapData;
    {-initializes the code segment relative data}
  begin
    { FPC port: no resident kernel entry points (Intercom 0..3) to fetch }
    Initialized := True;
    InitPops;
  end;

  procedure SetVecOnReturn(IntNum : Byte; ISR : Pointer);
    {-Set int vector in ISR table (takes affect when popup returns)}
  begin
    CSSwapData^.Vectors[IntNum] := ISR;
  end;

  procedure RestoreAllVectors;
    {-Restores all captured interrupt vectors}
  begin
    { FPC port: stubbed because no interrupt vectors are ever captured }
  end;

  function SwapSize(ParasToKeep : Word) : LongInt;
    {-Return the size in bytes of the area of memory to be swapped}
  begin
    { FPC port: stubbed because there is no DOS memory image to swap }
    SwapSize := 0;
  end;

  function WillSwapUseEms(ParasToKeep : Word) : Boolean;
    {-Returns True if OpSwap will use EMS memory for swapping}
  begin
    { FPC port: stubbed because EMS does not exist }
    WillSwapUseEms := False;
  end;

{$IFDEF SupportXms}
  function WillSwapUseXms(ParasToKeep : Word) : Boolean;
    {-Returns True if OpSwap will use XMS memory for swapping}
  begin
    { FPC port: stubbed because XMS does not exist }
    WillSwapUseXms := False;
  end;
{$ENDIF}

  procedure InitPops;
    {-Must be called before any other popup specific routines.}
  begin
    { FPC port: stubbed because there are no interrupt vectors to hook and
      no SideKick to detect }
    if TSRInitialized then
      Exit;
    SideKickLoaded := False;
    TSRInitialized := True;
  end;

  function AllocateStack(var P : Pointer; SizeInBytes : Word) : Boolean;
    {-This routine allocates a stack of size SizeInBytes}
  var
    Base : Pointer;
    ActualSize : LongInt;
  begin
    {allocate space for the stack record as well}
    ActualSize := LongInt(SizeInBytes)+SizeOf(StackRecord);

    {FPC port: MaxAvail check dropped; limit kept for the Word size field}
    if ActualSize <= 65521 then begin
      GetMem(Base, Word(ActualSize));

      {P points to where the stack record goes (top of the stack)}
      P := Pointer(PtrUInt(Base)+SizeInBytes);

      {save the address returned by GetMem and the # of bytes allocated}
      with StackRecPtr(P)^ do begin
        Address := Base;
        Size := Word(ActualSize);
      end;

      AllocateStack := True;
    end
    else
      AllocateStack := False;
  end;

  procedure DeallocateStack(P : Pointer);
    {-Frees an allocated stack}
  begin
    with StackRecPtr(P)^ do
      FreeMem(Address, Size);
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
    CSSwapData^.PopupsEnabled := True;
  end;

  procedure PopupsOff;
    {-Turns popups off}
  begin
    CSSwapData^.PopupsEnabled := False;
  end;

  function ChangeHotKey(OldHotKey, NewHotKey : Word) : Boolean;
    {-Change a hotkey from OldHotKey to NewHotKey}
  var
    Handle : Byte;
    OldScan : Byte;
    NewScan : Byte;
  begin
    OldScan := Lo(OldHotKey);
    NewScan := Lo(NewHotKey);
    with CSSwapData^ do begin
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
  end;

  function AddHotKey(PrimaryHotKey, SecondaryHotKey : Word) : Boolean;
    {-Add a second hot key for the popup with the specified primary hot key}
  var
    PScan : Byte;
    SScan : Byte;
  begin
    PScan := Lo(PrimaryHotKey);
    SScan := Lo(SecondaryHotKey);
    AddHotKey := False;
    with CSSwapData^ do
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

  function IsNilProc(var P) : Boolean;
  begin
    IsNilProc := Pointer(P) = nil;
  end;

  function DefinePopProc(var Handle : Byte; Routine : PopupProc;
                         StackPtr : Pointer) : Boolean;
    {-Defines a routine that can be triggered by calling SetPopTicker. Returns
      false if no more Popup handles are available.}
  var
    B : Byte;
  begin
    with CSSwapData^ do
      {search for an available handle}
      for B := 1 to MaxPopups do
        if IsNilProc(PopupAddrs[B]) then begin
          Handle := B;
          PopupAddrs[B] := Routine;
          PopupStacks[B] := StackPtr;
          PopupInUse[B] := False;
          DefinePopProc := True;
          Exit;
        end;

    {if we get to here we failed}
    DefinePopProc := False;
  end;

  function DefinePop(HotKey : Word; Routine : PopupProc;
                     StackPtr : Pointer) : Boolean;
    {-Defines a popup routine associated with a particular hotkey. Returns
      False if no more Popup handles are available.}
  var
    B : Byte;
  begin
    with CSSwapData^ do begin
      {assume failure}
      DefinePop := False;

      case Lo(HotKey) of
        1..MaxScanCode :
          if PopupKeys[Lo(HotKey)] = 0 then
            if DefinePopProc(B, Routine, StackPtr) then begin
              ShiftKeys[Lo(HotKey)] := Hi(HotKey);
              PopupKeys[Lo(HotKey)] := B;
              DefinePop := True;
            end;
      end;
    end;
  end;

  procedure InstallCmdEntryPtr(ProcPtr : PopupProc);
    {-Sets up a user-defined CmdEntryPtr}
  begin
    { FPC port: stubbed because the command entry point was a far address
      inside the resident ISR segment; no one can call it, so it stays Nil }
    CSSwapData^.ThisIfc.CmdEntryPtr := nil;
  end;

  function GetLastModulePtr : Pointer;
    {-Return a pointer to the last TPRO TSR loaded before us}
  begin
    { FPC port: stubbed because the module chain was discovered through an
      INT 16h signature call and the 40:F0 intra-applications area; with no
      resident modules the original returns Nil }
    GetLastModulePtr := nil;
  end;

  procedure InstallModule(var ModName : string; CmdEntryPtr : PopupProc);
   {-Installs this program as a resident module that can be located and
     accessed by other programs.}
  var
    P : IfcPtr;
  begin
    with CSSwapData^ do begin
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

          ModuleName := ModName;
          NamePtr := @ModuleName;
          NextIfc := nil;
          Version := IfcVersion;
          CSDataPtr := CSSwapData;
          IfcInstalled := True;
        end;
      InstallCmdEntryPtr(CmdEntryPtr);
    end;
  end;

  procedure UninstallModule;
    {-Uninstalls the module from the linked list of modules.}
  begin
    with CSSwapData^ do begin
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
  end;

  function ModulePtrByName(var ModuleName : string) : IfcPtr;
    {-Returns a pointer to the IfcRecord for the module named ModuleName or Nil}
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
    {-Returns true if ModuleName is installed}
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
      does *not* halt the program. Returns false if it's not safe.}
  begin
    { FPC port: stubbed because the program can never go resident }
    with CSSwapData^ do
      if not IsNilProc(UserExitProc) then
        UserExitProc;
    DisableTSR := False;
  end;

  procedure DisablePopup;
    {-An external interface procedure that attempts to disable the popup and
      reports the results in the UserData field of the IfcRecord. UserData is
      set to 1 on success.}
  begin
    CSSwapData^.ThisIFC.UserData := Pointer(PtrUInt(Ord(DisableTSR)));
  end;

  procedure StayResSwap(ParasToKeep : Word;
                        ExitCode : Byte;
                        SwapFileName1,
                        SwapFileName2 : String;
                        UseSwapping : Boolean);
   {-Terminate and stay resident. If we return from this call, we failed to
     go resident.}
  begin
    { FPC port: stubbed because a TSR (INT 21h/31h, swapping the image to
      EMS/XMS/disk) is impossible on Windows/Linux; returns as the original
      does when going resident fails }
    WentResident := False;
  end;

  procedure SetSingleSwapFile(On : Boolean);           {!!.02}
  begin
    {this must be set before going resident, otherwise it is ignored}
    if WentResident then
      Exit;
    if On then
      SetFlag(CSSwapData^.SwapFlags, SingleSwap)
    else
      ClearFlag(CSSwapData^.SwapFlags, SingleSwap);
  end;

  procedure SetQuickFixMode(On : Boolean); {!!.01}
  begin
    if On then
      SetFlag(CSSwapData^.SwapFlags, MSQuickFix)       {!!.02}
    else
      ClearFlag(CSSwapData^.SwapFlags, MSQuickFix);        {!!.02}
  end;

  procedure SetSwapMsgAttr(Attr : Byte);
    {-Sets the attribute used by Swap manager for swap message}
  begin
    CSSwapData^.SwapMsgAttr := Attr;
  end;

  procedure SetSwapMsgOn(On : Boolean);
    {-Turns Swap message on or off}
  begin
    CSSwapData^.SwapMsgOn := On;
  end;

  procedure SetSwapMsgRow(Row : Byte);
    {-Sets the row where swapping messages are to appear}
  begin
    CSSwapData^.SwapMsgRow := Pred(Row);
  end;

  procedure SetSwapFileAttr(Hidden : Boolean);    {!!.02}
  begin
    if Hidden then
      CSSwapData^.FileAttr := HiddenAttr
    else
      CSSwapData^.FileAttr := NormalAttr;
  end;

  function WasCommandActive : Boolean;                           {!!.02}
    {-Returns True if COMMAND.COM was active at time of last popup}
  begin
    WasCommandActive := FlagIsSet(CSSwapData^.SwapFlags, CommandBit);
  end;

  procedure SetSaveComPorts(Enable : Boolean);
    {-Enables/disables saving of UART interrupt states while popped}
  begin
    with CSSwapData^ do
      if Enable then
        SetFlag(SwapFlags, SaveUarts)
      else
        ClearFlag(SwapFlags, SaveUarts);
  end;

begin
  FillChar(LocalSwapData, SizeOf(LocalSwapData), 0);
  CSSwapData := @LocalSwapData;
  CSSwapData^.PopupsEnabled := False;
  SaveSSeg := 0;
  TopOfHeap := nil;
end.
