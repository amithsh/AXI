class axi_gen;
	axi_tx tx;

	task run();
		$display("testname=%0s",common::testname);
		case(common::testname)
			"SINGLE_WRITE_TEST":begin
				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==4; awlen==3; awsize==2; awburst==1; wid==awid;};
				common::gen2bfm.put(tx);	

				// tx=new();
				// tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==12; awlen==3; awsize==2; awburst==1; wid==awid;};
				// common::gen2bfm.put(tx);
			end



			"SINGLE_WRITE_READ_TEST":begin
				//write transaction
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==2; awlen==3; awsize==2; awburst==1; wid==awid; araddr==2; arlen==3; arsize==2; arburst==1; };
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


			"MULTIPLE_WRITE_READ_TEST":begin
				//aligned address and non-narrow transfer
				// tx=new();
	            // tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==0; awlen==3; awsize==2; awburst==1; wid==awid; araddr==0; arlen==3; arsize==2; arburst==1; };
	            // common::gen2bfm.put(tx);


				//aligned and narrow transfer
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==1; awlen==3; awsize==1; awburst==1; wid==awid; araddr==1; arlen==3; arsize==1; arburst==1; };
	            common::gen2bfm.put(tx);

				//non-aligned and non-narrow transfer
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==10; awlen==3; awsize==2; awburst==1; wid==awid; araddr==10; arlen==3; arsize==2; arburst==1; };
	            common::gen2bfm.put(tx);
				
				//non-aligned and narrow transfer
				tx=new();
	            tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==20; awlen==3; awsize==1; awburst==1; wid==awid; araddr==20; arlen==3; arsize==1; arburst==1; };
	            common::gen2bfm.put(tx);	

			end

			"SINGLE_READ_PARALLEL_WRITE":begin
				//aligned address with normal transfer

				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==0; awlen==3; awsize==2; awburst==1; wid==awid;};
				common::gen2bfm.put(tx);	

				//sending unaligned address with normal transfer
				tx=new();
				tx.randomize() with {wr_rd==WRITE_PARALLEL_READ; awaddr==10; awlen==3; awsize==2; awburst==1; wid==awid; araddr==0; arlen==3; arsize==2; arburst==1; };
				common::gen2bfm.put(tx);
			end

			//"MULTIPLE_PARALLEL_WRITE_READ"

			"OVERLAPPING_TRANSACTION_TEST":begin
				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==0; awlen==3; awsize==2; awburst==1; awid==3; awvalid==1; wvalid==0; };
				common::gen2bfm.put(tx);

				tx=new();
				tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==8; awlen==3; awsize==2; awburst==1; awid ==4; wid==3; awvalid==1; wvalid==1; };
				common::gen2bfm.put(tx);

				tx=new();
				tx.randomize() with {wr_rd==READ_ONLY; araddr==0; arlen==3; arsize==2; arburst==1; };
				common::gen2bfm.put(tx);
			end

			"wrap_transaction_with_aligned_addr":begin
				// tx=new();
				// tx.randomize() with {wr_rd==WRITE_ONLY; awaddr==4; awlen==3; awsize==2; awburst==2; wid==awid; };
				// common::gen2bfm.put(tx);

				tx=new();
				tx.randomize() with {wr_rd==WRITE_THEN_READ; awaddr==8; awlen==3; awsize==2; awburst==2; wid==awid; araddr==8; arlen==3; arsize==2; arburst==2;};
				common::gen2bfm.put(tx);
			end
		endcase
		endtask
endclass

		
