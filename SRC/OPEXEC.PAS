{$I opdefine.inc}

{*********************************************************}
{*                    OPEXEC.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1988, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpExec;
  {-Dos shell with swapping to Ems or disk}

  { FPC port: ExecDosSwap runs a child process via Dos.Exec (COMSPEC /C on
    Windows, $SHELL -c on Unix).  There is no memory to swap out in a 32/64-bit
    process, so the EMS/XMS/disk swapping interface is kept but stubbed. }

interface

uses
  Dos;

const
  ExecSaveScreen    = 0;
  ExecShowMemory    = 1;    {!!.20-This portion not used in protected mode}
  ExecPauseAfterRun = 2;
  ExecRestoreScreen = 3;
type
  ActionCodeType = ExecSaveScreen..ExecRestoreScreen;

const
  UseEmsIfAvailable : Boolean = True;
  NoSwapMsgForEms   : Boolean = True;
  AllowRemovable    : Boolean = False; {!!.02}
  HideSwapFile      : Boolean = True;  {!!.02}

var
  NoOfBytesSwapped : LongInt;     {Bytes to swap to EMS/disk}
  EmsAllocated : Boolean;         {True when EMS allocated for swap}
  SwapFileAllocated : Boolean;    {True when file allocated for swap}
  XmsAllocated : Boolean;         {True when XMS allocated for swap} {!!.03}

procedure SetSwapMsgOn(On : Boolean);
  {-Turns Swap message on or off}

procedure ExecWithSwap(Path, CmdLine : String);
  {-DOS shell with swapping to EMS, XMS or disk}

function PrepareExecWithSwap(LastToSave : Pointer;
                             SwapFileName : PathStr) : Boolean;
  {-Set up for a shell with swapping, returning true if successful}

procedure RemoveExecWithSwap;
  {-Deallocate EMS space or erase swap file, whichever was allocated}

function ExecDosSwap(Command : string;
                     UseSecond : Boolean;
                     EDP : Pointer;
                     SwapFName : PathStr) : Integer;
 {-Execute any DOS command. Call with Command = '' for a new shell.
   If UseSecond is false, Command must be the full pathname of a program to
   be executed. EDP is a pointer to a routine to save/restore the screen, etc.
   SwapFName is the name of the swap file to use. ExecDosSwap return codes are
   as follows:

       0 : Success
      -1 : Insufficient memory to store free list
      -5 : Unable to allocate EMS or open swap file
      else a DOS error code
  }

  {---------------------------------------------------------------}
  {Following routines are interfaced for other general purpose use}

{.Z+}
function EmsInstalled : Boolean;
  {-Return true if EMS driver installed}

function EmsPageFrame : Word;
  {-Returns the page frame base segment}

function AllocateEmsPages(NumPages : Word) : Word;
  {-Allocate the indicated number of pages and returns a handle}

procedure DeallocateEmsHandle(Handle : Word);
  {-Deallocate the memory associated with the indicated handle}
{.Z-}

  {==================================================================}

implementation

type
  ExecDosProc = procedure(ActionCode : ActionCodeType; Param : Word);

  { FPC port: stubbed because there is no memory to swap }
  procedure SetSwapMsgOn(On : Boolean);
  begin
  end;

  { FPC port: swapping is stubbed; simply runs the program }
  procedure ExecWithSwap(Path, CmdLine : String);
  begin
    Exec(Path, CmdLine);
  end;

  { FPC port: stubbed because swapping is not needed; reports failure so that
    callers know no swap area was set up }
  function PrepareExecWithSwap(LastToSave : Pointer;
                               SwapFileName : PathStr) : Boolean;
  begin
    EmsAllocated := False;
    XmsAllocated := False;
    SwapFileAllocated := False;
    NoOfBytesSwapped := 0;
    PrepareExecWithSwap := False;
  end;

  procedure RemoveExecWithSwap;
  begin
    EmsAllocated := False;
    XmsAllocated := False;
    SwapFileAllocated := False;
  end;

  { FPC port: stubbed because there is no EMS }
  function EmsInstalled : Boolean;
  begin
    EmsInstalled := False;
  end;

  { FPC port: stubbed because there is no EMS }
  function EmsPageFrame : Word;
  begin
    EmsPageFrame := 0;
  end;

  { FPC port: stubbed because there is no EMS }
  function AllocateEmsPages(NumPages : Word) : Word;
  begin
    AllocateEmsPages := 0;
  end;

  { FPC port: stubbed because there is no EMS }
  procedure DeallocateEmsHandle(Handle : Word);
  begin
  end;

  function ExecDosSwap(Command : string;
                       UseSecond : Boolean;
                       EDP : Pointer;
                       SwapFName : PathStr) : Integer;
   {-Execute any DOS command}
  var
    EProc          : ExecDosProc absolute EDP;
    PathName       : string;
    CommandTail    : string;
    BlankPos       : Word;
  begin
    if Command = '' then
      UseSecond := True;
    CommandTail := '';
    if not UseSecond then begin
      {Command is assumed to be a full pathname for a program}
      BlankPos := Pos(' ', Command);
      if BlankPos = 0 then
        PathName := Command
      else begin
        CommandTail := Copy(Command, BlankPos, Length(Command));
        PathName := Copy(Command, 1, Pred(BlankPos));
      end;
    end
    else begin
      {command processor}
{$IFDEF UNIX}
      PathName := GetEnv('SHELL');
      if PathName = '' then
        PathName := '/bin/sh';
      if Command <> '' then
        CommandTail := '-c "'+Command+'"';
{$ELSE}
      PathName := GetEnv('COMSPEC');
      if Command <> '' then
        CommandTail := '/C '+Command;
{$ENDIF}
    end;

    {Let user routine store and clear the physical screen}
    if EDP <> nil then
      EProc(ExecSaveScreen, 0);

    Exec(PathName, CommandTail);

    if EDP <> nil then begin
      {if not in shell, let user routine allow time to see result}
      if (Command <> '') or (DosError <> 0) then
        EProc(ExecPauseAfterRun, 0);

      {give user routine a chance to restore the screen}
      EProc(ExecRestoreScreen, 0);
    end;

    ExecDosSwap := DosError;
  end;

end.
