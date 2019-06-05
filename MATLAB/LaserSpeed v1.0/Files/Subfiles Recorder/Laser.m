classdef Laser < handle
    properties
        curState = struct(          ...
            'auto_start',   'ID',     ...
            'pilot_laser',  0,      ...
            'scaling',      1,      ...
            'offset',       0,      ...
            'window_start', 0,      ...
            'window_end',   50,     ...
            'freq',         2000,   ...
            'mean',         20     );
        
        desState = struct(      ...
            'auto_start',   [], ...
            'pilot_laser',  [],	...
            'scaling',      [],	...
            'offset',       [],	...
            'window_start', [],	...
            'window_end',   [],	...
            'freq',         [],	...
            'mean',         []	);
        
        messages = struct(                          ...
            'msg_id'              , 'ID',           ...
            'msg_settings'        , 'PA',           ...
            'msg_single_dista'    , 'DM',           ...
            'msg_contin_dista'    , 'DT',           ...
            'msg_single_speed'    , 'VM',           ...
            'msg_contin_speed'    , 'VT',           ...
            'msg_auto_start'      , 'AS',           ...
            'msg_pilot_laser'     , 'PL',           ...
            'msg_scaling'         , 'SF',           ...
            'msg_offset'          , 'OF',           ...
            'msg_window'          , 'MW',           ...
            'msg_freq'            , 'MF',           ...
            'msg_mean'            , 'SA',           ...
            'msg_stop'            , hex2dec('1B'),  ...
            'msg_terminator'      , 13      );
        
        COMport
        Data
        Time
        Distance
        port
        realtimeTrigger = 0;
        sampleFreq = 1;
        startTime
    end
    
    methods
        
        %% Settings
        function setCOMport(obj,n)
            if (n>=0) && (mod(n,1)==0)
                if ispc
                    obj.COMport = ['COM' num2str(n)];
                else
                    warning('not running on a Windows PC');
                end
            else
                warning('Please insert a positive integer');
            end
        end
        
        function setState(obj,var,val)
            switch var
                case 'auto_start'
                    obj.desState.auto_start = val;
                case 'pilot_laser'
                    obj.desState.pilot_laser = val;
                case 'scaling'
                    obj.desState.scaling = val;
                case 'offset'
                    obj.desState.offset = val;
                case 'window_start'
                    obj.desState.window_start = val;
                case 'window_end'
                    obj.desState.window_end = val;
                case 'freq'
                    obj.desState.freq = val;
                case 'mean'
                    obj.desState.mean = val;
                otherwise
                    warning('invalid variable input')
            end
        end
        
        function SetLaser(obj)
            SendLaserCommand(obj,[obj.messages.msg_auto_start ' ' obj.curState.auto_start]);
            SendLaserCommand(obj,obj.messages.msg_scaling,obj.curState.scaling);
            SendLaserCommand(obj,obj.messages.msg_offset,obj.curState.offset);
            SendLaserCommand(obj,obj.messages.msg_window,obj.curState.window_start,obj.curState.window_end);
            SendLaserCommand(obj,obj.messages.msg_freq,obj.curState.freq);
            SendLaserCommand(obj,obj.messages.msg_mean,obj.curState.mean);
        end
        
        function sampleFrequency(obj)
            laserFrequency = obj.curState.freq;
            window = obj.curState.mean;
            fs = laserFrequency/window;
            obj.sampleFreq = fs;
        end
        
        function updateLaser(obj)
            obj.curState = obj.desState;
        end
        
        %% Operations
        function ReceiveLaserData(obj,src,~)
            global axesHandle
            message = strtrim(fscanf(src));
            if length(message) == 10
                value = str2double(message(3:10));
                obj.Data = [obj.Data; value];
                obj.Time = ((0:length(obj.Data)-1)').*(1/(obj.sampleFreq*24*60*60))+obj.startTime;
                if length(obj.Data) > obj.sampleFreq && (length(obj.Data)/10)-floor(length(obj.Data)/10) == 0
                    t = ((0:obj.sampleFreq)')./obj.sampleFreq;
                    p = polyfit(t,obj.Data(end-obj.sampleFreq:end),1);
                    sCF = t*p(1)+p(2);
                    speed = (sCF(end)-sCF(end-1))*obj.sampleFreq;
                    set(axesHandle,'string',sprintf('Distance: %5.3f m, Speed: %5.3f m/s',sCF(end),speed))
                end
                
                %                 if length(obj.Data) >= 2
                %                     time = (0:length(obj.Data)-2)'*(1/obj.sampleFreq);
                %                     speedVal = diff(obj.Data);
                %                     axes(axesHandle)
                %                     pHandle = get(axesHandle,'UserData');
                %                     set(pHandle,'XData',time);
                %                     set(pHandle,'YData',speedVal);
                %                 end
            end
            src.UserData = 0;
        end
        
        function LaserDistance(obj)
            StartMeasurement(obj);
            pause(1)
            StopMeasurement(obj);
            obj.Distance = mean(obj.Data);
            obj.Data = [];
            obj.Time = [];
        end
            
        function StartMeasurement(obj)
            sampleFrequency(obj)
            obj.startTime = now;
            SendLaserCommand(obj,obj.messages.msg_contin_dista);
        end
        
        function StopMeasurement(obj)
            SendLaserCommand(obj,obj.messages.msg_stop);
        end
        
        function PilotOn(obj)
            SendLaserCommand(obj,obj.messages.msg_pilot_laser,1);
        end
        
        function PilotOff(obj)
            SendLaserCommand(obj,obj.messages.msg_pilot_laser,0);
        end
        
        function SendLaserCommand(obj,command,varargin)
            % check whether the serial port is open
            if strcmp(obj.port.Status,'open')
                if (nargin==2)
                    if length(command)<2
                        fprintf(obj.port,'%c',command);
                        fprintf(1,'Sc: %c\n ',command);
                    else
                        fprintf(obj.port,command);
                        fprintf(1,'S: %s\n ',command);
                    end
                    obj.port.UserData = 1;
                else
                    message = [command sprintf('%5.3f ',varargin{:})];
                    fprintf(obj.port,message);
                    fprintf(1,'S: %s\n',message);
                    obj.port.UserData = 1;
                end
                timeout = 0;
                while (obj.port.UserData>0) && (timeout<15)
                    pause(0.1);
                    timeout = timeout + 1;
                end
                if (timeout==15)
                    fprintf(1,'ERROR: Message timeout.\n');
                end
            else
                % error
                fprintf(1,'ERROR: Laser not connected.\n');
            end
        end
        
        %% Connection functions
        function ConnectLaser(obj)
            try
                obj.startTime = now;
                obj.port = serial(obj.COMport,'BaudRate',115200,'DataBits',8,'Parity','none','StopBits',1);
                fopen(obj.port);
                obj.port.Terminator = {obj.messages.msg_terminator,obj.messages.msg_terminator};
                obj.port.BytesAvailableFcn = {@obj.ReceiveLaserData};
                obj.port.UserData = 0;
            catch e
                warning('Error connecting');
            end
        end
        
        function DisconnectLaser(obj)
            disp('Disconnecting laser')
            try
                fclose(obj.port);
            catch e
                warning('Error disconnecting');
            end
        end
    end
end