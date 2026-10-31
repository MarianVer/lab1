`timescale 1ns / 1ps

module tb_i2c_master;

    // Сигнали
    reg clk;
    reg rst;
    reg start;
    reg [6:0] addr;
    reg [7:0] data;
    wire scl;
    wire sda;
    wire busy;

    // Підключення модуля I2C
    i2c_master uut (
        .clk(clk), 
        .rst(rst), 
        .start(start), 
        .addr(addr), 
        .data(data), 
        .scl(scl), 
        .sda(sda), 
        .busy(busy)
    );

    // Генерація тактового сигналу
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Період 10 нс
    end

    // Тестовий сценарій
    initial begin
        // Налаштування для виводу графіків
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_i2c_master);

        // Ініціалізація
        rst = 1;
        start = 0;
        addr = 7'b1010101; // Тестова адреса 0x55
        data = 8'b11001100; // Тестові дані 0xCC
        #20;
        
        rst = 0; // Знімаємо скидання
        #10;
        
        // Запуск транзакції
        start = 1;
        #10;
        start = 0;

        // Чекаємо завершення передачі (поки busy не впаде в 0)
        wait(busy == 0);
        
        #50;
        $display("Симуляція завершена успішно.");
        $finish;
    end
endmodule