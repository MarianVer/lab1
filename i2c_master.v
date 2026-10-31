`timescale 1ns / 1ps

module i2c_master (
    input wire clk,          // Системний тактовий сигнал
    input wire rst,          // Сигнал скидання (Reset)
    input wire start,        // Сигнал запуску транзакції
    input wire [6:0] addr,   // 7-бітна адреса Slave-пристрою
    input wire [7:0] data,   // 8-бітні дані для передачі
    output reg scl,          // Лінія тактування I2C
    inout wire sda,          // Двонаправлена лінія даних I2C
    output reg busy        // Флаг зайнятості модуля
);

    // Кодування станів FSM
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam ADDR  = 3'b010;
    localparam ACK1  = 3'b011;
    localparam DATA  = 3'b100;
    localparam ACK2  = 3'b101;
    localparam STOP  = 3'b110;

    reg [2:0] state, next_state;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg sda_out;
    reg sda_dir; // 1 - Master передає, 0 - Master слухає (для ACK)

    // Керування двонаправленою лінією SDA
    assign sda = (sda_dir) ? sda_out : 1'bz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            scl <= 1;
            sda_out <= 1;
            sda_dir <= 1;
            busy <= 0;
            bit_cnt <= 0;
        end else begin
            case (state)
                IDLE: begin
                    scl <= 1; sda_out <= 1; sda_dir <= 1;
                    if (start) begin
                        state <= START;
                        busy <= 1;
                        shift_reg <= {addr, 1'b0}; // Адреса + біт запису (Write=0)
                    end else begin
                        busy <= 0;
                    end
                end

                START: begin
                    sda_out <= 0; // SDA падає при високому SCL (умова START)
                    state <= ADDR;
                    bit_cnt <= 7;
                end

                ADDR: begin
                    scl <= ~scl; // Генерація SCL
                    if (scl == 0) begin
                        sda_out <= shift_reg[bit_cnt];
                        if (bit_cnt == 0) state <= ACK1;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end

                ACK1: begin
                    scl <= ~scl;
                    if (scl == 0) begin
                        sda_dir <= 0; // Відпускаємо SDA, щоб Slave дав ACK
                        state <= DATA;
                        shift_reg <= data;
                        bit_cnt <= 7;
                    end
                end

                DATA: begin
                    scl <= ~scl;
                    if (scl == 0) begin
                        sda_dir <= 1;
                        sda_out <= shift_reg[bit_cnt];
                        if (bit_cnt == 0) state <= ACK2;
                        else bit_cnt <= bit_cnt - 1;
                    end
                end

                ACK2: begin
                    scl <= ~scl;
                    if (scl == 0) begin
                        sda_dir <= 0; // Чекаємо ACK на дані
                        state <= STOP;
                    end
                end

                STOP: begin
                    scl <= 1;
                    sda_dir <= 1;
                    sda_out <= 0;
                    if (scl == 1) begin
                        sda_out <= 1; // SDA піднімається при високому SCL (умова STOP)
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule