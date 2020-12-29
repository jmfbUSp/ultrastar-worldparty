{*
    UltraStar WorldParty - Karaoke Game

	UltraStar WorldParty is the legal property of its developers,
	whose names	are too numerous to list here. Please refer to the
	COPYRIGHT file distributed with this source distribution.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. Check "LICENSE" file. If not, see
	<http://www.gnu.org/licenses/>.
 *}

unit UCommandLine;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses
  UPath;

type
  TScreenMode = (scmDefault, scmFullscreen, scmWindowed);
  TSplitMode = (spmDefault, spmNoSplit, spmSplit);

  {**
   * Reads infos from ParamStr and set some easy interface variables
   *}
  TCMDParams = class
    private
      fLanguage:   string;
      fResolution: string;

      procedure ShowHelp();

      procedure ReadParamInfo;
      procedure ResetVariables;

      function GetLanguage:   integer;
      function GetResolution: integer;
    public
      // some boolean variables set when reading infos
      Debug:      boolean;
      Benchmark:  boolean;
      NoLog:      boolean;
      ScreenMode: TScreenMode;
      Split:      TSplitMode;

      // some value variables set when reading infos {-1: Not Set, others: Value}
      Depth:      integer;
      Screens:    integer;

      // some strings set when reading infos {Length=0: Not Set}
      SongPath:   IPath;
      ConfigFile: IPath;
      ScoreFile:  IPath;

      // pseudo integer values
      property Language:      integer read GetLanguage;
      property Resolution:    integer read GetResolution;

      property CustomResolution:    string read fResolution;

      // some procedures for reading infos
      constructor Create;
  end;

var
  Params:    TCMDParams;

const
  cHelp            = 'help';
  cDebug           = 'debug';
  cMediaInterfaces = 'showinterfaces';


implementation

uses SysUtils,
     UPlatform;

{**
 * Resets variables and reads info
 *}
constructor TCMDParams.Create;
begin
  inherited;

  if FindCmdLineSwitch( cHelp ) or FindCmdLineSwitch( 'h' ) then
    ShowHelp();

  ResetVariables;
  ReadParamInfo;
end;

procedure TCMDParams.ShowHelp();

  function Fmt(aString : string) : string;
  begin
    Result := Format('%-15s', [aString]);
  end;

begin
  writeln;
  writeln('**************************************************************');
  writeln('  UltraStar WorldParty - Command line switches                    ');
  writeln('**************************************************************');
  writeln;
  writeln('  '+ Fmt('Switch') +' : Purpose');
  writeln('  ----------------------------------------------------------');
  writeln('  '+ Fmt(cMediaInterfaces) +' : Show in-use media interfaces');
  writeln('  '+ Fmt(cDebug) +' : Display Debugging info');
  writeln;

  platform.halt;
end;

{**
 * Reset Class Variables
 *}
procedure TCMDParams.ResetVariables;
begin
  Debug       := false;
  Benchmark   := False;
  NoLog       := false;
  ScreenMode  := scmDefault;
  Split       := spmDefault;

  // some value variables set when reading infos {-1: Not Set, others: Value}
  fResolution := '';
  fLanguage   := '';
  Depth       := -1;
  Screens     := -1;

  // some strings set when reading infos {Length=0 Not Set}
  SongPath    := PATH_NONE;
  ConfigFile  := PATH_NONE;
  ScoreFile   := PATH_NONE;
end;

{**
 * Read command-line parameters
 *}
procedure TCMDParams.ReadParamInfo;
var
  I:        integer;
  PCount:   integer;
  Command:  string;
begin
  PCount := ParamCount;
  //Log.LogError('ParamCount: ' + Inttostr(PCount));

  // check all parameters
  for I := 1 to PCount do
  begin
    Command := ParamStr(I);
    // check if the string is a parameter
    if (Length(Command) > 1) and (Command[1] = '-') then
    begin
      // remove '-' from command
      Command := LowerCase(Trim(Copy(Command, 2, Length(Command) - 1)));
      //Log.LogError('Command prepared: ' + Command);

      // check command

      // boolean triggers
      if (Command = 'debug') then
        Debug       := True
      else if (Command = 'benchmark') then
        Benchmark   := True
      else if (Command = 'nolog') then
        NoLog       := True
      else if (Command = 'fullscreen') then
        ScreenMode  := scmFullscreen
      else if (Command = 'window') then
        ScreenMode  := scmWindowed
      else if (Command = 'split') then
        Split     := spmSplit
      else if (Command = 'nosplit') then
        Split     := spmNoSplit

      // integer variables
      else if (Command = 'depth') then
      begin
        // check if there is another Parameter to get the Value from
        if (PCount > I) then
        begin
          Command := ParamStr(I + 1);

          // check for valid value
          // FIXME: guessing an array-index of depth is very error prone.
          If (Command = '16') then
            Depth := 0
          Else If (Command = '32') then
            Depth := 1;
        end;
      end

      else if (Command = 'screens') then
      begin
        // check if there is another parameter to get the value from
        if (PCount > I) then
        begin
          Command := ParamStr(I + 1);

          // check for valid value
          If (Command = '1') then
            Screens := 0
          Else If (Command = '2') then
            Screens := 1;
        end;
      end

      // pseudo integer values
      else if (Command = 'language') then
      begin
        // check if there is another parameter to get the value from
        if (PCount > I) then
        begin
          // write value to string
          fLanguage := Lowercase(ParamStr(I + 1));
        end;
      end

      else if (Command = 'resolution') then
      begin
        // check if there is another parameter to get the value from
        if (PCount > I) then
        begin
          // write value to string
          fResolution := Lowercase(ParamStr(I + 1));
        end;
      end

      // string values
      else if (Command = 'songpath') then
      begin
        // check if there is another parameter to get the value from
        if (PCount > I) then
        begin
          // write value to string
          SongPath := Path(ParamStr(I + 1));
        end;
      end

      else if (Command = 'configfile') then
      begin
        // check if there is another parameter to get the value from
        if (PCount > I) then
        begin
          // write value to string
          ConfigFile := Path(ParamStr(I + 1));

          // is this a relative path -> then add gamepath
          if (not ConfigFile.IsAbsolute) then
            ConfigFile := Platform.GetExecutionDir().Append(ConfigFile);
        end;
      end

      else if (Command = 'scorefile') then
      begin
        // check if there is another parameter to get the value from
        if (PCount > I) then
        begin
          // write value to string
          ScoreFile := Path(ParamStr(I + 1));
        end;
      end;

    end;

  end;

{
  Log.LogInfo('Screens: ' + Inttostr(Screens));
  Log.LogInfo('Depth: ' + Inttostr(Depth));

  Log.LogInfo('Resolution: ' + Inttostr(Resolution));
  Log.LogInfo('Language: ' + Inttostr(Language));

  Log.LogInfo('sResolution: ' + sResolution);
  Log.LogInfo('sLanguage: ' + sLanguage);

  Log.LogInfo('ConfigFile: ' + ConfigFile);
  Log.LogInfo('SongPath: ' + SongPath);
  Log.LogInfo('ScoreFile: ' + ScoreFile);
}

end;

//-------------
// GetLanguage - Get Language ID from saved String Information
//-------------
function TCMDParams.GetLanguage: integer;
begin
  Result := StrToIntDef(fLanguage, -1);
end;

//-------------
// GetResolution - Get Resolution ID from saved String Information
//-------------
function TCMDParams.GetResolution: integer;
begin
  Result := StrToIntDef(fResolution, -1);
end;

end.
