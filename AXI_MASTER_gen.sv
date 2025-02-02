class axi_gen;
	axi_tx tx;

	task run();
		$display("testname=%0s",common::testname);
		case(common::testname)
			"SINGLE_WRITE_TEST":begin
				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==4; awlen==3; awsize==2; awburst==1; wid==awid;};
				common::gen2bfm.put(tx);	
			end



		
			"MULTIPLE_WRITE_TEST":begin
				//1st transfer
				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==4; awlen==3; awsize==2; awburst==1;  wid==awid;};
				common::gen2bfm.put(tx);

				//2nd transfer
				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==2; awlen==2; awsize==1; awburst==1;  wid==awid;};
				common::gen2bfm.put(tx);

			end

			"SINGLE_WRITE_READ_TEST":begin
				//write transaction
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==2; awlen==3; awsize==2; awburst==1; wid==awid; araddr==2; arlen==3; arsize==2; arburst==1; };
	            common::gen2bfm.put(tx);

			end

			"MULTIPLE_WRITE_READ_TEST":begin
				//aligned address and non-narrow transfer
				// tx=new();
	            // tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==0; awlen==3; awsize==2; awburst==1; wid==awid; araddr==0; arlen==3; arsize==2; arburst==1; };
	            // common::gen2bfm.put(tx);


				//aligned and narrow transfer
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==1; awlen==3; awsize==1; awburst==1; wid==awid; araddr==0; arlen==3; arsize==1; arburst==1; };
	            common::gen2bfm.put(tx);

				//non-aligned and non-narrow transfer
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==2; awlen==3; awsize==2; awburst==1; wid==awid; araddr==2; arlen==3; arsize==2; arburst==1; };
	            common::gen2bfm.put(tx);
				
				//non-aligned and narrow transfer
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==3; awlen==3; awsize==1; awburst==1; wid==awid; araddr==2; arlen==3; arsize==1; arburst==1; };
	            common::gen2bfm.put(tx);	

			end

			"OVERLAPPING_TRANSACTION_TEST":begin
				
			end
		endcase
		endtask
endclass

		
