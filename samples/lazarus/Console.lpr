program Console;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse,
  Horse.Logger, // It's necessary to use the unit
  Horse.Logger.Provider.Console, // It's necessary to use the unit
  SysUtils;

//var
//  LLogFileConfig: THorseLoggerConsoleConfig;

procedure GetPing(Req: THorseRequest; Res: THorseResponse);
begin
  Res.Send('Pong');
end;

procedure OnListen;
begin
  Writeln(Format('Server is runing on %s:%d', [THorse.Host, THorse.Port]));
end;

begin
  // LLogFileConfig := THorseLoggerConsoleConfig.New
  //   .SetLogFormat('${request_clientip} [${time}] ${response_status}');

  // You can also specify the log format:
  // THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New(LLogFileConfig));

  // Here you will define the provider that will be used.
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New());

  // It's necessary to add the middleware in the Horse:
  THorse.Use(THorseLoggerManager.HorseCallback);

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000, OnListen);
end.
