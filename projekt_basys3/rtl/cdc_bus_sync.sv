//===========================================================================
// Modu realizuje zapezpieczenia wielobitowych szyn danych przy przenoszeniu
// ich z jednej domeny zegarowej do drugiej
//===========================================================================
module cdc_bus_sync #(
    parameter DATA_WIDTH = 8
)(
    // --- Domena zegara źródłowego ---
    input logic clk_in,
    input logic rst_n,
    input logic [DATA_WIDTH-1:0] data_in,
    input logic valid_in,

    // --- Domena zegara docelowego ---
    input logic clk_out,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic valid_out
);

//#######################################################################
// 1. ZEGAR ŹRÓDŁOWY (clk_in): Zamiana impulsu na sygnał stały (Toggle)
//#######################################################################

logic toggle_in;

always_ff @(posedge clk_in, negedge rst_n) begin
    if(!rst_n) begin
        toggle_in <= '0;
    end
    else begin
        if(valid_in) begin
            toggle_in <= ~toggle_in;
        end
    end
end

//#######################################################################
// 2. ZEGAR DOCELOWY (clk_out): Podwójny synchronizator + Detekcja zbocza
//#######################################################################

logic sync_1, sync_2, sync_3;

always_ff @(posedge clk_out, negedge rst_n) begin
    if(!rst_n) begin
        sync_1 <= '0;
        sync_2 <= '0;
        sync_3 <= '0;
    end
    else begin
        sync_1 <= toggle_in;
        sync_2 <= sync_1;
        sync_3 <= sync_2;
    end
end

assign valid_out = sync_2 ^ sync_3;

//##############################################################
// 3. ZEGAR DOCELOWY (clk_out): Zatrzaśnięcie danych
//##############################################################
always_ff @(posedge clk_out, negedge rst_n) begin
    if(!rst_n) begin
        data_out <= '0;
    end
    else begin
        if(valid_out) begin
            //zatrzasniecie i przepisania danych gdy toggle zmienił stan
            data_out <= data_in;
        end
    end
end
endmodule