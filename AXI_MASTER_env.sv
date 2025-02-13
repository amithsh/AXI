class axi_env;

	axi_gen gen;
	axi_bfm bfm;
	axi_slave_bfm slv;
	axi_monitor mon;
	axi_scoreboard sco;
	task run();
		fork
			gen=new();
			bfm=new();
			slv=new();
			mon=new();
			sco=new();

			gen.run();
			bfm.run();
			slv.run();
			mon.run();
			sco.run();
		join

	endtask
endclass

