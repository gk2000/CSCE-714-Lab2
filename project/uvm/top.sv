//=====================================================================
// Project: 4 core MESI cache design
// File Name: top.sv
// Description: testbench for cache top with environment
// Designers: Venky & Suru
//=====================================================================
// Notable Change History:
// Date By   Version Change Description
// 2016/12/01  1.0     Initial Release
// 2016/12/02  2.0     Added CPU MESI and LRU interface
//=====================================================================

    `define INST_TOP_CORE inst_cache_lv1_multicore
    `define READ_TIMEOUT 80
    `define WRITE_TIMEOUT 90

module top;

    //Import the UVM library
    import uvm_pkg::*;
    //Include the UVM macros
    `include "uvm_macros.svh"

//Lab2 TO DO: Include the cpu transaction class
    `include "cpu_transaction_c.sv"

    parameter DATA_WID_LV1           = `DATA_WID_LV1       ;
    parameter ADDR_WID_LV1           = `ADDR_WID_LV1       ;
    parameter DATA_WID_LV2           = `DATA_WID_LV2       ;
    parameter ADDR_WID_LV2           = `ADDR_WID_LV2       ;

    reg                           clk;
    wire [DATA_WID_LV2 - 1   : 0] data_bus_lv2_mem;
    wire [ADDR_WID_LV2 - 1   : 0] addr_bus_lv2_mem;
    wire                          data_in_bus_lv2_mem;
    wire                          mem_rd;
    wire                          mem_wr;
    wire                          mem_wr_done;

    wire [3:0]                    cpu_lv1_if_cpu_rd;
    wire [3:0]                    cpu_lv1_if_cpu_wr;
    wire [3:0]                    cpu_lv1_if_cpu_wr_done;
    wire [3:0]                    cpu_lv1_if_data_in_bus_cpu_lv1;

//Lab2 TO DO: Create handle for cpu_transaction_c class, name that handle as o_transaction
    cpu_transaction_c o_transaction;

    // Instantiate the interfaces
    cpu_lv1_interface       inst_cpu_lv1_if[0:3](clk);
    system_bus_interface    inst_system_bus_if(clk);

    // Assign internal signals of the interface
    assign inst_system_bus_if.data_bus_lv1_lv2      = inst_cache_top.data_bus_lv1_lv2;
    assign inst_system_bus_if.addr_bus_lv1_lv2      = inst_cache_top.addr_bus_lv1_lv2;
    assign inst_system_bus_if.data_in_bus_lv1_lv2   = inst_cache_top.data_in_bus_lv1_lv2;
    assign inst_system_bus_if.lv2_rd                = inst_cache_top.lv2_rd;
    assign inst_system_bus_if.lv2_wr                = inst_cache_top.lv2_wr;
    assign inst_system_bus_if.lv2_wr_done           = inst_cache_top.lv2_wr_done;
    assign inst_system_bus_if.cp_in_cache           = inst_cache_top.cp_in_cache;
    assign inst_system_bus_if.shared                = inst_cache_top.`INST_TOP_CORE.shared;
    assign inst_system_bus_if.all_invalidation_done = inst_cache_top.`INST_TOP_CORE.all_invalidation_done;
    assign inst_system_bus_if.invalidate            = inst_cache_top.`INST_TOP_CORE.invalidate;
    assign inst_system_bus_if.bus_rd                = inst_cache_top.`INST_TOP_CORE.bus_rd;
    assign inst_system_bus_if.bus_rdx               = inst_cache_top.`INST_TOP_CORE.bus_rdx;

    // instantiate memory golden model
    memory #(
            .DATA_WID(DATA_WID_LV2),
            .ADDR_WID(ADDR_WID_LV2)
            )
             inst_memory (
                            .clk                (clk                ),
                            .data_bus_lv2_mem   (data_bus_lv2_mem   ),
                            .addr_bus_lv2_mem   (addr_bus_lv2_mem   ),
                            .mem_rd             (mem_rd             ),
                            .mem_wr             (mem_wr             ),
                            .mem_wr_done        (mem_wr_done        ),
                            .data_in_bus_lv2_mem(data_in_bus_lv2_mem)
                         );

    // instantiate arbiter golden model
    lrs_arbiter  inst_arbiter (
                                    .clk(clk),
                                    .bus_lv1_lv2_gnt_proc (inst_system_bus_if.bus_lv1_lv2_gnt_proc ),
                                    .bus_lv1_lv2_req_proc (inst_system_bus_if.bus_lv1_lv2_req_proc ),
                                    .bus_lv1_lv2_gnt_snoop(inst_system_bus_if.bus_lv1_lv2_gnt_snoop),
                                    .bus_lv1_lv2_req_snoop(inst_system_bus_if.bus_lv1_lv2_req_snoop),
                                    .bus_lv1_lv2_gnt_lv2  (inst_system_bus_if.bus_lv1_lv2_gnt_lv2  ),
                                    .bus_lv1_lv2_req_lv2  (inst_system_bus_if.bus_lv1_lv2_req_lv2  )
                               );
    assign cpu_lv1_if_cpu_rd                = {inst_cpu_lv1_if[3].cpu_rd,inst_cpu_lv1_if[2].cpu_rd,inst_cpu_lv1_if[1].cpu_rd,inst_cpu_lv1_if[0].cpu_rd};
    assign cpu_lv1_if_cpu_wr                = {inst_cpu_lv1_if[3].cpu_wr,inst_cpu_lv1_if[2].cpu_wr,inst_cpu_lv1_if[1].cpu_wr,inst_cpu_lv1_if[0].cpu_wr};
    assign {inst_cpu_lv1_if[3].cpu_wr_done,inst_cpu_lv1_if[2].cpu_wr_done,inst_cpu_lv1_if[1].cpu_wr_done,inst_cpu_lv1_if[0].cpu_wr_done} = cpu_lv1_if_cpu_wr_done;
    assign {inst_cpu_lv1_if[3].data_in_bus_cpu_lv1,inst_cpu_lv1_if[2].data_in_bus_cpu_lv1,inst_cpu_lv1_if[1].data_in_bus_cpu_lv1,inst_cpu_lv1_if[0].data_in_bus_cpu_lv1} = cpu_lv1_if_data_in_bus_cpu_lv1;

    // instantiate DUT (L1 and L2)
    cache_top inst_cache_top (
                                .clk(clk),
                                .data_bus_cpu_lv1_0     (inst_cpu_lv1_if[0].data_bus_cpu_lv1              ),
                                .addr_bus_cpu_lv1_0     (inst_cpu_lv1_if[0].addr_bus_cpu_lv1              ),
                                .data_bus_cpu_lv1_1     (inst_cpu_lv1_if[1].data_bus_cpu_lv1              ),
                                .addr_bus_cpu_lv1_1     (inst_cpu_lv1_if[1].addr_bus_cpu_lv1              ),
                                .data_bus_cpu_lv1_2     (inst_cpu_lv1_if[2].data_bus_cpu_lv1              ),
                                .addr_bus_cpu_lv1_2     (inst_cpu_lv1_if[2].addr_bus_cpu_lv1              ),
                                .data_bus_cpu_lv1_3     (inst_cpu_lv1_if[3].data_bus_cpu_lv1              ),
                                .addr_bus_cpu_lv1_3     (inst_cpu_lv1_if[3].addr_bus_cpu_lv1              ),
                                .cpu_rd                 (cpu_lv1_if_cpu_rd                          ),
                                .cpu_wr                 (cpu_lv1_if_cpu_wr                          ),
                                .cpu_wr_done            (cpu_lv1_if_cpu_wr_done                     ),
                                .bus_lv1_lv2_gnt_proc   (inst_system_bus_if.bus_lv1_lv2_gnt_proc    ),
                                .bus_lv1_lv2_req_proc   (inst_system_bus_if.bus_lv1_lv2_req_proc    ),
                                .bus_lv1_lv2_gnt_snoop  (inst_system_bus_if.bus_lv1_lv2_gnt_snoop   ),
                                .bus_lv1_lv2_req_snoop  (inst_system_bus_if.bus_lv1_lv2_req_snoop   ),
                                .data_in_bus_cpu_lv1    (cpu_lv1_if_data_in_bus_cpu_lv1             ),
                                .data_bus_lv2_mem       (data_bus_lv2_mem                           ),
                                .addr_bus_lv2_mem       (addr_bus_lv2_mem                           ),
                                .mem_rd                 (mem_rd                                     ),
                                .mem_wr                 (mem_wr                                     ),
                                .mem_wr_done            (mem_wr_done                                ),
                                .bus_lv1_lv2_gnt_lv2    (inst_system_bus_if.bus_lv1_lv2_gnt_lv2     ),
                                .bus_lv1_lv2_req_lv2    (inst_system_bus_if.bus_lv1_lv2_req_lv2     ),
                                .data_in_bus_lv2_mem    (data_in_bus_lv2_mem                        )
                            );

    // System clock generation
    initial begin
        clk = 1'b0;
        forever
            #5 clk = ~clk;
    end

    //Initial begin to run both drive() and check() in parallel.
    initial begin
        fork
            drive();
            check();
        join_none
    end
	
    //Definition of drive() task
    task drive();
	int success;
    logic ok;
        inst_cpu_lv1_if[0].addr_bus_cpu_lv1 <= 32'h0;
        inst_cpu_lv1_if[0].data_bus_cpu_lv1_reg <= 32'hz;
        inst_cpu_lv1_if[0].cpu_rd <= 1'b0;
        inst_cpu_lv1_if[0].cpu_wr <= 1'b0;
        inst_cpu_lv1_if[1].addr_bus_cpu_lv1 <= 32'h0;
        inst_cpu_lv1_if[1].data_bus_cpu_lv1_reg <= 32'hz;
        inst_cpu_lv1_if[1].cpu_rd <= 1'b0;
        inst_cpu_lv1_if[1].cpu_wr <= 1'b0;
        inst_cpu_lv1_if[2].addr_bus_cpu_lv1 <= 32'h0;
        inst_cpu_lv1_if[2].data_bus_cpu_lv1_reg <= 32'hz;
        inst_cpu_lv1_if[2].cpu_rd <= 1'b0;
        inst_cpu_lv1_if[2].cpu_wr <= 1'b0;
        inst_cpu_lv1_if[3].addr_bus_cpu_lv1 <= 32'h0;
        inst_cpu_lv1_if[3].data_bus_cpu_lv1_reg <= 32'hz;
        inst_cpu_lv1_if[3].cpu_rd <= 1'b0;
        inst_cpu_lv1_if[3].cpu_wr <= 1'b0;

    //Add a TEST
       `ifdef TEST5
    //Lab2: TO DO: Assign object to handle o_transaction
    //Randomize the handle pointing to an object such that request_type is always READ_REQ
    //If randomization is successful, make read on PROC[2], Use the read task that you would have created in HOMEWORK PART A
    //If randomization fails, it should report an error
            `uvm_info("Verbosity Low", "Start of Test 5", UVM_LOW)
            `uvm_info("Verbosity Low", "CSCE 714: Lab2", UVM_LOW)
            `uvm_info("Verbosity Medium", "CSCE 714: Lab2", UVM_MEDIUM)
            `uvm_info("Verbosity High", "CSCE 714: Lab2", UVM_HIGH)
            o_transaction = new();
            ok = o_transaction.randomize() with {request_type==READ_REQ;};
            if(ok) begin
                o_transaction.read(inst_cpu_lv1_if[2]);
            end
            else
                `uvm_error("ID 2","Randomization of o_transaction failed !!!");
            `uvm_info("Verbosity Low", "End of Test 5", UVM_LOW)
        `endif
	@(posedge clk);
        $finish;
    endtask
    
    //Definition of check() task
    task check();
        `uvm_info("ID 3","MSG: checker starts", UVM_HIGH);
        forever begin
            @(posedge clk);
            if(!($onehot0(inst_system_bus_if.bus_lv1_lv2_gnt_proc)))
                `uvm_error("ID 1","TBCHK: multiple proc grants");
            if(inst_cpu_lv1_if[0].cpu_rd && inst_cpu_lv1_if[0].cpu_wr)
                    `uvm_error("ID 1","CPU_RD and CPU_WR asserted simultaneously for CPU0");
            if(inst_cpu_lv1_if[1].cpu_rd && inst_cpu_lv1_if[1].cpu_wr)
                    `uvm_error("ID 1","CPU_RD and CPU_WR asserted simultaneously for CPU1");
            if(inst_cpu_lv1_if[2].cpu_rd && inst_cpu_lv1_if[2].cpu_wr)
                    `uvm_error("ID 1","CPU_RD and CPU_WR asserted simultaneously for CPU2");
            if(inst_cpu_lv1_if[3].cpu_rd && inst_cpu_lv1_if[3].cpu_wr)
                    `uvm_error("ID 1","CPU_RD and CPU_WR asserted simultaneously for CPU3");
	end
    endtask

endmodule
