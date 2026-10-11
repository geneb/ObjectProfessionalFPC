{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows!!                {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F+,O-,A-}

{$I opdefine.inc}

{*********************************************************}
{*                    OP8087.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{ FPC port: stubbed because the original unit saved/restored the registers of
  a real-mode 80x87 (or the Turbo Pascal 8087 emulator) for TSR pop-ups, and
  detected which of the two was in use.  Under Windows/Linux the FPU is always
  present, is managed by the operating system, and there is no emulator.  The
  interface is kept; the routines behave as "FPU present, no emulator".
  Note: Extended is an 80-bit type on i386 but equals Double on x86_64-win64,
  so SizeOf(SaveBuffer8087) differs between targets. }

unit Op8087;
  {-Routines to add 80x87 support to pop-up routines}

interface

type
  SaveBuffer8087 =
    record
      Control : Word;        {control word}
      Status : Word;         {status word}
      Tag : Word;            {tags for stack}
      InstPtr : LongInt;     {instruction pointer}
      OpPtr : LongInt;       {data pointer}
      Regs8087 : array[0..7] of Extended; {stack}
    end;

procedure Save8087(var SaveBuf : SaveBuffer8087);
  {-Saves the 80x87 registers in the save buffer.}

procedure Restore8087(var SaveBuf : SaveBuffer8087);
  {-Restores the 80x87 registers from the save buffer.}

function Installed8087 : Boolean;
  {-Returns true if an 80x87 coprocessor is installed.}

procedure Exceptions8087(On : Boolean);
  {-Turn exception interrupts on or off}

function Error8087 : Word;
  {-Return (and clear) the error status of the 80x87}

procedure Reinit8087;
  {-Reinitialize the 8087 chip}

procedure ReinitEmulator;
  {-Reinitialize the emulator}

function UseEmulator : Boolean;
  {-Return True if ReinitEmulator should be used rather than Reinit8087}

  {==========================================================================}

implementation

  { FPC port: stubbed because the FPU state belongs to the OS/RTL }
  procedure Save8087(var SaveBuf : SaveBuffer8087);
  begin
    FillChar(SaveBuf, SizeOf(SaveBuf), 0);
  end;

  { FPC port: stubbed because the FPU state belongs to the OS/RTL }
  procedure Restore8087(var SaveBuf : SaveBuffer8087);
  begin
  end;

  { FPC port: an FPU is always present }
  function Installed8087 : Boolean;
  begin
    Installed8087 := True;
  end;

  { FPC port: stubbed because exception masks are managed by the RTL }
  procedure Exceptions8087(On : Boolean);
  begin
  end;

  { FPC port: stubbed, no pending 8087 error status is ever reported }
  function Error8087 : Word;
  begin
    Error8087 := 0;
  end;

  { FPC port: stubbed because the RTL initializes the FPU }
  procedure Reinit8087;
  begin
  end;

  { FPC port: stubbed because there is no 8087 emulator }
  procedure ReinitEmulator;
  begin
  end;

  { FPC port: there is never an emulator }
  function UseEmulator : Boolean;
  begin
    UseEmulator := False;
  end;

end.
