//features included:-out of order,overlaping transaction,increment transaction 
//also supports narrow transfer


class axi_slave_bfm;

//get the virtual interface
virtual axi_interface svif;

reg[7:0] mem[10000];
int temp_id;
int w_count;
int r_count;
int data_size;
int data_in_bytes;
int reversed_index;

axi_tx wr_tx[int];//assosiative array,of type transaction class stores mainly on the ID incomming
axi_tx rd_tx[int];//for storing read address & control information

task run();
svif = common::vif;
forever begin
    @(posedge svif.aclk)
    if(svif.aresetn==1)begin
            //write address channel
	    svif.awready <= 'bx;
	    
	    //write data channel
            svif.wready <= 'bx;
	    
	    //write response channel
            svif.bresp <= 'bx;
            svif.bvalid <= 'bx;
            svif.bid <= 'bx;
	    
	    //read address channel
            svif.arready <= 'bx;
	    
	    //read data channel
            svif.rvalid <= 'bx;
            svif.rresp <= 'bx;
            svif.rlast <= 'bx;
            svif.rdata <= 'bx;
            svif.rid <= 'bx;
            for(int i=0; i<10000; i++)begin
                mem[i] =0;
            end
    end



    else begin
        if(svif.awvalid==0)
                    svif.awready <=0;
        if(svif.wvalid==0)
                    svif.wready <=0;
        if(svif.bready==0)
                    svif.bvalid <=0;
        if(svif.arvalid==0)
                    svif.arready <=0;
        if(svif.rready==0)
                    svif.rvalid <=0;
        
        //write address channel codes and signals
        if(svif.awvalid ==1)begin
            svif.awready <=1;
            wr_tx[svif.awid] = new();
            wr_tx[svif.awid].awaddr = svif.awaddr;
            wr_tx[svif.awid].awlen = svif.awlen;
            wr_tx[svif.awid].awsize = svif.awsize;
            wr_tx[svif.awid].awburst = svif.awburst;
            wr_tx[svif.awid].awprot = svif.awprot;
            wr_tx[svif.awid].awcache = svif.awcache;
            wr_tx[svif.awid].awlock = svif.awlock;
            wr_tx[svif.awid].awid = svif.awid;
        end

        //write data channel
        if(svif.wvalid==1)begin
            svif.wready <=1;

            data_size = $size(svif.wdata);
            data_in_bytes = data_size/8;

            if(wr_tx[svif.wid].awburst ==1)begin
                @(posedge svif.aclk);
                for(int i=0; i<=wr_tx[svif.wid].awlen; i++)begin
                    w_count=0;
                    for(int i=0; i<data_in_bytes; i++)begin
                        if(svif.wstrb[i]==1)begin
                            //reversed_index = (data_in_bytes - 1 - j) * 8;
    				        mem[wr_tx[svif.wid].awaddr+w_count] = svif.wdata[i*8 +: 8];
                           // $display("data in mem %0h",mem[wr_tx[svif.wid].awaddr+w_count]);
                            w_count = w_count+1;
                        end
                    end
                    //unalined to alined conversion
                    wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr - (wr_tx[svif.wid].awaddr % 2**wr_tx[svif.wid].awsize);
                    //next transfer start address
                    wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr + 2**wr_tx[svif.wid].awsize;
                    @(posedge svif.aclk);

                    //for everlapping transaction we need to extract the data every clock cycle else it will stay in this for loop till the awlen ends 
                    if(svif.awvalid ==1)begin
                         svif.awready<=1;
                         wr_tx[svif.awid] = new();
                         wr_tx[svif.awid].awaddr = svif.awaddr;
                         wr_tx[svif.awid].awlen = svif.awlen;
                         wr_tx[svif.awid].awsize = svif.awsize;
                         wr_tx[svif.awid].awburst = svif.awburst;
                         wr_tx[svif.awid].awprot = svif.awprot;
                         wr_tx[svif.awid].awcache = svif.awcache;
                         wr_tx[svif.awid].awlock = svif.awlock;
                         wr_tx[svif.awid].awid = svif.awid;
                    end


        //write response channel
        if(svif.bready==1)begin
            if(svif.wlast==1)begin
                svif.bvalid<=1;
                svif.bid <= svif.wid;
                svif.bresp <= 'b00;
            end
        end

                end//end of awlen loop
            end// end of awburst loop
        end//end of wvalid loop




        //read address channel
        if(svif.arvalid ==1)begin
            svif.arready <=1;
            rd_tx[svif.arid] = new();
            rd_tx[svif.arid].araddr = svif.araddr;
            rd_tx[svif.arid].arlen = svif.arlen;
            rd_tx[svif.arid].arsize = svif.arsize;
            rd_tx[svif.arid].arburst = svif.arburst;
            rd_tx[svif.arid].arprot = svif.arprot;
            rd_tx[svif.arid].arcache = svif.arcache;
            rd_tx[svif.arid].arlock = svif.arlock;
            rd_tx[svif.arid].arid = svif.arid;
        end

        //read data channel from slave
        if(svif.rready==1)begin
            svif.rvalid <=1;
            rd_tx.first(temp_id);
            
            
            
            if(rd_tx[temp_id].arburst==1)begin //burst==1 indicates the transfer is the increment type
                
                for(int i=0; i<=rd_tx[temp_id].arlen; i++)begin
                   r_count = 0;
                    //unaligned address to aligned address
                    rd_tx[temp_id].araddr = rd_tx[temp_id].araddr - (rd_tx[temp_id].araddr % 2** rd_tx[temp_id].arsize);
                    
                    
                    svif.rdata <= 0; 
                    for(int i=0; i<(2** rd_tx[temp_id].arsize); i++)begin
                        svif.rdata[i*8 +: 8] = mem[rd_tx[temp_id].araddr+r_count];
                        r_count = r_count +1;
                    end
                    rd_tx[temp_id].araddr = rd_tx[temp_id].araddr + 2** rd_tx[temp_id].arsize;
                    svif.rid = temp_id;
                    svif.rresp = 'b00;
                    if(i==rd_tx[temp_id].arlen)
                        svif.rlast<=1;
                    @(posedge svif.aclk);
                    //read address channel
                    if(svif.arvalid==1)begin
                        svif.arready=1;
                        rd_tx[svif.arid] = new();
                        wr_tx[svif.arid].awaddr = svif.araddr;
                        wr_tx[svif.arid].awlen = svif.arlen;
                        wr_tx[svif.arid].awsize = svif.arsize;
                        wr_tx[svif.arid].awburst = svif.arburst;
                        wr_tx[svif.arid].awprot = svif.arprot;
                        wr_tx[svif.arid].awcache = svif.arcache;
                        wr_tx[svif.arid].awlock = svif.arlock;
                        wr_tx[svif.arid].awid = svif.arid;
                    end
                    svif.rlast<=0;
                end
            end
            rd_tx.delete(temp_id);
        end
    end
end
endtask
endclass
