program samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Horse,
  Horse.Logger, // It's necessary to use the unit
  Horse.Logger.Provider.Console, // It's necessary to use the unit
  System.SysUtils;

//var
//  LLogFileConfig: THorseLoggerConsoleConfig;

begin
//  LLogFileConfig := THorseLoggerConsoleConfig.New
//    .SetLogFormat('${request_clientip} [${time}] ${response_status}');

  // You can also specify the log format:
  // THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New(LLogFileConfig));

  // Here you will define the provider that will be used.
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New());

  // It's necessary to add the middleware in the Horse:
  THorse.Use(THorseLoggerManager.HorseCallback);

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
