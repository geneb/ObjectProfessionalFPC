{$mode objfpc}
{$H-}

{ Free Pascal port helper.  Replaces the TP SetJump/LongJump inline macros
  (which captured raw SP/BP/CS:IP) with exception-based non-local exits.
  This unit is compiled in ObjFPC mode because exceptions are not available
  in Turbo Pascal mode. }

unit OpJump;

interface

type
  TJumpProc = procedure(Data : Pointer);

function RunJump(Proc : TJumpProc; Data : Pointer) : Word;
  {-Call Proc(Data). Returns 0 if Proc returns normally, or the Result value
    passed to LongJumpTo if Proc (or anything it called) executed LongJumpTo}

procedure LongJumpTo(Result : Word);
  {-Abandon the innermost active RunJump and make it return Result}

implementation

type
  EJump = class(TObject)
    Value : Word;
  end;

function RunJump(Proc : TJumpProc; Data : Pointer) : Word;
begin
  RunJump := 0;
  try
    Proc(Data);
  except
    on E : EJump do
      RunJump := E.Value;
  end;
end;

procedure LongJumpTo(Result : Word);
var
  E : EJump;
begin
  E := EJump.Create;
  E.Value := Result;
  raise E;
end;

end.
