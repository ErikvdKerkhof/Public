classdef MecmesinAFG1000N
    % this class generalizes the basic functions required to connect, disconnect and realtime read
    % data from the Mecmesin AFG 1000N to be used in the Forcegauge script
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
                'Terminator','LF',...
                'Timeout', 0.05);
        end
        
        function StartAcquisition(obj)
            fopen(obj.device);
            readasync(obj.device);
            flushinput(obj.device);
            fscanf(obj.device,'%f')
            flushinput(obj.device);
        end
        
        function val = GetData(obj)
            val = fscanf(obj.device,'%f');
            if isempty(val)
                val = 0;
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


