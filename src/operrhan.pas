{*********************************************************}
{*                  OPERRHAN.PAS 1.30                    *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I opdefine.inc}

unit OpErrHan;
  {-Allow recovery from some Turbo runtime errors}

  { FPC port: the original patched the Turbo Pascal system error handler and
    the INT 0 / 8087 vectors to recover from runtime errors.  That is not
    possible (and not meaningful) with the FPC runtime, so recovery is
    stubbed: CanRecover is always False and ErrorRecovery does nothing.
    FPC code that wants to trap errors should use exceptions or ErrorProc. }

interface

var
  CanRecover : Boolean;      {True when the error handler is successfully installed}

procedure ErrorRecovery(On : Boolean; UserRoutine : Pointer);
  {-Turn error recovery on and off, and attach to a user error routine}

  {==========================================================================}

implementation

  { FPC port: stubbed because the TP system error handler cannot be patched }
  procedure ErrorRecovery(On : Boolean; UserRoutine : Pointer);
  begin
  end;

begin
  CanRecover := False;
end.
