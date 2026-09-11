`timescale 1ns / 1ps

module rtc_clock (
    input  logic clk_65MHz,
    input  logic rst_n,

    input  logic set_time_trigger,
    input  logic [4:0] set_hour,
    input  logic [5:0] set_min,
    input  logic [4:0] set_day,
    input  logic [3:0] set_mon,

    output logic [4:0] hours,
    output logic [5:0] minutes,
    output logic [5:0] seconds,
    output logic [4:0] days,
    output logic [3:0] months,

    output logic time_updated
);

    // --- Prosty detektor zbocza dla kliknięcia w przycisk "Zapisz czas" ---
    logic set_time_prev;
    logic set_time_pulse;

    always_ff @(posedge clk_65MHz or negedge rst_n) begin
        if (!rst_n) set_time_prev <= 1'b0;
        else set_time_prev <= set_time_trigger;
    end
    assign set_time_pulse = set_time_trigger && !set_time_prev;

    // --- Dzielnik generujący tyknięcie co 1 sekundę ---
    logic [26:0] clk_divider;
    logic one_second_tick;

    always_ff @(posedge clk_65MHz or negedge rst_n) begin
        if (!rst_n) begin
            clk_divider <= 27'd0;
            one_second_tick <= 1'b0;
        end else begin
            // Liczymy do 65 milionów
            if (clk_divider == 27'd65_000_000 - 1) begin
                clk_divider <= 27'd0;
                one_second_tick <= 1'b1;
            end else begin
                clk_divider <= clk_divider + 1'b1;
                one_second_tick <= 1'b0;
            end
        end
    end

    // --- Główny licznik czasu realnego ---
    always_ff @(posedge clk_65MHz or negedge rst_n) begin
        if (!rst_n) begin
            hours <= 5'd12; minutes <= 6'd0; seconds <= 6'd0;
            days  <= 5'd15; months  <= 4'd6;
        end else if (set_time_pulse) begin
            hours   <= set_hour; 
            minutes <= set_min;
            seconds <= 6'd0;
            days    <= set_day;
            months  <= set_mon;
        end else if (one_second_tick) begin
            if (seconds == 6'd59) begin
                seconds <= 6'd0;
                if (minutes == 6'd59) begin
                    minutes <= 6'd0;
                    if (hours == 5'd23) begin
                        hours <= 5'd0;
                        if (days == 5'd31) begin
                            days <= 5'd1;
                            months <= (months == 4'd12) ? 4'd1 : months + 1'b1;
                        end else days <= days + 1'b1;
                    end else hours <= hours + 1'b1;
                end else minutes <= minutes + 1'b1;
            end else seconds <= seconds + 1'b1;
        end
    end

    assign time_updated = one_second_tick | set_time_pulse;
endmodule