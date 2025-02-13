
typedef enum{WRITE_ONLY,
			READ_ONLY,
			WRITE_THEN_READ,
			WRITE_PARALLEL_READ
			} write_read;
class axi_tx;
	
	//declaration of write_read enum
	rand write_read wr_rd;

	//write adress channel
	rand bit[31:0] awaddr;
	rand bit[3:0] awid;
	rand bit[3:0] awlen;
	rand bit awvalid;
	rand bit[2:0] awsize;
	rand bit[1:0] awburst;
	rand bit[3:0] awcache;
	rand bit[2:0] awprot;
	rand bit[1:0] awlock;
	bit awready;

	//write data channell
	rand bit[31:0] wdata[$];
	rand bit [3:0] wstrb;
	rand bit wlast;
	rand bit[3:0] wid;
	rand bit wvalid;
	bit wready;
	//write response channel
	rand bit bready;
	bit bvalid;
	bit[3:0]bid;
	bit[1:0]bresp;
	//read address channel
	rand bit[31:0] araddr;
	rand bit[3:0] arid;
	rand bit[3:0] arlen;
	rand bit arvalid;
	rand bit[2:0] arsize;
	rand bit[1:0] arburst;
	rand bit[3:0] arcache;
	rand bit[2:0] arprot;
	rand bit[1:0] arlock;
	bit arready;

	//read data channel
	rand bit rready;
	bit rvalid;
	bit [31:0]rdata;
	bit [3:0]rid;
	bit rlast;
	bit [1:0]rresp;

	constraint c1{
		
			wdata.size() == awlen+1;
		}

endclass
