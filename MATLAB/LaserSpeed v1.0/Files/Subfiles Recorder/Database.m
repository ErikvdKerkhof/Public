classdef Database < handle
    properties
        db
    end
    
    methods
        function Empty(obj)
            obj.db = cell(1,10);
            obj.db(1,:) = {'#' 'Name' 'Gender' 'Age' 'Date' 'Time' 'Type' 'Summersaults' 'Twists' 'Identifier'};
        end
        
        function Load(obj)
            load('LASERSPEEDdb.mat');
            obj.db = LASERSPEEDdb;
        end
        
        function Append(obj,info)
            Date         = datestr(now,'yyyy-mmm-dd');
            Time         = datestr(now,'HH:MM');
            
            number = sum(ismember(obj.db(:,2), info.Name))+1;
            Identifier   = [info.Name ' ' num2str(number)];
            
            [nRow nColl] = size(obj.db);
            obj.db(nRow+1,:) = cell(1,nColl);
            obj.db(end,:) = {nRow info.Name info.Gender info.Age Date Time info.Type info.Summersaults info.Twists Identifier};
        end
        
        function Save(obj)
            LASERSPEEDdb = obj.db;
            save([pwd '/Data/LASERSPEEDdb.mat'], 'LASERSPEEDdb')
        end
        
    end
end
