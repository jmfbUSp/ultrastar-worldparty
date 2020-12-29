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


unit UScreenStatMain;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses
  UMenu,
  sdl2,
  SysUtils,
  UDisplay,
  UMusic,
  UIni,
  UThemes;

type
  TScreenStatMain = class(TMenu)
    private
      //Some Stat Value that don't need to be calculated 2 times
      SongsWithVid: cardinal;
      function FormatOverviewIntro(FormatStr: UTF8String): UTF8String;
      function FormatSongOverview(FormatStr: UTF8String): UTF8String;
      function FormatPlayerOverview(FormatStr: UTF8String): UTF8String;
    public
      TextOverview:    integer;
      constructor Create; override;
      function ParseInput(PressedKey: cardinal; CharCode: UCS4Char; PressedDown: boolean): boolean; override;
      procedure OnShow; override;
      procedure SetAnimationProgress(Progress: real); override;

      procedure SetOverview;
  end;

implementation

uses
  Classes,
  UCommon,
  UGraphic,
  UDataBase,
  ULanguage,
  ULog,
  USongs,
  USong,
  UScreenStatDetail,
  UUnicodeUtils;

function TScreenStatMain.ParseInput(PressedKey: cardinal; CharCode: UCS4Char; PressedDown: boolean): boolean;
begin
  Result := true;
  if (PressedDown) then
  begin // Key Down
    // check special keys
    case PressedKey of
      SDLK_ESCAPE,
      SDLK_BACKSPACE :
        begin
          Ini.Save;
          AudioPlayback.PlaySound(SoundLib.Back);
          FadeTo(@ScreenMain);
        end;
      SDLK_RETURN:
        begin
          //Exit Button Pressed
          if Interaction = 4 then
          begin
            AudioPlayback.PlaySound(SoundLib.Back);
            FadeTo(@ScreenMain);
          end
          else //One of the Stats Buttons Pressed
          begin
            AudioPlayback.PlaySound(SoundLib.Back);
            ScreenStatDetail.Typ := TStatType(Interaction);
            FadeTo(@ScreenStatDetail);
          end;
        end;
      SDLK_LEFT:
      begin
          InteractPrev;
      end;
      SDLK_RIGHT:
      begin
          InteractNext;
      end;
      SDLK_UP:
      begin
          InteractPrev;
      end;
      SDLK_DOWN:
      begin
          InteractNext;
      end;
    end;
  end;
end;

constructor TScreenStatMain.Create;
begin
  inherited Create;

  TextOverview := AddText(Theme.StatMain.TextOverview);

  LoadFromTheme(Theme.StatMain);

  AddButton(Theme.StatMain.ButtonScores);
  if (Length(Button[0].Text)=0) then
    AddButtonText(14, 20, Theme.StatDetail.Description[0]);

  AddButton(Theme.StatMain.ButtonSingers);
  if (Length(Button[1].Text)=0) then
    AddButtonText(14, 20, Theme.StatDetail.Description[1]);

  AddButton(Theme.StatMain.ButtonSongs);
  if (Length(Button[2].Text)=0) then
    AddButtonText(14, 20, Theme.StatDetail.Description[2]);

  AddButton(Theme.StatMain.ButtonBands);
  if (Length(Button[3].Text)=0) then
    AddButtonText(14, 20, Theme.StatDetail.Description[3]);

  AddButton(Theme.StatMain.ButtonExit);

  Interaction := 0;
end;

procedure TScreenStatMain.OnShow;
var
  I: integer;
begin
  inherited;
  if not Assigned(UGraphic.ScreenStatDetail) then //load the screen only the first time
    UGraphic.ScreenStatDetail := TScreenStatDetail.Create();

  //Set Songs with Vid
  SongsWithVid := 0;
  for I := 0 to Songs.SongList.Count -1 do
    if (TSong(Songs.SongList[I]).Video.IsSet) then
      Inc(SongsWithVid);

  //Set Overview Text:
  SetOverview;
end;

function TScreenStatMain.FormatOverviewIntro(FormatStr: UTF8String): UTF8String;
var
  Year, Month, Day: word;
begin
  {Format:
    %0:d Ultrastar Version
    %1:d Day of Reset
    %2:d Month of Reset
    %3:d Year of Reset}

  Result := '';

  try
    DecodeDate(Database.GetStatReset(), Year, Month, Day);
    Result := Format(FormatStr, [Language.Translate('US_VERSION'), Day, Month, Year]);
  except
    on E: EConvertError do
      Log.LogError('Error Parsing FormatString "STAT_OVERVIEW_INTRO": ' + E.Message);
  end;
