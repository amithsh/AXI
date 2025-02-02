interface axi_interface(input bit aclk,aresetn);

	//write adress channel
	logic[31:0] awaddr;
	logic[3:0] awid;
	logic[3:0] awlen;
	logic awvalid;
	logic[2:0] awsize;
	logic[1:0] awburst;
	logic[3:0] awcache;
	logic[2:0] awprot;
	logic[1:0] awlock;
	logic awready;

	//write data channell
	logic[31:0] wdata;
	logic[3:0] wstrb;
	logic wlast;
	logic[3:0] wid;
	logic wvalid;
	logic wready;


	//write response channel
	logic bready;
	logic bvalid;
	logic[3:0]bid;
	logic[1:0]bresp;


	//read address channel
	logic[31:0] araddr;
	logic[3:0] arid;
	logic[3:0] arlen;
	logic arvalid;
	logic[2:0] arsize;
	logic[1:0] arburst;
	logic[3:0] arcache;
	logic[2:0] arprot;
	logic[1:0] arlock;
	logic arready;

	//read data channel
	logic rready;
	logic rvalid;
	logic [31:0]rdata;
	logic [3:0]rid;
	logic rlast;
	logic [1:0]rresp;

	

endinterface
