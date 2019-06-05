%BT_EMG_Reader
% This file is a wrapper of the TMSI Matlab file. It wil provide a more
% user friendly GUI that is self-explaining. All data as shown in the plot
% will automatically be saved in a .mat file. The filename will be 
% automatically generated based on the time. Feel free to change this 
% script to your needs.
%
% This means that data can directly be loaded with Matlab. For example: 
% a measurement is saved in a file called: 20170517.mat. Then the data 
% can be loaded (put in the workspace) by calling: 
%
%                                               load('20170517.mat')
%
% After loading the file the workspace will have three new variables:
%                                       
%              1 - sampleRate: the samplerate of the loaded measurement
%              2 - saw: the saw signal, can be used to detect missing data
%              3 - signal: a struct containing the channels selected by the
%                          user. For example: access the data of channel A 
%                                             by typing:  signal.A
%
%	   Copyright (C) 2017  E. van den Kerkhof, M. Schrauwen (mjschrau@hhs.nl)
%
%	   This program is free software: you can redistribute it and/or modify
%	   it under the terms of the GNU General Public License as published by
%	   the Free Software Foundation, either version 3 of the License, or
%	   (at your option) any later version.
%
%	   This program is distributed in the hope that it will be useful,
%	   but WITHOUT ANY WARRANTY; without even the implied warranty of
%	   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%	   GNU General Public License for more details.
%
%	   You should have received a copy of the GNU General Public License
%	   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
% 
%
%%	$Revisie: 1.0.0.0 $  $Date: 2017-05-17 $
%	creation of file



function BT_EMG_Reader
clear all; close all; clc;
addpath(genpath('Toebehoren'));
global handles data
data = [];
%% Connect the device
try
      handles.library = TMSi.Library('bluetooth');
catch
      msgbox('Please install the TMSi drivers!');
end

% Find device to connect to. Keep on trying esvery second.
cntSearchDevice = 0;
while numel(handles.library.devices) == 0
    handles.library.refreshDevices();
    pause(1);
    if cntSearchDevice > 10;
        msgbox('Found no device. Please connect the device via Bluetooth.');
        return
    else
        cntSearchDevice = cntSearchDevice + 1;
    end
end
% Get first device an retrieve information about device.
try
    handles.device = handles.library.getFirstDevice();
catch
    msgbox('Turn the device on? Script is stopped.');
    return
end

%% Initialize interface using the number of available channels to create the required number of buttons
InitializeGUI()

end

function InitializeGUI
% creates a graphical user interface, sets up both the figure and
% uicontrols. also checks the connected device for information about the
% number of available channels and creates an textbox and checkbox for each
% channel
global handles

numChannels = CleanChannels();
fsOptions(1) = handles.device.base_sample_rate;
for i = 1:handles.device.sample_rate_setting
    fsOptions(i+1) =  fsOptions(i)/2;
end
figHeight = 20*(numChannels+4); %bepaal de hoogte van de interface, deze is dynamisch afhankelijk van het aantal kanalen. de +4 is een standaard afmeting voor de overige knoppen en spacing tussen knoppen

handles.fig = figure(...
    'Visible',      'on',...
    'NumberTitle',  'off',...
    'Resize',       'off',...
    'Color',        [240 240 240]./255,...
    'Position',     [200 200 125 figHeight],...
    'MenuBar',      'none',...
    'DeleteFcn',    @DeleteFcn);

handles.btnStartStop = uicontrol(...
    'Style',        'pushbutton',...
    'String',       'Start Meting',...
    'Position',     [10 10 80 20],...
    'Callback',     @StartStopCallback);

handles.btnHelp = uicontrol(...
    'Style',        'pushbutton',...
    'String',       '?',...
    'Position',     [100 figHeight-25 20 20],...
    'Callback',     @OpenHelp);

handles.FPSlist = uicontrol(...
    'Style',        'popupmenu',...
    'String',       num2cell(fsOptions),...
    'Position',     [10 40 50 20],...
    'Callback',     []);

handles.FPStext = uicontrol(...
    'Style',                'text',...
    'HorizontalAlignment',  'Left',...
    'String',               'Hz',...
    'Position',             [70 35 30 20],...
    'Callback',             []);

