try
    % Define serial port and baud rate
    serialPort = 'COM3';
    baudRate = 9600;

    % Create serial port object
    device = serialport(serialPort, baudRate);
    flush(device);

    % Prompt user for input value (0-255)
    inputValue = input('Enter a decimal value to send (0-255): ');

    % Check if input value is within valid range
    if inputValue < 0 || inputValue > 255
        error('Input value must be between 0 and 255.');
    end

    % Send the input value to the FPGA
    write(device, inputValue, "uint8");

    % Pause briefly for FPGA to process and respond
    pause(0.1);

    % Read the response from the FPGA (expecting a single byte response)
    response = read(device, 1, "uint8");

    % Display sent and received values
    fprintf('Sent: %d\n', inputValue);
    fprintf('Received: %d\n', response);

    % Verify the response
    if response == inputValue
        disp('Loopback test passed!');
    else
        disp('Loopback test failed!');
    end

    % Clear the serial port object
    clear device;

catch ME
    disp('An error occurred:');
    disp(ME.message);
end
