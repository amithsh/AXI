module top;
bit aclk,aresetn;

initial begin
	aclk=1;
	forever #5 aclk=~aclk;
end

initial begin
	aresetn = 1;
	repeat(2)@(posedge aclk);
	aresetn = 0;
end

axi_interface pvif(aclk,aresetn);

axi_env e;


initial begin
	e=new();
	common::vif=pvif;
	
	common::testname = "SINGLE_WRITE_READ_TEST";
	e.run();
end




initial begin
	#1000;
	//$display("p=%0d",pvif.aclk);
	$finish;
end
endmodule






