function serialPortGUI()
    % Create the main figure window with a title
    fig = uifigure('Name', 'GUI for UART Communication', 'Position', [100 100 900 600]);

    % Add components for configuring the port
    uilabel(fig, 'Position', [20 550 80 22], 'Text', 'Port:', 'FontWeight', 'bold');
    portDropDown = uidropdown(fig, 'Position', [110 550 100 22], 'Items', {'COM1', 'COM2', 'COM3', 'COM4', 'COM5'});

    % Add components for configuring the baud rate
    uilabel(fig, 'Position', [20 510 80 22], 'Text', 'Baud Rate:', 'FontWeight', 'bold');
    baudRateDropDown = uidropdown(fig, 'Position', [110 510 100 22], 'Items', {'9600'});

    % Add button to open the serial port
    openButton = uibutton(fig, 'Position', [230 530 100 40], 'Text', 'Open Port', 'ButtonPushedFcn', @(btn, event) openPort());

    % Add button to close the serial port
    closeButton = uibutton(fig, 'Position', [350 530 100 40], 'Text', 'Close Port', 'ButtonPushedFcn', @(btn, event) closePort());

    % Add panel for writing data
    writePanel = uipanel(fig, 'Title', 'Write Data', 'Position', [20 350 400 150]);
    
    % Add fields for writing to the serial port
    uilabel(writePanel, 'Position', [10 80 80 22], 'Text', 'Write Data:', 'FontWeight', 'bold');
    writeDataField = uieditfield(writePanel, 'numeric', 'Position', [100 80 100 22]);

    % Add button to write data
    writeButton = uibutton(writePanel, 'Position', [220 80 100 22], 'Text', 'Write', 'ButtonPushedFcn', @(btn, event) writeData());

    % Add a panel for 8-bit LED data representation for write function
    lampPanelWrite = uipanel(writePanel, 'Title', '8-bit LED Data Representation', 'Position', [10 10 380 60]);
    lampsWrite = gobjects(1, 8);
    lampLabelsWrite = gobjects(1, 8);
    for i = 1:8
        lampsWrite(i) = uilamp(lampPanelWrite, 'Position', [20 + (i-1)*45, 10, 20, 20]);
        lampsWrite(i).Color = 'black';
        lampLabelsWrite(i) = uilabel(lampPanelWrite, 'Position', [20 + (i-1)*45, -20, 20, 20], 'Text', '0', 'HorizontalAlignment', 'center');
    end

    % Add a field to display the binary representation for write function
    uilabel(fig, 'Position', [20 320 200 22], 'Text', 'Binary Representation (Write):', 'FontWeight', 'bold');
    binaryFieldWrite = uieditfield(fig, 'text', 'Position', [230 320 200 22]);

    % Add panel for reading data
    readPanel = uipanel(fig, 'Title', 'Read Data', 'Position', [440 350 400 150]);
    
    % Add fields for reading from the serial port
    uilabel(readPanel, 'Position', [10 80 80 22], 'Text', 'Read Data:', 'FontWeight', 'bold');
    readDataField = uieditfield(readPanel, 'text', 'Position', [100 80 100 22]); % Changed to 'text' to display read data

    % Add button to read data
    readButton = uibutton(readPanel, 'Position', [220 80 100 22], 'Text', 'Read', 'ButtonPushedFcn', @(btn, event) readData());

    % Add a panel for 8-bit LED data representation for read function
    lampPanelRead = uipanel(readPanel, 'Title', '8-bit LED Data Representation', 'Position', [10 10 380 60]);
    lampsRead = gobjects(1, 8);
    lampLabelsRead = gobjects(1, 8);
    for i = 1:8
        lampsRead(i) = uilamp(lampPanelRead, 'Position', [20 + (i-1)*45, 10, 20, 20]);
        lampsRead(i).Color = 'black';
        lampLabelsRead(i) = uilabel(lampPanelRead, 'Position', [20 + (i-1)*45, -20, 20, 20], 'Text', '0', 'HorizontalAlignment', 'center');
    end

    % Add a field to display the binary representation for read function
    uilabel(fig, 'Position', [440 320 200 22], 'Text', 'Binary Representation (Read):', 'FontWeight', 'bold');
    binaryFieldRead = uieditfield(fig, 'text', 'Position', [650 320 200 22]);

    % Add a text area to display messages
    messageArea = uitextarea(fig, 'Position', [20 20 860 250]);

    % Initialize serial port variable
    device = [];
    t = [];

    function openPort()
        try
            device = serialport(portDropDown.Value, str2double(baudRateDropDown.Value));
            messageArea.Value = ['Opened ' portDropDown.Value ' at ' baudRateDropDown.Value ' baud rate'];
            
            % Create and start a timer for real-time reading
            t = timer('ExecutionMode', 'fixedRate', 'Period', 1, 'TimerFcn', @(~,~) readData());
            start(t);
        catch e
            messageArea.Value = ['Error opening port: ' e.message'];
        end
    end

    function closePort()
        try
            if ~isempty(t)
                stop(t);
                delete(t);
                t = [];
            end
            if ~isempty(device)
                clear device;
                device = [];
            end
            messageArea.Value = 'Closed port successfully.';
        catch e
            messageArea.Value = ['Error closing port: ' e.message'];
        end
    end

    function writeData()
        if isempty(device)
            messageArea.Value = 'Please open a port first.';
            return;
        end

        data = writeDataField.Value;
        try
            if ~isempty(t) && strcmp(t.Running, 'on')
                stop(t); % Stop the timer while writing data
            end
            write(device, data, "uint8");
            messageArea.Value = ['Wrote data: ' num2str(data)];
            updateLampsWrite(data);
            binaryFieldWrite.Value = dec2bin(data, 8);
            if ~isempty(t)
                start(t); % Restart the timer after writing data
            end
        catch e
            messageArea.Value = ['Error writing data: ' e.message'];
            if ~isempty(t)
                start(t); % Restart the timer in case of error
            end
        end
    end

    function readData()
        if isempty(device)
            messageArea.Value = 'Please open a port first.';
            return;
        end

        try
            numBytes = device.NumBytesAvailable;
            if numBytes > 0
                data = read(device, numBytes, "uint8");
                readDataField.Value = num2str(data(end)); % Display only the last byte read
                messageArea.Value = ['Read data: ' num2str(data)];
                binaryFieldRead.Value = dec2bin(data(end), 8);
                updateLampsRead(data(end));
            end
        catch e
            messageArea.Value = ['Error reading data: ' e.message'];
        end
    end

    function updateLampsWrite(data)
        % Convert the data to binary string
        binData = dec2bin(data, 8);
        
        % Update the lamp colors and labels based on the binary string
        for i = 1:8
            if binData(i) == '1'
                lampsWrite(i).Color = 'green';
                lampLabelsWrite(i).Text = '1';
            else
                lampsWrite(i).Color = 'black';
                lampLabelsWrite(i).Text = '0';
            end
        end
    end

    function updateLampsRead(data)
        % Convert the data to binary string
        binData = dec2bin(data, 8);
        
        % Update the lamp colors and labels based on the binary string
        for i = 1:8
            if binData(i) == '1'
                lampsRead(i).Color = 'red';
                lampLabelsRead(i).Text = '1';
            else
                lampsRead(i).Color = 'black';
                lampLabelsRead(i).Text = '0';
            end
        end
    end

    % Ensure the timer stops when the figure is closed
    fig.CloseRequestFcn = @(~, ~) closeFigure();

    function closeFigure()
        closePort();
        delete(fig);
    end
end
