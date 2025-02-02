class axi_bfm;

	axi_tx tx;
	virtual axi_interface mvif;
	axi_tx wr_tx[int];
	int data_size_in_bytes;
	int each_beat_active_bytes;
	int offset_addr;
	int aligned_addr;
	int wstrb_bit;
	int a[int] ;
	int b;

	task run();
		mvif = common::vif;
		forever begin
			@(posedge mvif.aclk);

			common::gen2bfm.get(tx);
			
		//write then read combination
		if(tx.wr_rd == WRITE_THEN_READ)begin
			write_address_channel();
			write_data_channel();
			write_response_channel();
			read_address_channel();
			read_data_channel();
		end

		//write and read parallel combination
		if(tx.wr_rd==WRITE_PARALLEL_READ)begin
		fork
			begin
				write_address_channel();
				write_data_channel();
				write_response_channel();
			end
			begin
				read_address_channel();
				read_data_channel();
			end
		join
		end

		//read only channel
		if(tx.wr_rd == READ_ONLY)begin
			read_address_channel();
			read_data_channel();
		end


		//write only channel
		if(tx.wr_rd == WRITE_ONLY)begin
			write_address_channel();
			write_data_channel();
			write_response_channel();
		end
		end

	endtask


	//write_address_channel
	task write_address_channel();
		mvif.awaddr <= tx.awaddr;
		mvif.awid <= tx.awid;
		mvif.awlen <= tx.awlen;
		mvif.awcache <= tx.awcache;
		mvif.awprot <= tx.awprot;
		mvif.awlock <= tx.awlock;
		mvif.awsize <= tx.awsize;
		mvif.awburst <= tx.awburst;
		mvif.awvalid <= 1;
		wait(mvif.awready==1);

		//storing the current address channel data
		wr_tx[mvif.awid] = new();
		wr_tx[mvif.awid].awaddr = mvif.awaddr;
		wr_tx[mvif.awid].awid = mvif.awid;
		wr_tx[mvif.awid].awlen = mvif.awlen;
		wr_tx[mvif.awid].awcache = mvif.awcache;
		wr_tx[mvif.awid].awprot = mvif.awprot;
		wr_tx[mvif.awid].awlock = mvif.awlock;
		wr_tx[mvif.awid].awsize = mvif.awsize;
		wr_tx[mvif.awid].awburst = mvif.awburst;
		
		

		//wait one clock cycle and then make the valid=0
		@(posedge mvif.aclk);
		mvif.awvalid<=0;
	endtask

	//write data channel
	task write_data_channel();
		write_address_channel();
		mvif.bready<=1;


		//generating the multiple transafers
		for(int i=0; i<=wr_tx[tx.wid].awlen; i++)begin
			mvif.wdata <= tx.wdata.pop_back();//32bit random data
			mvif.wid <= tx.wid;//0
			mvif.wvalid <= 1;
			if(i==wr_tx[tx.wid].awlen)
				mvif.wlast <=1;//last transfer the wlast will be asserted
			
			/*strobe:-each need to generate the wstrobe to indicate which bytes are active in the above data sent
			//wdata_size in bytes 
			2. many bytes are active in each beat by 2** awsize
			3.unaligned to aligned start address of aligned address
			4.find the start address of in the first beat
			5.finding the next start address of the of the second address 
			*/

			data_size_in_bytes = ($size(mvif.wdata)/8);//4
			each_beat_active_bytes = (2**wr_tx[tx.wid].awsize);//4
			//offset is used for narrow transfer
			offset_addr = wr_tx[tx.wid].awaddr % data_size_in_bytes;//2%4 = 2
			aligned_addr = wr_tx[tx.wid].awaddr - (wr_tx[tx.wid].awaddr % (2 ** wr_tx[tx.wid].awsize));// 2-(2%4)=0

			tx.wstrb =0;
			//check for aligned address
			if(wr_tx[tx.wid].awaddr % each_beat_active_bytes ==0)begin
				for(int j=0; j<each_beat_active_bytes; j++)begin
					wstrb_bit = (offset_addr+j) % data_size_in_bytes;
					tx.wstrb[wstrb_bit] = 1'b1;
				end
			end 
			//check for unaligned
			if(wr_tx[tx.wid].awaddr % each_beat_active_bytes !=0)begin
				for(int j=offset_addr; j<(aligned_addr+each_beat_active_bytes); j++)begin
					tx.wstrb[j] = 'b1;
				end
			end
			mvif.wstrb <= tx.wstrb;

			/* 1.convert unaligned to aligned address
				2.
			*/
			wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr -(wr_tx[tx.wid].awaddr %  (2**wr_tx[tx.wid].awsize));

			wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr + 2** wr_tx[tx.wid].awsize;
			wait(mvif.wready==1);
			@(posedge mvif.aclk);
			mvif.wlast<=0;
			mvif.wvalid<=0;
		end
	endtask

	//write response channel
	task write_response_channel();
		wait(mvif.bvalid==1);
	endtask

	//read address channel
	task read_address_channel();
		mvif.araddr <= tx.araddr;
		mvif.arid <= tx.arid;
		mvif.arlen <= tx.arlen;
		mvif.arcache <= tx.arcache;
		mvif.arprot <= tx.arprot;
		mvif.arlock <= tx.arlock;
		mvif.arsize <= tx.arsize;
		mvif.arburst <= tx.arburst;
		mvif.arvalid <= 1;

		wait(mvif.arready==1);
		@(posedge mvif.aclk);
		mvif.arvalid<=0;

		a[tx.arid] = tx.arlen;
	endtask

	//read data channel
	task read_data_channel();
	a.first(b);

	for(int i=0; i<=a[b]; i++)begin
		mvif.rready<=1;
		wait(mvif.rvalid==1);
		@(posedge mvif.aclk);
		mvif.rready<=0;
	end
	a.delete(b);

	endtask
endclass
