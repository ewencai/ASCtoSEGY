function ASCtoSGY3(ascFilePath, outputPath)
% ASCtoSGY2 将指定目录下所有 ASC 文件合并为 SEG-Y 文件
% 
% 特性:
% 1. 支持在代码头部直接修改硬编码路径，方便一键运行
% 2. 自动提取 ASC 文件的公共前缀作为 SEG-Y 的文件名
% 3. 自动将深度修正为正向（符合实际物理空间）
% 4. 自动处理 SEG-Y 道头整数截断问题，确保深度信息无损保存

    %% ========================================================
    %% 参数设置 - 用户可修改部分 (如果直接点击运行，将使用这里的默认值)
    %% ========================================================
    if nargin < 1 || isempty(ascFilePath)
        % 设置 ASC 文件所在路径
        ascFilePath = 'X:\71.2026年辽河储气库\3.数据处理（新算法）\布格数据（2026年）\雷61\L61-DTP\L61-DTP补充\';
    end
    
    if nargin < 2 || isempty(outputPath)
        % 设置输出 SEG-Y 文件路径（默认为 ASC 文件同一目录）
        outputPath = ascFilePath; 
    end
    %% ========================================================

    % 1. 获取指定目录下的所有 ASC 文件
    files = dir(fullfile(ascFilePath, '*.asc'));
    nFiles = numel(files);
    if nFiles == 0
        error('在路径 "%s" 下未找到任何 ASC 文件，请检查路径是否正确。', ascFilePath);
    end

    % 2. 自动生成输出文件名（提取所有ASC文件名的最长公共前缀）
    fileNames = {files.name};
    baseName = fileNames{1};
    for i = 2:nFiles
        str2 = fileNames{i};
        len = min(length(baseName), length(str2));
        % 寻找第一个不匹配的字符位置
        matchIdx = find(baseName(1:len) ~= str2(1:len), 1, 'first');
        if ~isempty(matchIdx)
            baseName = baseName(1:matchIdx-1);
        end
    end
    % 清理末尾可能多余的下划线、短横线或点号
    baseName = regexprep(baseName, '[_\-\.]+$', ''); 
    if isempty(baseName)
        baseName = 'merged_volume'; % 容错处理
    end
    
    outputFilename = fullfile(outputPath, [baseName, '.sgy']);
    fprintf('▶ 目标输出文件: %s\n', outputFilename);

    % 3. 读取第一个文件初始化网格参数
    first_file_path = fullfile(ascFilePath, files(1).name);
    [data0, nCols, nRows, xllCorner, yllCorner, cellSize, ~] = readASCFile(first_file_path);
    volume = nan(nRows, nCols, nFiles);
    depths = zeros(nFiles,1);

    % 4. 读取所有文件
    for k = 1:nFiles
        fname = files(k).name;
        full_fname = fullfile(ascFilePath, fname);
        fprintf('  读取第 %d/%d 个 ASC 文件: %s\n', k, nFiles, fname);

        % 从文件名中提取尺度（delt64toXXX）
        tok = regexp(fname, 'delt(\d+)', 'tokens');
        if isempty(tok)
            error('无法从文件名 %s 提取尺度', fname);
        end
        scale = str2double(tok{1}{1});

        [data, nc, nr, xll, yll, cs, ~] = readASCFile(full_fname);

        % 检查网格一致性
        if nc~=nCols || nr~=nRows
            error('文件 %s 网格尺寸不一致: %d×%d vs %d×%d', fname, nr, nc, nRows, nCols);
        end
        if xll ~= xllCorner || yll ~= yllCorner || cs ~= cellSize
            error('文件 %s 网格参数不一致', fname);
        end

        volume(:,:,k) = data;
        
        % 修改点 1：将深度改为向下为正，物理意义对应实际深度
        depths(k) = scale * cellSize * 2.5; 
    end

    % 5. 按深度升序排序
    [depths, idx] = sort(depths);
    volume = volume(:,:,idx);

    % 6. 计算采样间隔 dt
    nDepths = numel(depths);
    if nDepths > 1
        dt = (depths(end) - depths(1)) / (nDepths - 1);
    else
        dt = 1; % 单切片默认 dt=1
    end

    % 构建 Data 矩阵，每列为一个 (i,j) 位置剖面
    nTraces = nRows * nCols;
    Data = nan(nDepths, nTraces);
    [I, J] = ndgrid(1:nRows, 1:nCols);
    I = I(:); J = J(:);
    for k = 1:nDepths
        slice = volume(:,:,k);
        Data(k, :) = slice(:)';
    end

    % 生成道头信息，保证为行向量
    Inline    = I(:)';           
    Crossline = J(:)';           
    X = (xllCorner + (J-1) * cellSize)'; X = X(:)';  
    Y = (yllCorner + (nRows - I) * cellSize)'; Y = Y(:)';  
    CDP = 1:nTraces;             

    % 检查 Data 列数和头信息长度一致
    assert(size(Data,2) == numel(Inline), 'Data 列数与头信息长度不一致');

    % 修改点 2：处理 SEG-Y 道头整数截断问题 (乘以1000变毫米存储)
    scale_factor = 1000; 
    dt_scaled = round(dt * scale_factor);
    start_depth_scaled = round(depths(1) * scale_factor);
    
    % 修改点 3：抵消 WriteSegy 内部自动乘以 1e6 的机制
    dt_input_to_WriteSegy = dt_scaled / 1e6;

    % 7. 写入 SEG-Y 文件主体
    fprintf('▶ 正在生成 SEG-Y 文件主体...\n');
    WriteSegy(outputFilename, Data, ...
        'dt', dt_input_to_WriteSegy, ...
        'Inline3D', Inline, 'Crossline3D', Crossline, ...
        'cdpX', X, 'cdpY', Y);

    % 更新 CDP 道头
    WriteSegyTraceHeaderValue(outputFilename, CDP, 'key', 'cdp');

    % 修改点 4：强制写入起始深度和真实采样间隔
    fprintf('▶ 正在将深度信息(精确至毫米)写入 SEG-Y 道头...\n');
    
    % 写入起始深度 (利用 DelayRecordingTime 字段)
    DelayRecordingTime = repmat(start_depth_scaled, 1, nTraces);
    WriteSegyTraceHeaderValue(outputFilename, DelayRecordingTime, 'key', 'DelayRecordingTime');
    
    % 双重保险：直接复写 dt 字段
    dt_array = repmat(dt_scaled, 1, nTraces);
    WriteSegyTraceHeaderValue(outputFilename, dt_array, 'key', 'dt');

    fprintf('✅ 处理完毕！文件已保存至: %s\n', outputFilename);
    fprintf('💡 提示: 导入专业软件时，请设定 Z轴/时间 维度的单位为毫米或乘以 0.001 缩放系数。\n');
end