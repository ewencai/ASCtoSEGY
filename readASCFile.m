function [data, nCols, nRows, xllCorner, yllCorner, cellSize, noDataValue] = readASCFile(fileName)
    % 读取ASC文件
    fid = fopen(fileName, 'r');
    if fid == -1
        error('无法打开文件: %s', fileName);
    end
    
    % 读取元数据
    nCols = fscanf(fid, 'ncols %d\n', 1);
    nRows = fscanf(fid, 'nrows %d\n', 1);
    xllCorner = fscanf(fid, 'xllcorner %f\n', 1);
    yllCorner = fscanf(fid, 'yllcorner %f\n', 1);
    cellSize = fscanf(fid, 'cellsize %f\n', 1);
    noDataValue = fscanf(fid, 'nodata_value %f\n', 1);
    
    % 读取数据
    data = fscanf(fid, '%f', [nCols, nRows])'; % 转置数据以匹配 nRows 和 nCols
    fclose(fid);
    
    % 处理无效值
    data(data == noDataValue) = NaN;
    
    % 只显示文件名，不显示完整路径
    [~, name, ext] = fileparts(fileName);
    % fprintf('Read File: %s\n', [name, ext]);
end