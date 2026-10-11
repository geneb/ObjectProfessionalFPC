{$IFDEF OPWinTP}                                                      {!!.20}
  !! ERROR: This unit is not compatible with Windows applications !!  {!!.20}
{$ENDIF}                                                              {!!.20}

{$S-,R-,V-,I-,B-,F+,O+,A-}

{$I opdefine.inc}

{*********************************************************}
{*                    OPDOS.PAS 1.30                     *}
{*     Copyright (c) TurboPower Software 1987, 1992.     *}
{* Portions Copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

{ FPC port: DOS INT 21h/INT 2Fh/BIOS services were replaced by Free Pascal
  RTL equivalents (Dos, SysUtils, kernel32 on Windows).
    - Drives are 'A'..'Z' on Windows; on Unix a single virtual drive 'C'
      stands for the root file system.
    - Stubbed (no equivalent): absolute sector read/write, DOS print
      spooler (PRINT.COM), DTA, DOS memory blocks (SetBlock), file handle
      table walking, phantom drives, parent/master DOS environments' memory
      segments.
    - DOS environment records (EnvRec) are now private memory buffers:
      EnvSeg is only a validity marker (0 = invalid, 1 = static snapshot,
      2 = heap allocated) and EnvPtr points to the buffer.
  Unit OpDos.in2 (the DPMI variant) is no longer used. }

unit OpDos;
  {-Miscellaneous DOS/BIOS call routines}

interface

uses
  Dos,
  OpString;

const
  ExecSaveScreen    = 0;
  ExecShowMemory    = 1;
  ExecPauseAfterRun = 2;
  ExecRestoreScreen = 3;
type
  OS =                 {!!.20}
    record             {!!.20}
      O, S : Word;     {!!.20}
    end;               {!!.20}
  ActionCodeType = ExecSaveScreen..ExecRestoreScreen;
  DiskClass = (
    Floppy360, Floppy720, Floppy12, Floppy144, OtherFloppy, Bernoulli,
    HardDisk, RamDisk, SubstDrive, UnknownDisk, InvalidDrive,
    NovellDrive, CDRomDisk); {!!.13}{!!.20}

type
  EnvRec =
    record
      EnvSeg : Word;              {Validity marker (FPC port), 0 = invalid}
      EnvLen : Word;              {Usable length of the environment}
      EnvPtr : Pointer;           {Environment buffer}
    end;

  ExecDosProc = procedure(ActionCode : ActionCodeType; Param : Word);
  VolumeNameStr = String[11];     {string type for volume labels}    {!!.14}
  MediaIDType =                   {record type for Get/SetMediaID}   {!!.14}
    record
      InfoLevel : Word;
      SerialNumber : LongInt;
      VolumeLabel : Array[0..10] of Char;
      FileSystemID : Array[0..7] of Char;
    end;

const
  StackSafetyMargin : Word = 1000;
  MinSpaceForDos : Word = 20000; {Minimum bytes for DOS shell to run}

  StdInHandle = 0;           {handle numbers for OpenStdDev}
  StdOutHandle = 1;
  StdErrHandle = 2;
  StdPrnHandle = 4;

function DosVersion : Word;
  {-Returns the DOS version number. High byte has major version number,
    low byte has minor version number. Eg., DOS 3.1 => $0301.}

function NumberOfDrives : Byte;
  {-Returns the number of logical drives}

procedure SelectDrive(Drive : Char);
  {-Selects the specified drive as default if possible}

function DefaultDrive : Char;
  {-Returns the default drive as an uppercase letter}

function ValidDrive(Drive : Char) : Boolean;
  {-Return True if the specified drive is valid}

function IsPhantom(Drive : Char) : Boolean;                    {!!.30}
  {-Return True if the specified drive is a phantom drive}     {!!.30}

function PhantomExists : Boolean;                              {!!.30}
  {-Return True if there is a phantom drive in the system}     {!!.30}

procedure SelectPhantom(Drive : Char);                         {!!.30}
  {-Select a phantom drive as default if possible}             {!!.30}

function GetDiskInfo(Drive : Byte; var ClustersAvailable, TotalClusters,
                     BytesPerSector, SectorsPerCluster : Word) : Boolean;
  {-Return technical info about the specified drive}

function GetDiskClass(Drive : Char; var SubstDriveChar : Char) : DiskClass;
  {-Return the disk class for the drive with the specified letter}

function ReadDiskSectors(Drive : Word; FirstSect : Longint;
                         NumSects : Word; var Buf) : Boolean;
  {-Read absolute disk sectors.}

function WriteDiskSectors(Drive : Word; FirstSect : Longint;
                          NumSects : Word; var Buf) : Boolean;
  {-Write absolute disk sectors.}

function GetFileMode(FName : string; var Attr : Word) : Byte;
  {-Returns a file's attribute in Attr and the DOS error code as the function
    result.}

function FlushDosBuffers(var F) : Boolean;
  {-Flush DOS's buffers for the specified file}

function FileHandlesLeft : Byte;
  {-Return the number of available file handles}

function FileHandlesOpen(CountDevices : Boolean) : Byte;
  {-Return the number of open files owned by a program}

procedure SetDta(DTAptr : Pointer);
  {-Set the DOS DTA to point to DTAptr}

procedure GetDta(var DTAptr : Pointer);
  {-Return the DOS DTA pointer}

function ParsePath(var InputPath, SearchPath, LeadInPath : string) : Boolean;
  {-Takes a user entered path, trims blanks, and returns a valid global
    search path and a valid lead-in path.}

function PrintInstalled : Boolean;
  {-Returns True if PRINT.COM is installed}

function SubmitPrintFile(FileName : string) : Byte;
  {-This procedure submits a file to the PC DOS 3.0 or greater concurrent
   print utility.}

procedure CancelPrintFile(FileMask : string);
  {-Cancels the files matched by the file mask passed in FileMask.}

procedure CancelAllPrintFiles;
  {-Cancels all files in the print queue}

function GetPrintStatus(var QPtr : Pointer) : Byte;
 {-Halts printing, returns current error status, puts pointer to the filename
   queue in the QPtr variable. Filenames in the queue are 64-byte ASCIIZ
   strings. The end of the queue is marked by a name starting with a null.}

procedure EndPrintStatus;
  {-Releases the spooler from the GetPrintStatus procedure.}

function GetEnvironmentString(SearchString : string) : string;
  {-Return a string from the environment}

function SetBlock(var Paragraphs : Word) : Boolean;
  {-Change size of DOS memory block allocated to this program}

procedure NoExecDosProc(ActionCode : ActionCodeType; Param : Word);
  {-Do-nothing ExecDosProc}

function ExecDos(Command : string; UseSecond : Boolean; EDP : ExecDosProc) : Integer;
 {-Execute any DOS command. Call with Command = '' for a new shell.
   If UseSecond is false, Command must be the full pathname of a program to be
   executed. EDP is a procedure to display status, save/restore the screen,
   etc. ExecDos return codes are as follows:
         0 : Success
        -1 : Insufficient memory to store free list
        -2 : DOS setblock error before EXEC call
        -3 : DOS setblock error after EXEC call  -- critical error!
        -4 : Insufficient memory to run DOS command
      else   a DOS error code
  }

function TextSeek(var F : Text; Target : LongInt) : Boolean;
 {-Do a Seek for a text file opened for input. Returns False in case of I/O
   error.}

function TextFileSize(var F : Text) : LongInt;
  {-Return the size of text file F. Returns -1 in case of I/O error.}

function TextPos(var F : Text) : LongInt;
 {-Return the current position of the logical file pointer (that is,
   the position of the physical file pointer, adjusted to account for
   buffering). Returns -1 in case of I/O error.}

function TextFlush(var F : Text) : Boolean;
  {-Flush the buffer(s) for a text file. Returns False in case of I/O error.}

function OpenStdDev(var F : Text; StdHandle : Word) : Boolean;
  {-Assign the text file to a standard DOS device: 0, 1, 2, or 4}

function HandleIsConsole(Handle : Word) : Boolean;
  {-Return true if handle is the console device}

procedure SetRawMode(var F : Text; On : Boolean);
  {-Set "raw" mode on or off for the specified text file (must be a device)}

function ExistFile(FName : string) : Boolean;
  {-Return true if file is found}

function ExistOnPath(FName : string; var FullName : string) : Boolean;
 {-Return true if fname is found in
   a) current directory
   b) program's directory (DOS 3.X only)
   c) any DOS path directory
  and return full path name to file}

