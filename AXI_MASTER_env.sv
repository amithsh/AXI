class axi_env;

	axi_gen gen;
	axi_bfm bfm;
	axi_slave_bfm slv;
	task run();
		fork
			gen=new();
			bfm=new();
			slv=new();
			gen.run();
			bfm.run();
			slv.run();
		join

	endtask
endclass

