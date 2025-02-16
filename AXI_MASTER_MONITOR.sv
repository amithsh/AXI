class axi_monitor;
	virtual axi_interface vif;

	axi_tx tx;
	task run();
		vif = common::vif;
		tx=new();

		forever begin
			//$display("awaddr = %0h",vif.awaddr);
			@(negedge vif.aclk);
			//monitoring all valid write address signals to tx
			if(vif.awvalid==1 && vif.awready==1)begin
				tx.awaddr = vif.awaddr;
				tx.awid = vif.awid;
				tx.awlen = vif.awlen;
				tx.awvalid = vif.awvalid;
				tx.awsize = vif.awsize;
				tx.awburst = vif.awburst;
				tx.awcache = vif.awcache;
				tx.awprot = vif.awprot;
				tx.awlock = vif.awlock;
				tx.awready = vif.awready;
				common::mon2sco.put(tx);
				//$display("write address put time=%0t",$time());
			end
			
			//monitor all valid write data channel signals to tx
			if(vif.wvalid==1 && vif.wready==1)begin

				tx.awvalid = vif.awvalid;
				tx.awready = vif.awready;

				tx.wdata.push_back(vif.wdata);
				tx.wid = vif.wid;
				tx.wstrb = vif.wstrb;
				tx.wlast = vif.wlast;
				tx.wvalid = vif.wvalid;
				tx.wready = vif.wready;
				
				common::mon2sco.put(tx);
				//$display("write data put time=%0t",$time());

			end
			//monitor all valid write response signals to tx
			// if(vif.bvalid==1 && vif.bready==1)begin
			// 	tx.bvalid = vif.bvalid;
			// 	tx.bresp = vif.bvalid;
			// 	tx.bready = vif.bready;
			// 	tx.bid = vif.bid;
			// 	common::mon2sco.put(tx);
			// 	$display("read address put time=%0t",$time());
			// end
			//monitor all valid read address channel signals to tx
			if(vif.arvalid==1 && vif.arready==1)begin

				tx.wvalid = vif.wvalid;
				tx.wready = vif.wready;

				tx.araddr = vif.araddr;
				tx.arid = vif.arid;
				tx.arlen = vif.arlen;
				tx.arvalid = vif.arvalid;
				tx.arsize = vif.arsize;
				tx.arburst = vif.arburst;
				tx.arcache = vif.arcache;
				tx.arprot = vif.arprot;
				tx.arlock = vif.arlock;
				tx.arready = vif.arready;
				common::mon2sco.put(tx);
				//$display("read address put time=%0t arvalid=%0d arready=%0d",$time(),vif.arvalid,vif.arready);
			end

			//monitor all the valid read data channel signals to tx
			if(vif.rvalid==1 && vif.rready==1)begin
				
				tx.arvalid = vif.arvalid;
				tx.arready = vif.arready;
				tx.rvalid  = vif.rvalid;
				
				tx.rdata = vif.rdata;
				tx.rresp = vif.rresp;
				tx.rid = vif.rid;
				tx.rready = vif.rready;
				tx.rlast = vif.rlast;
				common::mon2sco.put(tx);
				//$display("read data put time=%0t rdata=%0h",$time(),vif.rdata);
			end
		end

	endtask

endclass
