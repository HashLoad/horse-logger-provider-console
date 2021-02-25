unit Horse.Logger.Provider.Console;

{$IFDEF FPC }
{$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC }
  Classes,
{$ELSE}
  System.Classes,
{$ENDIF}
  Horse.Logger;

type

  THorseLoggerConsoleConfig = class
  private
    { private declarations }
    FLogFormat: string;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create;
    function SetLogFormat(ALogFormat: string): THorseLoggerConsoleConfig;
    function GetLogFormat(out ALogFormat: string): THorseLoggerConsoleConfig;
    class function New: THorseLoggerConsoleConfig;
  end;

  THorseLoggerProviderConsoleManager = class(THorseLoggerThread)
  private
    { private declarations }
    FConfig: THorseLoggerConsoleConfig;
  protected
    { protected declarations }
    procedure DispatchLogCache; override;
  public
    { public declarations }
    destructor Destroy; override;
    function SetConfig(AConfig: THorseLoggerConsoleConfig): THorseLoggerProviderConsoleManager;
  end;

  THorseLoggerProviderConsole = class(TInterfacedObject, IHorseLoggerProvider)
  private
    { private declarations }
    FHorseLoggerProviderConsoleManager: THorseLoggerProviderConsoleManager;
  protected
    { protected declarations }
  public
    { public declarations }
    constructor Create(const AConfig: THorseLoggerConsoleConfig = nil);
    destructor Destroy; override;
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
    class function New(const AConfig: THorseLoggerConsoleConfig = nil): IHorseLoggerProvider;
  end;

implementation

uses
{$IFDEF FPC }
  SysUtils, fpJSON, SyncObjs{$IFDEF MSWINDOWS}, Windows{$ENDIF MSWINDOWS};
{$ELSE}
  System.SysUtils, System.JSON, System.SyncObjs{$IFDEF MSWINDOWS}, Winapi.Windows{$ENDIF MSWINDOWS};
{$ENDIF}

{ THorseLoggerProviderConsole }

const
  DEFAULT_HORSE_LOG_FORMAT =
    '${request_clientip} [${time}] ${request_user_agent}' +
    ' "${request_method} ${request_path_info} ${request_version}"' +
    ' ${response_status} ${response_content_length}';

constructor THorseLoggerProviderConsole.Create(const AConfig: THorseLoggerConsoleConfig = nil);
begin
  FHorseLoggerProviderConsoleManager := THorseLoggerProviderConsoleManager.Create(True);
  FHorseLoggerProviderConsoleManager.SetConfig(AConfig);
  FHorseLoggerProviderConsoleManager.FreeOnTerminate := False;
  FHorseLoggerProviderConsoleManager.Start;
end;

destructor THorseLoggerProviderConsole.Destroy;
begin
  FHorseLoggerProviderConsoleManager.Terminate;
  FHorseLoggerProviderConsoleManager.GetEvent.SetEvent;
  FHorseLoggerProviderConsoleManager.WaitFor;
  FHorseLoggerProviderConsoleManager.Free;
  inherited;
end;

procedure THorseLoggerProviderConsole.DoReceiveLogCache(ALogCache: THorseLoggerCache);
var
  I: Integer;
begin
  for I := 0 to Pred(ALogCache.Count) do
    FHorseLoggerProviderConsoleManager.NewLog(THorseLoggerLog(ALogCache.Items[0].Clone));
end;

class function THorseLoggerProviderConsole.New(const AConfig: THorseLoggerConsoleConfig = nil): IHorseLoggerProvider;
begin
  Result := THorseLoggerProviderConsole.Create(AConfig);
end;

{ TTHorseLoggerProviderConsoleThread }

destructor THorseLoggerProviderConsoleManager.Destroy;
begin
  FreeAndNil(FConfig);
  inherited;
end;

procedure THorseLoggerProviderConsoleManager.DispatchLogCache;
var
  I: Integer;
  Z: Integer;
  LLogCache: THorseLoggerCache;
  LLog: THorseLoggerLog;
  LParams: TArray<string>;
  LValue: {$IFDEF FPC}THorseLoggerLogItemString{$ELSE}string{$ENDIF};
  LLogStr: string;
  LResponseStatus: Integer;
begin
  if FConfig = nil then
    FConfig := THorseLoggerConsoleConfig.New;
  FConfig.GetLogFormat(LLogStr);
  LLogCache := ExtractLogCache;
  try
    if LLogCache.Count = 0 then
      Exit;
    for I := 0 to Pred(LLogCache.Count) do
    begin
      LLog := LLogCache.Items[I] as THorseLoggerLog;
      LParams := THorseLoggerUtils.GetFormatParams(LLogStr);
      for Z := Low(LParams) to High(LParams) do
      begin
{$IFDEF FPC}
        if LLog.Find(LParams[Z], LValue) then
          LLogStr := LLogStr.Replace('${' + LParams[Z] + '}', LValue.AsString);
{$ELSE}
        if LLog.TryGetValue<string>(LParams[Z], LValue) then
          LLogStr := LLogStr.Replace('${' + LParams[Z] + '}', LValue);
{$ENDIF}
      end;
{$IFDEF FPC}
      if LLog.Find('response_status', LValue) then
      begin
        LResponseStatus := LValue.AsInteger;
{$ELSE}
      if LLog.TryGetValue<Integer>('response_status', LResponseStatus) then
      begin
{$ENDIF}
        if (LResponseStatus >= 200) and (LResponseStatus <= 299) then
          LLogStr := #27'[1;92m' + LLogStr + #27'[0m'
        else if (LResponseStatus >= 300) and (LResponseStatus <= 399) then
          LLogStr := #27'[1;94m' + LLogStr + #27'[0m'
        else if (LResponseStatus >= 400) and (LResponseStatus <= 499) then
          LLogStr := #27'[1;93m' + LLogStr + #27'[0m'
        else if (LResponseStatus >= 500) and (LResponseStatus <= 599) then
          LLogStr := #27'[1;91m' + LLogStr + #27'[0m';
      end;
{$IFDEF MSWINDOWS}
      SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), 7);
{$ENDIF MSWINDOWS}
      WriteLn(LLogStr);
    end;

  finally
    LLogCache.Free;
  end;
end;

function THorseLoggerProviderConsoleManager.SetConfig(AConfig: THorseLoggerConsoleConfig): THorseLoggerProviderConsoleManager;
begin
  Result := Self;
  FConfig := AConfig;
end;

{ THorseLoggerConfig }

constructor THorseLoggerConsoleConfig.Create;
begin
  FLogFormat := DEFAULT_HORSE_LOG_FORMAT;
end;

function THorseLoggerConsoleConfig.GetLogFormat(out ALogFormat: string): THorseLoggerConsoleConfig;
begin
  Result := Self;
  ALogFormat := FLogFormat;
end;

class function THorseLoggerConsoleConfig.New: THorseLoggerConsoleConfig;
begin
  Result := THorseLoggerConsoleConfig.Create;
end;

function THorseLoggerConsoleConfig.SetLogFormat(ALogFormat: string): THorseLoggerConsoleConfig;
begin
  Result := Self;
  FLogFormat := ALogFormat;
end;

end.
