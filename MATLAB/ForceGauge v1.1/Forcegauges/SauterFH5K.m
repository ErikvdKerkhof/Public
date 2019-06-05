classdef SauterFH5K
    % this class generalizes the basic functions required to connect, disconnect and realtime read
    % data from the Sauter FH 5K to be used in the Forcegauge script
    % created for Human Technology students from THUAS.
    properties
        device
    end
    
    methods
        function obj = Connect(obj,COMport)
            obj.device = serial(COMport);
            set(obj.device,...
                'BaudRate',9600,...
                'DataBits',8,...
                'Parity','none',...
                'Terminator',char(46));
        end
        
        function StartAcquisition(obj)
            fopen(obj.device);
        end
        
        function val = GetData(obj)
            fprintf(obj.device,'%c',char(57));
            val = fscanf(obj.device,'%e');
            if isempty(val)
                val = 0;
            elseif(val>=100000)
                val = -val+100000;
            end
        end
        
        function StopAcquisition(obj)
            fclose(obj.device);
        end
        
        function Close(obj)
            delete(obj.device)
        end
        
    end
    
end

