class common;
	static mailbox gen2bfm=new();
	static mailbox mon2sco = new();
	static virtual axi_interface vif;
	static string testname;
	static int out_of_order = 0;
	static int overlaping = 0;
endclass