handles.Helptext = uicontrol(...
    'Style',                'text',...
    'HorizontalAlignment',  'Left',...
    'String',               sprintf('Scaling of the individual channels can be done with the key ''a''. Scaling will scale the channels to min-max.\nSet a fixed range can be done with the key ''r''. A dialog will show where you can enter the +/- uV range.'),...
    'Position',             [140 10 150 figHeight-20],...
    'Callback',             []);

for i = 1:numChannels
    handles.channels.(handles.device.channels{i}.name).checkbox = uicontrol(...
        'Style',    'Checkbox',...
        'Position', [10 (figHeight-10)-20*i 20 20],...
        'Callback', []);
    
    handles.channels.(handles.device.channels{i}.name).text = uicontrol(...
        'Style',                'text',...
        'HorizontalAlignment',  'Left',...
        'string',               sprintf('Channel %s',handles.device.channels{i}.name),...
        'Position',             [40 (figHeight-15)-20*i 60 20],...
        'Callback',             []);
end
end

function measurement
% provides all actions required to open a realtime plot and measure using
% the TMSI toolkit. also closes the connection with the device when the
% measurement is stopped
global handles data
data = [];
% Create a sampler with which we are going to retrieve samples.
sampler = handles.device.createSampler();

% Set settings for sampler.
sampler.setSampleRate(checkSelectedFrameRate());
sampler.setReferenceCalculation(true);
channel_subset = checkSelectedChannels();

% Create a RealTimePlot.
handles.realTimePlot = TMSi.RealTimePlot('RealTimePlot Example',...
    sampler.sample_rate, handles.device.channels(channel_subset));
handles.realTimePlot.setWindowSize(10);
handles.realTimePlot.show();

sampler.connect();
sampler.start();

while handles.realTimePlot.is_visible
    samples = sampler.sample();
    data = [data samples(channel_subset, :)];
    handles.realTimePlot.append(samples(channel_subset, :));
    handles.realTimePlot.draw();
end
sampler.stop();
sampler.disconnect();
end

function chans = checkSelectedChannels
% queries all checkboxes whether or not they are checked
global handles
mask = zeros(1,handles.device.num_channels);
saw = true;

if saw
    mask(end) = true;
end

for i = 1:CleanChannels
    mask(i) = get(handles.channels.(char(i+64)).checkbox,'Value');
end

chans = find(mask);
end

function fs = checkSelectedFrameRate
% queries the listbox which framerate is set by the user
global handles
val = get(handles.FPSlist,'Value');
list = get(handles.FPSlist,'String');
fs = str2double(list{val});
end

function StartStopCallback(src,~)
% callback of the start and stop button, changes button accordingly and
% calls the required method, either measurement or stop and save data
global handles data
switch get(src,'String');
    case 'Start Meting'
        set(src,'String','Stop Meting')
        measurement()
    case 'Stop Meting'
        set(src,'String','Start Meting')
        handles.realTimePlot.hide
        filename = GenerateFileName();
        saw = data(end,:);
        
        for i = 1:(size(data,1)-1)
            signal.(char(i+64)) = data(i,:);
        end
        
        sampleRate = checkSelectedFrameRate();
        save(filename,'saw','signal','sampleRate');
        msgbox(sprintf('Data saved under %s in %s',filename,pwd))        
end
end

function DeleteFcn(~,~)
% closes all open figures, including possible realtime plots
close all
end

function numChannels = CleanChannels
% clean the available channel list to only show the emg channels. searches
% for channelnames only consisting of one character
global handles
numChannels = 0;
for i = 1:handles.device.num_channels
    if length(handles.device.channels{i}.name) == 1
        numChannels = numChannels+1;
    end
end
end

function str = GenerateFileName
% This function generates a .mat filename based on the current date and
% time
str = num2str(fix(clock));
str(str==char(32))=[];
str = [str '.mat'];
end

function OpenHelp(src,~)
% Resizes the GUI-figure window to show or hide the help
global handles
switch get(src,'String');
    case '?'
        set(src,'String','<')
        pos = get(handles.fig,'Position');
        set(handles.fig,'Position',[pos(1) pos(2) 300 pos(4)]);
    case '<'
        set(src,'String','?')
        pos = get(handles.fig,'Position');
        set(handles.fig,'Position',[pos(1) pos(2) 125 pos(4)]);
end
end
