function [data] = cparFinalizeSampling(dev, data)
% cparFinalizeSampling Finalize sampling of data from the cpar deviced
%    [data] = cparFinalizeSampling(dev, data) finalize sampling of data from
%    the cpar device. This stops the sampling of data, and it converts the
%    .NET data structures in the [data] sampling structure to Matlab data
%    structures, which are easier to work with.
%
% See also, cparPlot

    cparStopSampling(dev);
    data.Pressure01 = ConvertToArray(data.Pressure01);
    data.Pressure02 = ConvertToArray(data.Pressure02);
    data.Target01 = ConvertToArray(data.Target01);
    data.Target02 = ConvertToArray(data.Target02);
    data.VAS = ConvertToArray(data.VAS);
    
    data.t = (0:length(data.Pressure01)-1)/20;
end

function [x] = ConvertToArray(list)
    x = zeros(1, list.Count);
    
    for n = 0:list.Count - 1 
        x(n + 1) = list.Item(n);
    end
end