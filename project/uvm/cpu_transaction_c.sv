//=====================================================================
// Project: 4 core MESI cache design
// File Name: cpu_transaction.sv
// Description: basic transaction class which is passed to the cpu agent and
// scoreboard
// Designers: Venky & Suru
//=====================================================================

//Lab2: TO DO:: Write transaction class

//Enumerated type defined for request_type and access_cache_type

typedef enum bit {READ_REQ=0, WRITE_REQ=1} request_t;
typedef enum bit {ICACHE_ACC, DCACHE_ACC} access_cache_t;

//Declare a class cpu_transaction_c
class cpu_transaction_c;

    parameter DATA_WID_LV1      = `DATA_WID_LV1;
    parameter ADDR_WID_LV1      = `ADDR_WID_LV1;

//In the transaction class, below 4 class properties are needed. All class properties should be declared random.
//1.  request_type of type request_t
//2.  data of type bit(32 bit wide)
//3.  address of type bit(32 bit wide)
//4.  access_cache_type of type access_cache_t
    rand request_t request_type;
    rand bit[DATA_WID_LV1-1:0] data;
    rand bit [ADDR_WID_LV1-1:0] address;
    rand access_cache_t access_cache_type;



//Constraints on class properties which will be randomized
//Constraint 1: Set default access to I-cache.
    constraint ct_cache_type {
        access_cache_type == ICACHE_ACC; // TODO
    }

//Constraint 2: Set access_cache_type(either ICACHE_ACC or DCACHE_ACC) based on address bits.
//Read through HAS to figure out which addresses are meant for dcache access and icache access.
    constraint c_address_type {
        address<32'h4000_0000 -> access_cache_type==ICACHE_ACC;
        address>32'h4000_0000 -> access_cache_type==DCACHE_ACC;
    } 

 
//Constraint 3: Soft constraint for expected data in case of a read type
//This information is there in the README.md 
    constraint ct_exp_data{
        soft (address[3]==1 & request_type==READ_REQ) -> data==32'h5555_aaaa;
        soft (address[3]!=0 & request_type==READ_REQ) -> data==32'haaaa_5555;
    }

//Constructor
    function new ();
        $display("new object of class cpu_transaction_c is created");
    endfunction : new


//Declare the task read: task should get the values of address, data from the transaction class properties.  
//Use virtual interface

  task automatic read(virtual interface cpu_lv1_interface vif);
  
	//Task body:: We already wrote read task using virtual interface in Lab1, reuse that code with changes as required
        reg timeout, got;
        timeout = 1'b0;
        got = 1'b0;
        @(posedge vif.clk);
        vif.cpu_rd <= 1'b1;
        vif.addr_bus_cpu_lv1 <= this.address;

        fork: timeout_check_0
            begin
                @(posedge vif.data_in_bus_cpu_lv1)
                //disable timeout check
                got = 1'b1;
            end
            begin
                repeat(`READ_TIMEOUT) begin
                    @(posedge vif.clk);
                    if(got == 1) break;
                end
                if(got == 1) begin
                    if(vif.data_bus_cpu_lv1 !== data) begin
                        $error("TBCHK: at time %t CPU0 read to addr %h data is %h : expected %h ",$time(),address,vif.data_bus_cpu_lv1,data);
                    end
                end
                if(got == 0) begin
                    timeout = 1;
                    $error("TBCHK: timeout of cpu read request");
                end
            end
        join_any

        @(posedge vif.clk);
        vif.cpu_rd <= 1'b0;
        vif.data_bus_cpu_lv1_reg <= 32'hz;
        vif.addr_bus_cpu_lv1 <= 32'hz;


  endtask

endclass : cpu_transaction_c