function IsDirectory(FName : String) : Boolean;
  {-Return true if FName is a directory}

function SameFile(FilePath1,FilePath2 : String;
                  var ErrorCode : Word) : Boolean;
  {-Return true if FilePath1 and FilePath2 refer to the same physical file.
    Error codes:
      0 - Success (no error)
      1 - Invalid FilePath
  }

function CopyFile(SrcPath, DestPath : String;
                  Buffer : Pointer;
                  BufferSize : Word) : Word;
  {-Copy the file specified by SrcPath into DestPath. DestPath must specify
    a complete filename, it may not be the name of a directory without the
    file portion.  This a low level routine, and the input pathnames are not
    checked for validity. Buffer must already be allocated, and must be no
    less than BufferSize.}

function TimeMs : LongInt;
  {-Return time of day in milliseconds since midnight}

{-------- routines from TPENV --------}

procedure MasterEnv(var Env : EnvRec);
  {-Return master environment record}

procedure CurrentEnv(var Env : EnvRec);
  {-Return current environment record}

procedure ParentEnv(var Env : EnvRec);
  {-Return environment record of program's parent}

procedure CommandEnv(var Env : EnvRec); {!!.12}
  {-Return environment record for last copy of COMMAND.COM in memory}

procedure NewEnv(var Env : EnvRec; Size : Word);
  {-Allocate a new environment on the heap}

procedure DisposeEnv(var Env : EnvRec);
  {-Deallocate an environment previously allocated on heap}

procedure SetCurrentEnv(Env : EnvRec);
  {-Specify a different environment for the current program}

procedure CopyEnv(Src, Dest : EnvRec);
  {-Copy contents of Src environment to Dest environment}

function EnvFree(Env : EnvRec) : Word;
  {-Return bytes free in environment}

function GetEnvStr(Env : EnvRec; Search : string) : string;
  {-Return a string from the environment}

function SetEnvStr(Env : EnvRec; Search, Value : string) : Boolean;
  {-Set environment string, returning true if successful}

procedure DumpEnv(Env : EnvRec);
  {-Dump the environment to the screen}

function GetProgramStr(Env : EnvRec) : string;
  {-Return the name of the program that owns Env, '' if DOS < 3.0 or unknown}

function SetProgramStr(Env : EnvRec; Path : string) : Boolean;
  {-Add a program name to the end of an environment if sufficient space}

function ShellWithPrompt(Prompt : string; EDP : ExecDosProc) : Integer;
  {-Shell to DOS with a new prompt}

function GetVolumeLabel(Drive : Char;
                        var VolName : VolumeNameStr) : Word; {!!.14}
  {-Gets the volume label for Drive. Returns 0 for success, or DOS error
    code.}

function DeleteVolumeLabel(Drive : Char) : Word;            {!!.20}
  {-Deletes an existing volume label on Drive. Returns 0 for success,
    or DOS error code.}

function SetVolumeLabel(Drive : Char; VolName : VolumeNameStr) : Word; {!!.14}
  {-Set the volume label for Drive to VolName. All 11 characters in VolName
    are significant, so the string should always be padded to 11 characters.
    Returns 0 for success, or DOS error code.}

function GetMediaID(Drive : Char;
                    var MediaIDRec : MediaIDType) : Word; {!!.14}
  {-Returns the DOS 5 Media ID record which includes the disk's serial number
    and volume label. Returns 0 for success, or DOS error code.}

function SetMediaID(Drive : Char;
                    var MediaIDRec : MediaIDType) : Word; {!!.14}
  {-Sets the DOS 5 Media ID record which includes the disk's serial number
    and volume label. Returns 0 for success, or DOS error code.}

  {============================================================================}

implementation

uses
{$IFDEF UNIX}
  Unix,
{$ENDIF}
  SysUtils;

type
  EnvArray = array[0..32767] of Char;
  EnvArrayPtr = ^EnvArray;

const
{$IFDEF UNIX}
  PathListSep = ':';
  DirSep = '/';
  NullDevName = '/dev/null';
  PrnDevName = '/dev/lp0';
{$ELSE}
  PathListSep = ';';
  DirSep = '\';
  NullDevName = 'NUL';
  PrnDevName = 'PRN';
{$ENDIF}

{$IFDEF WINDOWS}
  function GetDriveTypeA(Root : PChar) : LongWord; stdcall;
    external 'kernel32.dll' name 'GetDriveTypeA';
  function GetDiskFreeSpaceA(Root : PChar;
                             var SectPerClus, BytesPerSect,
                             FreeClus, TotalClus : LongWord) : LongBool; stdcall;
    external 'kernel32.dll' name 'GetDiskFreeSpaceA';
  function GetVolumeInformationA(Root, VolName : PChar; VolNameSize : LongWord;
                                 Serial, MaxComp, Flags : Pointer;
                                 FsName : PChar;
                                 FsNameSize : LongWord) : LongBool; stdcall;
    external 'kernel32.dll' name 'GetVolumeInformationA';
  function SetVolumeLabelA(Root, VolLabel : PChar) : LongBool; stdcall;
    external 'kernel32.dll' name 'SetVolumeLabelA';
  function GetLastError : LongWord; stdcall;
    external 'kernel32.dll' name 'GetLastError';
  function GetFileType(H : PtrUInt) : LongWord; stdcall;
    external 'kernel32.dll' name 'GetFileType';
{$ENDIF}

  function AddSep(S : string) : string;
    {-Add a directory separator unless S is empty or already ends with one}
  begin
    if (S <> '') and not (S[Length(S)] in ['\', '/', ':']) then
      S := S+DirSep;
    AddSep := S;
  end;

  function DosVersion : Word;
    {-Returns the DOS version number. High byte has major version number,
      low byte has minor version number. Eg., DOS 3.1 => $0301.}
  begin
    {FPC port: no DOS; report a version new enough for all feature tests}
    DosVersion := $0700;
  end;

{$IFDEF WINDOWS}
  function DriveType(Drive : Char) : LongWord;
    {-Windows drive type; 0 or 1 for non-existing drives}
  var
    Root : array[0..3] of Char;
  begin
    Drive := UpCase(Drive);
    if not (Drive in ['A'..'Z']) then begin
      DriveType := 0;
      Exit;
    end;
    Root[0] := Drive;
    Root[1] := ':';
    Root[2] := '\';
    Root[3] := #0;
    DriveType := GetDriveTypeA(Root);
  end;
{$ENDIF}

  function NumberOfDrives : Byte;
    {-Returns the number of logical drives}
  {$IFDEF WINDOWS}
  var
    C : Char;
    N : Byte;
  begin
    N := 3;
    for C := 'A' to 'Z' do
      if (DriveType(C) > 1) and (Ord(C)-Ord('A')+1 > N) then
        N := Ord(C)-Ord('A')+1;
    NumberOfDrives := N;
  end;
  {$ELSE}
  begin
    {FPC port: Unix has a single virtual drive 'C' (the root)}
    NumberOfDrives := 3;
  end;
  {$ENDIF}

  function DefaultDrive : Char;
    {-Returns the default drive as an uppercase letter}
  {$IFDEF WINDOWS}
  var
    S : string;
  begin
    GetDir(0, S);
    if (Length(S) >= 2) and (S[2] = ':') then
      DefaultDrive := UpCase(S[1])
    else
      DefaultDrive := 'C';
  end;
  {$ELSE}
  begin
    DefaultDrive := 'C';
  end;
  {$ENDIF}

  function IsPhantom(Drive : Char) : Boolean;
    {-Return True if the specified drive is a phantom drive}
  begin
    {FPC port: stubbed because phantom (logical A:/B:) drives do not exist}
    IsPhantom := False;
  end;

  procedure SelectDrive(Drive : Char);
    {-Selects the specified drive as default if possible}
  {$IFDEF WINDOWS}
  var
    S : string;
    IO : Integer;
  begin
    Drive := UpCase(Drive);
    if DriveType(Drive) <= 1 then
      Exit;
    GetDir(Ord(Drive)-Ord('A')+1, S);
    ChDir(S);
    IO := IoResult;
  end;
  {$ELSE}
  begin
    {FPC port: single virtual drive on Unix, nothing to select}
  end;
  {$ENDIF}

  function ValidDrive(Drive : Char) : Boolean;
    {-Return True if the specified drive is valid}
  begin
    Drive := UpCase(Drive);
    {$IFDEF WINDOWS}
    ValidDrive := DriveType(Drive) > 1;
    {$ELSE}
    ValidDrive := (Drive = 'C');
    {$ENDIF}
  end;

  function PhantomExists : Boolean;
  begin
    PhantomExists := False;
  end;

  procedure SelectPhantom(Drive : Char);
    {-Select a phantom drive as default if possible}
  begin
    {FPC port: stubbed because phantom drives do not exist}
  end;

  function GetDiskInfo(Drive : Byte; var ClustersAvailable, TotalClusters,
                       BytesPerSector, SectorsPerCluster : Word) : Boolean;
    {-Return technical info about the specified drive (0 = default)}
  {$IFDEF WINDOWS}
  var
    Root : array[0..3] of Char;
    SPC, BPS, Free, Total : LongWord;
  begin
    GetDiskInfo := False;
    if Drive = 0 then
      Root[0] := DefaultDrive
    else
      Root[0] := Chr(Ord('A')+Drive-1);
    Root[1] := ':';
    Root[2] := '\';
    Root[3] := #0;
    if not GetDiskFreeSpaceA(Root, SPC, BPS, Free, Total) then
      Exit;
    if Free > $FFFF then
      Free := $FFFF;
    if Total > $FFFF then
      Total := $FFFF;
    ClustersAvailable := Free;
    TotalClusters := Total;
    BytesPerSector := BPS;
    SectorsPerCluster := SPC;
    GetDiskInfo := True;
  end;
  {$ELSE}
  var
    Free, Total : Int64;
    SPC : LongInt;
  begin
    GetDiskInfo := False;
    if not ((Drive = 0) or (Drive = 3)) then
      Exit;
    Total := Dos.DiskSize(0);
    Free := Dos.DiskFree(0);
    if (Total < 0) or (Free < 0) then
      Exit;
    {fake 512 byte sectors, scale clusters so the counts fit in a Word}
    SPC := 1;
    while (Total div (512*SPC) > $FFFF) and (SPC < 32768) do
      SPC := SPC*2;
    BytesPerSector := 512;
    SectorsPerCluster := SPC;
    TotalClusters := Total div (512*SPC);
    ClustersAvailable := Free div (512*SPC);
    GetDiskInfo := True;
  end;
  {$ENDIF}

  function GetDiskClass(Drive : Char; var SubstDriveChar : Char) : DiskClass;
    {-Return the disk class for the drive with the specified letter}
  {$IFDEF WINDOWS}
  var
    Size : Int64;
  begin
    GetDiskClass := InvalidDrive;
    SubstDriveChar := Drive;
    Drive := UpCase(Drive);
    case DriveType(Drive) of
      2 : begin {removable}
            Size := Dos.DiskSize(Ord(Drive)-Ord('A')+1);
            if Size < 0 then
              GetDiskClass := OtherFloppy
            else if Size <= 400000 then
              GetDiskClass := Floppy360
            else if Size <= 800000 then
              GetDiskClass := Floppy720
            else if Size <= 1300000 then
              GetDiskClass := Floppy12
            else if Size <= 1500000 then
              GetDiskClass := Floppy144
            else
              GetDiskClass := OtherFloppy;
          end;
      3 : GetDiskClass := HardDisk;
      4 : GetDiskClass := NovellDrive; {network drive}
      5 : GetDiskClass := CDRomDisk;
      6 : GetDiskClass := RamDisk;
    end;
  end;
  {$ELSE}
  begin
    SubstDriveChar := Drive;
    if UpCase(Drive) = 'C' then
      GetDiskClass := HardDisk
    else
      GetDiskClass := InvalidDrive;
  end;
  {$ENDIF}

  function ReadDiskSectors(Drive : Word; FirstSect : Longint;
                           NumSects : Word; var Buf) : Boolean;
    {-Read absolute disk sectors.}
  begin
    {FPC port: stubbed because absolute sector access (INT 25h) is not available}
    ReadDiskSectors := False;
  end;

  function WriteDiskSectors(Drive : Word; FirstSect : Longint;
                            NumSects : Word; var Buf) : Boolean;
    {-Write absolute disk sectors.}
  begin
    {FPC port: stubbed because absolute sector access (INT 26h) is not available}
    WriteDiskSectors := False;
  end;

  function GetFileMode(FName : string; var Attr : Word) : Byte;
    {-Returns a file's attribute in Attr and the DOS error code as the function
      result.}
  var
    F : file;
  begin
    Assign(F, FName);
    {call routine in the Dos unit to get the attribute}
    GetFAttr(F, Attr);
    GetFileMode := DosError;
  end;

  function FlushDosBuffers(var F) : Boolean;
    {-Flush DOS's buffers for the specified file}
  begin
    {FPC port: F is a file variable; its handle is the first field}
    FlushDosBuffers := SysUtils.FileFlush(FileRec(F).Handle);
  end;

  procedure SetDta(DTAptr : Pointer);
    {-Set the DOS DTA to point to DTA}
  begin
    {FPC port: stubbed because there is no DTA}
  end;

  procedure GetDta(var DTAptr : Pointer);
    {-Return the DOS DTA pointer}
  begin
    {FPC port: stubbed because there is no DTA}
    DTAptr := nil;
  end;

  function ParsePath(var InputPath, SearchPath, LeadInPath : string) : Boolean;
    {-Takes a user entered path, trims blanks, and returns a valid global
      search path and a valid lead-in path.}
  var
    S : string;
    SLen : Byte absolute S;
    Attr : Word;

    function IsPath(S : string) : Boolean;
      {-Return True if S is empty or ends with a drive colon or separator}
    var
      SLen : Byte absolute S;
    begin
      {check last character in S}
      if SLen = 0 then
        IsPath := True
      else
        case S[SLen] of
          ':' : IsPath := (SLen = 2);
          '\' : IsPath := True;
          '/' : IsPath := True;
          '.' : IsPath := (SLen = 1) or (S = '..') or
                          ((SLen > 2) and                      {!!.03}
                           ((Pos(DirSep+'..', S) = (SLen - 2)) or  {!!.03}
                            (Pos(':.', S)  = (SLen - 1)) or    {!!.10}
                            (Pos(':..', S) = (SLen - 2)) )     {!!.03}
                          );                                   {!!.03}
          else IsPath := False;
        end;
    end;

    function NameIsValid(S : string) : Boolean; {!!.10}
    var
      I : Word;
    begin
      NameIsValid := False;
      for I := 1 to Length(S) do
        {$IFDEF UNIX}
        if S[I] = #0 then
        {$ELSE}
        if S[I] in [#0..#31, '"', '[', ']', '|', ';'..'>', '+', ','] then
        {$ENDIF}
          Exit;
      NameIsValid := True;
    end;

  begin
    {Assume success}
    ParsePath := True;

    {Get working copy of InputPath; trim blanks (DOS names are upper case)}
    S := OpString.Trim(InputPath);
    {$IFNDEF UNIX}
    S := StUpCase(S);
    {$ENDIF}

    {$IFDEF UNIX}
    if (Pos('//', S) <> 0) then
    {$ELSE}
    if (Pos(':', S) > 2) or (Pos('/', S) <> 0) or
       (Pos('::', S) <> 0) or (Pos('\\', S) <> 0) then
    {$ENDIF}
      ParsePath := False
    {if S is just a path name, add "*.*" to search path}
    else if IsPath(S) then begin
      if (SLen > 0) and (S[SLen] = '.') then
        S := S+DirSep;
      LeadInPath := S;
      SearchPath := S+'*.*';
    end
    else
      if SLen >= 77 then
        ParsePath := False
      else
        {test validity of pathname by calling routine to get file attribute}
        case GetFileMode(S, Attr) of

          0 : if (Attr and Directory {= $10} ) <> 0 then begin
                {Input path is valid directory name}
                SearchPath := S+DirSep+'*.*';
                LeadInPath := S+DirSep;
              end
              else begin
                {Input path is the name of a file}
                SearchPath := S;

                {trim end of string until only a path is left}
                while not IsPath(S) do
                  Dec(SLen);
                LeadInPath := S
              end;

          2, 3 : begin {!!.20}
                {path not found}

                {reject clearly invalid names}
                ParsePath := NameIsValid(S);

                SearchPath := S;

                {trim end of string until only a path is left}
                while not IsPath(S) do
                  Dec(SLen);

                if (SLen = 0) or (S[SLen] <> ':') or (SLen = 2) then
                  LeadInPath := S
                else
                  ParsePath := False;
              end;
        else
          ParsePath := False;
        end;
  end;

  function PrintInstalled : Boolean;
    {-Returns True if PRINT.COM is installed}
  begin
    {FPC port: stubbed because there is no DOS print spooler}
    PrintInstalled := False;
  end;

  function SubmitPrintFile(FileName : string) : Byte;
    {-This procedure submits a file to the PC DOS 3.0 or greater concurrent
      print utility.}
  begin
    {FPC port: stubbed because there is no DOS print spooler; 1 = invalid function}
    SubmitPrintFile := 1;
  end;

  procedure CancelPrintFile(FileMask : string);
    {-Cancels the files matched by the file mask passed in FileMask.}
  begin
    {FPC port: stubbed because there is no DOS print spooler}
  end;

  procedure CancelAllPrintFiles;
    {-Cancels all files in the print queue}
  begin
    {FPC port: stubbed because there is no DOS print spooler}
  end;

  function GetPrintStatus(var QPtr : Pointer) : Byte;
    {-Halts printing, returns current error status, puts pointer to the filename
      queue in the QPtr variable.}
  begin
    {FPC port: stubbed because there is no DOS print spooler}
    QPtr := nil;
    GetPrintStatus := 1;
  end;

  procedure EndPrintStatus;
    {-Releases the spooler from the GetPrintStatus procedure.}
  begin
    {FPC port: stubbed because there is no DOS print spooler}
  end;

  function GetEnvironmentString(SearchString : string) : string;
    {-Return a string from the environment}
  begin
    while (Length(SearchString) > 0) and
          (SearchString[Length(SearchString)] = '=') do
      Dec(SearchString[0]);
    GetEnvironmentString := Dos.GetEnv(SearchString);
  end;

  function SetBlock(var Paragraphs : Word) : Boolean;
    {-Change size of DOS memory block allocated to this program}
  begin
    {FPC port: stubbed because there are no DOS memory blocks; reports success}
    SetBlock := True;
  end;

  function ExecDos(Command : string; UseSecond : Boolean; EDP : ExecDosProc) : Integer;
    {-Execute any DOS command. Call with Command = '' for a new shell. If
      UseSecond is false, Command must be the full pathname of a program to be
      executed}
  var
    BlankPos : Word;
    PathName : string;
    CommandTail : string;
  begin
    {FPC port: no heap compression / DOS memory block juggling is needed}
    if Command = '' then
      UseSecond := True;
    CommandTail := '';
    if not UseSecond {command processor} then begin
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
      {$IFDEF UNIX}
      PathName := GetEnvironmentString('SHELL');
      if PathName = '' then
        PathName := '/bin/sh';
      {$ELSE}
      PathName := GetEnvironmentString('COMSPEC');
      if PathName = '' then
        PathName := 'cmd.exe';
      {if Command is empty, we're doing a shell}
      if Command <> '' then
        CommandTail := '/C '+Command;
      {$ENDIF}
    end;

    {Let user routine store and clear the physical screen}
    EDP(ExecSaveScreen, 0);

    {let user routine show status info if entering DOS shell}
    if (Command = '') then
      EDP(ExecShowMemory, 640);

    DosError := 0;
    {$IFDEF UNIX}
    if UseSecond and (Command <> '') then begin
      if Unix.Shell(Command) < 0 then
        DosError := 2;
    end
    else
      Dos.Exec(PathName, CommandTail);
    {$ELSE}
    Dos.Exec(PathName, CommandTail);
    {$ENDIF}

    {if not in shell, let user routine allow time to see result}
    if (Command <> '') or (DosError <> 0) then
      EDP(ExecPauseAfterRun, 0);

    {give user routine a chance to restore the screen}
    EDP(ExecRestoreScreen, 0);

    {If we get to here, our function result is in DosError}
    ExecDos := DosError;
  end;

  function FPos(H : THandle; Offset, Origin : Int64) : Int64;
    {-Seek wrapper, returns -1 on error}
  begin
    FPos := SysUtils.FileSeek(H, Offset, Origin);
  end;

  function TextSeek(var F : Text; Target : LongInt) : Boolean;
    {-Do a Seek for a text file opened for input. Returns False in case of I/O
      error.}
  var
    Pos : Int64;
  begin
    with TextRec(F) do begin
      {assume failure}
      TextSeek := False;

      {check for file opened for input}
      if Mode <> fmInput then
        Exit;

      {get current position of the file pointer}
      Pos := FPos(Handle, 0, 1);
      if Pos < 0 then
        Exit;

      {calculate current position for the start of the buffer}
      Pos := Pos-BufEnd;

      {see if the Target is within the buffer}
      Pos := Target-Pos;
      if (Pos >= 0) and (Pos < BufEnd) then
        {it is--just move the buffer pointer}
        BufPos := Pos
      else begin
        {seek to the Target-ed offset}
        if FPos(Handle, Target, 0) < 0 then
          Exit;

        {tell the RTL its buffer is empty}
        BufEnd := 0;
        BufPos := 0;
      end;
    end;

    {if we get to here we succeeded}
    TextSeek := True;
  end;

  function TextFileSize(var F : Text) : LongInt;
    {-Return the size of text file F. Returns -1 in case of I/O error.}
  var
    Old, Size : Int64;
  begin
    with TextRec(F) do begin
      TextFileSize := -1;
      {check for open file}
      if Mode = fmClosed then
        Exit;
      Old := FPos(Handle, 0, 1);
      if Old < 0 then
        Exit;
      Size := FPos(Handle, 0, 2);
      if Size < 0 then
        Exit;
      if FPos(Handle, Old, 0) < 0 then
        Exit;
      TextFileSize := Size;
    end;
  end;

  function TextPos(var F : Text) : LongInt;
    {-Return the current position of the logical file pointer (that is,
      the position of the physical file pointer, adjusted to account for
      buffering). Returns -1 in case of I/O error.}
  var
    Position : Int64;
  begin
    with TextRec(F) do begin
      TextPos := -1;
      {check for open file}
      if Mode = fmClosed then
        Exit;

      {get current position of the physical file pointer}
      Position := FPos(Handle, 0, 1);
      if Position < 0 then
        Exit;

      {calculate the position of the logical file pointer}
      if Mode = fmOutput then
        {writing}
        Inc(Position, BufPos)
      else
        {reading}
        if BufEnd <> 0 then
          Dec(Position, BufEnd-BufPos);

      TextPos := Position;
    end;
  end;

  function TextFlush(var F : Text) : Boolean;
    {-Flush the buffer(s) for a text file. Returns False in case of I/O error.}
  var
    Position : Int64;
  begin
    with TextRec(F) do begin
      {assume failure}
      TextFlush := False;

      {check for open file}
      if Mode = fmClosed then
        Exit;

      {see if file is opened for reading or writing}
      if Mode = fmInput then begin
        {get current position of the logical file pointer}
        Position := TextPos(F);

        {exit in case of I/O error}
        if Position = -1 then
          Exit;

        {set the new position of the physical file pointer}
        if FPos(Handle, Position, 0) < 0 then
          Exit;
      end
      else begin
        {write the current contents of the buffer, if any}
        if BufPos <> 0 then begin
          if SysUtils.FileWrite(Handle, BufPtr^, BufPos) <> BufPos then
            Exit;
        end;

        {flush OS buffers}
        if not FlushDosBuffers(F) then
          {not all handles (e.g. devices) can be flushed; ignore}
          ;
      end;

      {tell the RTL its buffer is empty}
      BufEnd := 0;
      BufPos := 0;
    end;

    {if we get to here we succeeded}
    TextFlush := True;
  end;

  function OpenStdDev(var F : Text; StdHandle : Word) : Boolean;
    {-Assign the text file to the specified standard DOS device}
  begin
    OpenStdDev := False;
    case StdHandle of
      StdInHandle,
      StdOutHandle,
      StdErrHandle :
        begin
          {Initialize the file variable}
          Assign(F, '');
          if StdHandle = StdInHandle then {!!.11}
            Reset(F)                      {!!.11}
          else                            {!!.11}
            Rewrite(F);                   {!!.11}
          if IoResult = 0 then begin
            case StdHandle of
              StdInHandle  : TextRec(F).Handle := StdInputHandle;
              StdOutHandle : TextRec(F).Handle := StdOutputHandle;
              StdErrHandle : begin
                               TextRec(F).Handle := StdErrorHandle;
                               TextRec(F).BufSize := 1;
                             end;
            end;
            OpenStdDev := True;
          end;
        end;
      StdPrnHandle :
        begin
          {FPC port: the DOS standard printer is the OS printer device}
          Assign(F, PrnDevName);
          Rewrite(F);
          OpenStdDev := (IoResult = 0);
        end;
    end;
  end;

  function HandleIsConsole(Handle : Word) : Boolean;
    {-Return true if handle is the console device (input or output)}
  {$IFDEF WINDOWS}
  var
    H : PtrUInt;
  begin
    case Handle of
      0 : H := StdInputHandle;
      1 : H := StdOutputHandle;
      2 : H := StdErrorHandle;
      else H := Handle;
    end;
    HandleIsConsole := GetFileType(H) = 2; {FILE_TYPE_CHAR}
  end;
  {$ELSE}
  begin
    {FPC port: assume the standard handles are the console}
    HandleIsConsole := Handle <= 2;
  end;
  {$ENDIF}

  procedure SetRawMode(var F : Text; On : Boolean);
    {-Set "raw" mode on or off for the specified text file (must be a device)}
  begin
    with TextRec(F) do begin
      {check for open file}
      if (Mode < fmInput) or (Mode > fmInOut) then begin
        {file not found error code}
        DosError := 103;
        Exit;
      end;
      {FPC port: stubbed because there is no DOS device raw/cooked mode}
      DosError := 0;
    end;
  end;

  function FileHandlesOpen(CountDevices : Boolean) : Byte; {!!.01}
    {-Return the number of open files owned by a program}
  begin
    {FPC port: stubbed because the DOS job file table is not accessible;
     report only the three standard handles}
    if CountDevices then
      FileHandlesOpen := 3
    else
      FileHandlesOpen := 0;
  end;

  function FileHandlesLeft : Byte;    {!!.01}  {revised}  {!!.11}
    {-Return the number of available file handles}
  const
    MaxHandles = 255;
  var
    Handles : array[1..MaxHandles] of THandle;
    N, I : Integer;
    H : THandle;
  begin
    N := 0;
    while N < MaxHandles do begin
      H := SysUtils.FileOpen(NullDevName, fmOpenRead);
      if LongInt(H) < 0 then
        Break;
      Inc(N);
      Handles[N] := H;
    end;
    for I := 1 to N do
      SysUtils.FileClose(Handles[I]);
    FileHandlesLeft := N;
  end;

  function ExistFile(FName : string) : Boolean;
    {-Return true if file is found}
  var
    F : file;
    Attr : Word;
  begin
    {check for empty string}
    if Length(FName) = 0 then
      ExistFile := False
    else begin
      Assign(F, FName);
      GetFAttr(F, Attr);
      ExistFile := (DosError = 0) and (Attr and (VolumeID+Directory) = 0);
    end;
  end;

  function ExistOnPath(FName : string; var FullName : string) : Boolean;
   {-Return true if FName is found in
      a) current directory
      b) program's directory
      c) any directory on the PATH
    and return path name to file}
  var
    Ppos, Fpos : Word;
    DosPath : string;
  begin
    {string empty?}
    if Length(FName) = 0 then begin
      ExistOnPath := False;
      Exit;
    end;

    {Assume success}
    ExistOnPath := True;

    {Check current directory}
    if ExistFile(FName) then begin
      FullName := FName;
      Exit;
    end;

    {Check the directory where the program was found}
    FullName := AddSep(SysUtils.ExtractFilePath(ParamStr(0)))+FName;
    if ExistFile(FullName) then
      Exit;

    {Check the path}
    DosPath := Dos.GetEnv('PATH');
    Ppos := 1;
    while Ppos <= Length(DosPath) do begin

      {Find the termination of the current path entry}
      Fpos := Ppos;
      while (Fpos <= Length(DosPath)) and (DosPath[Fpos] <> PathListSep) do
        Inc(Fpos);

      if Fpos > Ppos then begin
        {A path entry found}
        FullName := AddSep(Copy(DosPath, Ppos, Fpos-Ppos))+FName;
        if ExistFile(FullName) then
          Exit;
      end;

      {Prepare to look at next item}
      Ppos := Succ(Fpos);
    end;

    {Not found, even on the path}
    ExistOnPath := False;
    FullName := FName;
  end;

  function TimeMs : LongInt;
    {-Return time of day in milliseconds since midnight}
  var
    H, M, S, S100 : Word;
  begin
    GetTime(H, M, S, S100);
    TimeMs := 1000*(LongInt(S)+60*(LongInt(M)+60*LongInt(H)))+10*LongInt(S100);
  end;

  function IsDirectory(FName : String) : Boolean;
    {-Return true if FName is a directory}
  begin
    {an empty name means the current directory (as ChDir('') did)}
    if FName = '' then
      IsDirectory := True
    else
      IsDirectory := SysUtils.DirectoryExists(FName);
  end;

  function SameFile(FilePath1, FilePath2 : String;
                    var ErrorCode : Word) : Boolean;
    {-Return true if FilePath1 and FilePath2 refer to the same physical file.
      Error codes:
        0 - Success (no error)
        1 - Invalid FilePath1
        2 - Invalid FilePath2
        3 - Error on Dos Set/GetFAttr
    }
  var
    F1, F2 : File;
    Attr1, Attr2 : Word;
    N1, N2 : string;
  begin
    SameFile := False;
    ErrorCode := 0;
    Assign(F1,FilePath1);
    Assign(F2,FilePath2);
    GetFAttr(F1,Attr1);
    if DosError <> 0 then begin
      ErrorCode := 1;
      Exit;
    end;
    GetFAttr(F2,Attr2);
    if DosError <> 0 then begin
      {leave ErrorCode at 0 if file not found but path is valid}
      if DosError <> 2 then
        ErrorCode := 2;
      Exit;
    end;
    {FPC port: compare the fully expanded names instead of the DOS trick of
     toggling the archive attribute (hard links are not detected)}
    N1 := SysUtils.ExpandFileName(FilePath1);
    N2 := SysUtils.ExpandFileName(FilePath2);
    {$IFNDEF UNIX}
    N1 := StUpCase(N1);
    N2 := StUpCase(N2);
    {$ENDIF}
    SameFile := (N1 = N2);
  end;

  function CopyFile(SrcPath, DestPath : String;
                    Buffer : Pointer;
                    BufferSize : Word) : Word;
    {-Copy the file specified by SrcPath into DestPath. DestPath must specify
      a complete filename, it may not be the name of a directory without the
      file portion.  This a low level routine, and the input pathnames are not
      checked for validity. Buffer must already be allocated, and must be no
      less than BufferSize.}
  var
    BytesRead,BytesWritten : Word;
    Time : LongInt;
    Src,Dest : File;
    SaveFileMode : Word;                                 {!!.03}
    SaveFAttr : Word;                                    {!!.12}

    procedure UnDo(CloseAndDeleteDest : Boolean);
    begin
      Close(Src);
      if IoResult <> 0 then ;
      if CloseAndDeleteDest then begin
        Close(Dest);
        if IoResult <> 0 then ;
        Erase(Dest);
        if IoResult <> 0 then ;
      end;
    end;

  begin
    SaveFileMode := FileMode;                            {!!.03}
    Assign(Src,SrcPath);
    GetFAttr(Src, SaveFAttr);                            {!!.12}
    if DosError <> 0 then begin                          {!!.12}
      CopyFile := 1;                                     {!!.12}
      Exit;                                              {!!.12}
    end;                                                 {!!.12}
    FileMode := FileMode and $F0;                        {!!.03} {!!.14 moved}
    Reset(Src,1);
    FileMode := SaveFileMode;                            {!!.03}
    if IoResult <> 0 then begin
      CopyFile := 1;                   {unable to open SrcPath}
      Exit;
    end;
    Assign(Dest,DestPath);
    Rewrite(Dest,1);
    if IoResult <> 0 then begin
      CopyFile := 2;                   {unable to open DestPath}
      Undo(False);
      Exit;                                              {!!.12}
    end;
    while not EOF(Src) do begin
      BlockRead(Src,Buffer^,BufferSize,BytesRead);
      if IoResult <> 0 then begin
        CopyFile := 3;                 {error reading SrcPath}
        UnDo(True);
        Exit;
      end;
      BlockWrite(Dest,Buffer^,BytesRead,BytesWritten);
      if (IoResult <> 0) or (BytesWritten <> BytesRead) then begin
        CopyFile := 4;                 {error writing DestPath}
        UnDo(True);
        Exit;
      end;
    end;
    GetFTime(Src,Time);
    if DosError <> 0 then begin
      CopyFile := 5;                   {error getting SrcPath's Date/Time}
      UnDo(True);
      Exit;
    end;
    SetFTime(Dest,Time);
    if DosError <> 0 then begin
      CopyFile := 6;                   {error getting DestPath's Date/Time}
      UnDo(True);
      Exit;
    end;
    Close(Dest);
    if IoResult <> 0 then begin        {!!.02}
      CopyFile := 7;
      Close(Src);                      {!!.02}
      if IoResult <> 0 then ;          {!!.02}
    end                                {!!.02}
    else begin                         {!!.02}
      Close(Src);                      {!!.02}
      if IoResult <> 0 then ;          {!!.02}
      CopyFile := 0;                   {!!.02}
    end;                               {!!.02}
    SetFAttr(Dest, SaveFAttr);         {!!.12}
  end;

  procedure NoExecDosProc(ActionCode : ActionCodeType; Param : Word);
    {-Do-nothing ExecDosProc}
  begin
  end;

{$IFDEF WINDOWS}
  procedure MakeRoot(Drive : Char; var Root : array of Char);
  begin
    Root[0] := UpCase(Drive);
    Root[1] := ':';
    Root[2] := '\';
    Root[3] := #0;
  end;
{$ENDIF}

  function GetMediaID(Drive : Char;
                      var MediaIDRec : MediaIDType) : Word; {!!.14}
  {$IFDEF WINDOWS}
  var
    Root : array[0..3] of Char;
    VolName : array[0..63] of Char;
    FsName : array[0..31] of Char;
    Serial : LongWord;
    I, L : Integer;
  begin
    MakeRoot(Drive, Root);
    Serial := 0;
    if not GetVolumeInformationA(Root, VolName, SizeOf(VolName), @Serial,
                                 nil, nil, FsName, SizeOf(FsName)) then begin
      GetMediaID := GetLastError;
      Exit;
    end;
    FillChar(MediaIDRec, SizeOf(MediaIDRec), ' ');
    MediaIDRec.InfoLevel := 0;
    MediaIDRec.SerialNumber := Serial;
    L := StrLen(VolName);
    for I := 0 to 10 do
      if I < L then
        MediaIDRec.VolumeLabel[I] := VolName[I];
    L := StrLen(FsName);
    for I := 0 to 7 do
      if I < L then
        MediaIDRec.FileSystemID[I] := FsName[I];
    GetMediaID := 0;
  end;
  {$ELSE}
  begin
    {FPC port: stubbed, no media ID on Unix; 1 = invalid function}
    GetMediaID := 1;
  end;
  {$ENDIF}

  function SetMediaID(Drive : Char;
                      var MediaIDRec : MediaIDType) : Word; {!!.14}
  {$IFDEF WINDOWS}
  var
    S : VolumeNameStr;
  begin
    {FPC port: the serial number cannot be changed, only the label is set}
    SetMediaID := 0;
    S[0] := #11;
    Move(MediaIDRec.VolumeLabel, S[1], 11);
    SetMediaID := SetVolumeLabel(Drive, S);
  end;
  {$ELSE}
  begin
    {FPC port: stubbed, no media ID on Unix; 1 = invalid function}
    SetMediaID := 1;
  end;
  {$ENDIF}

  function GetVolumeLabel(Drive : Char; var VolName : VolumeNameStr) : Word; {!!.14}
    {-Gets the volume label for Drive. Returns 0 for success, or Dos error
      code.}
  {$IFDEF WINDOWS}
  var
    Root : array[0..3] of Char;
    Buf : array[0..63] of Char;
  begin
    VolName := '';
    MakeRoot(Drive, Root);
    if GetVolumeInformationA(Root, Buf, SizeOf(Buf), nil, nil, nil,
                             nil, 0) then begin
      VolName := StrPas(Buf);
      GetVolumeLabel := 0;
    end
    else
      GetVolumeLabel := GetLastError;
  end;
  {$ELSE}
  begin
    {FPC port: no volume labels on Unix, report an empty label}
    VolName := '';
    GetVolumeLabel := 0;
  end;
  {$ENDIF}

  function DeleteVolumeLabel(Drive : Char) : Word; {!!.20}
    {-Deletes an existing volume label on Drive. Returns 0 for success,
      or DOS error code.}
  {$IFDEF WINDOWS}
  var
    Root : array[0..3] of Char;
  begin
    MakeRoot(Drive, Root);
    if SetVolumeLabelA(Root, nil) then
      DeleteVolumeLabel := 0
    else
      DeleteVolumeLabel := GetLastError;
  end;
  {$ELSE}
  begin
    {FPC port: stubbed, 5 = access denied}
    DeleteVolumeLabel := 5;
  end;
  {$ENDIF}

  function SetVolumeLabel(Drive : Char; VolName : VolumeNameStr) : Word; {!!.14}
    {-Set the volume label for Drive to VolName. Returns 0 for success, or DOS
      error code.}
  {$IFDEF WINDOWS}
  var
    Root : array[0..3] of Char;
    Buf : array[0..32] of Char;
    L : Integer;
  begin
    MakeRoot(Drive, Root);
    L := Length(VolName);
    while (L > 0) and (VolName[L] = ' ') do
      Dec(L);
    if L > 0 then
      Move(VolName[1], Buf, L);
    Buf[L] := #0;
    if SetVolumeLabelA(Root, Buf) then
      SetVolumeLabel := 0
    else
      SetVolumeLabel := GetLastError;
  end;
  {$ELSE}
  begin
    {FPC port: stubbed, 5 = access denied}
    SetVolumeLabel := 5;
  end;
  {$ENDIF}

  {$I opdos.in1}

{$IFDEF InitAllUnits}
begin
{$ENDIF}
end.