end;

function TScreenStatMain.FormatSongOverview(FormatStr: UTF8String): UTF8String;
var
  CntSongs, CntSungSongs, CntVidSongs: integer;
  MostPopSongArtist, MostPopSongTitle: UTF8String;
  StatList: TList;
  MostSungSong: TStatResultMostSungSong;
begin
  {Format:
    %0:d Count Songs
    %1:d Count of Sung Songs
    %2:d Count of UnSung Songs
    %3:d Count of Songs with Video
    %4:s Name of the most popular Song}

  CntSongs := Songs.SongList.Count;
  CntSungSongs := Database.GetTotalEntrys(stMostSungSong);
  CntVidSongs := SongsWithVid;

  StatList := Database.GetStats(stMostSungSong, 1, 0, false);
  if ((StatList <> nil) and (StatList.Count > 0)) then
  begin
    MostSungSong := StatList[0];
    MostPopSongArtist := MostSungSong.Artist;
    MostPopSongTitle := MostSungSong.Title;
  end
  else
  begin
    MostPopSongArtist := '-';
    MostPopSongTitle := '-';
  end;
  Database.FreeStats(StatList);

  Result := '';

  try
    Result := Format(FormatStr, [
        CntSongs, CntSungSongs, CntSongs-CntSungSongs, CntVidSongs,
        MostPopSongArtist, MostPopSongTitle]);
  except
    on E: EConvertError do
      Log.LogError('Error Parsing FormatString "STAT_OVERVIEW_SONG": ' + E.Message);
  end;
end;

function TScreenStatMain.FormatPlayerOverview(FormatStr: UTF8String): UTF8String;
var
  CntPlayers: integer;
  BestScoreStat:    TStatResultBestScores;
  BestSingerStat:   TStatResultBestSingers;
  BestPlayer, BestScorePlayer: UTF8String;
  BestPlayerScore, BestScore: integer;
  SingerStats, ScoreStats: TList;
begin
  {Format:
    %0:d Count Players
    %1:s Best Player
    %2:d Best Players Score
    %3:s Best Score Player
    %4:d Best Score}

  CntPlayers := Database.GetTotalEntrys(stBestSingers);

  SingerStats := Database.GetStats(stBestSingers, 1, 0, false);
  if ((SingerStats <> nil) and (SingerStats.Count > 0)) then
  begin
    BestSingerStat := SingerStats[0];
    BestPlayer := BestSingerStat.Player;
    BestPlayerScore := BestSingerStat.AverageScore;
  end
  else
  begin
    BestPlayer := '-';
    BestPlayerScore := 0;
  end;
  Database.FreeStats(SingerStats);

  ScoreStats  := Database.GetStats(stBestScores, 1, 0, false);
  if ((ScoreStats <> nil) and (ScoreStats.Count > 0)) then
  begin
    BestScoreStat := ScoreStats[0];
    BestScorePlayer := BestScoreStat.Singer;
    BestScore := BestScoreStat.Score;
  end
  else
  begin
    BestScorePlayer := '-';
    BestScore := 0;
  end;
  Database.FreeStats(ScoreStats);

  Result := '';

  try
    Result := Format(Formatstr, [
        CntPlayers, BestPlayer, BestPlayerScore,
        BestScorePlayer, BestScore]);
  except
    on E: EConvertError do
      Log.LogError('Error Parsing FormatString "STAT_OVERVIEW_PLAYER": ' + E.Message);
  end;
end;

procedure TScreenStatMain.SetOverview;
var
  Overview: UTF8String;
begin
  // Format overview
  Overview := FormatOverviewIntro(Language.Translate('STAT_OVERVIEW_INTRO')) + '\n \n' +
              FormatSongOverview(Language.Translate('STAT_OVERVIEW_SONG')) + '\n \n' +
              FormatPlayerOverview(Language.Translate('STAT_OVERVIEW_PLAYER'));
  Text[0].Text := Overview;
end;

procedure TScreenStatMain.SetAnimationProgress(Progress: real);
var
  I: integer;
begin
  for I := 0 to high(Button) do
    Button[I].Texture.ScaleW := Progress;
end;

end.
