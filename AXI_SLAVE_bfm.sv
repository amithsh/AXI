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
int data_size_in_bytes;
int each_beat_active_bytes;
int offset_addr;
int aligned_addr;


//wrap related internal variables
int j;
int wrap_boundry_addr;
int upper_boundry_addr;

//fixed transaction related internal variables
int wr_ptr=0;
int rd_ptr=0;

//increment related interbal variables
axi_tx rd_tx[int];//for storing read address & control information
axi_tx wr_tx[int];//assosiative array,of type transaction class stores mainly on the ID incomming
int rd_j;
int rd_wrap_boundry_addr;
int rd_upper_boundry_addr;

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
            
            //increment transaction
            if(wr_tx[svif.wid].awburst ==1)begin
                @(posedge svif.aclk);
                for(int i=0; i<=wr_tx[svif.wid].awlen; i++)begin
                    w_count=0;
                    for(int i=0; i<data_in_bytes; i++)begin
                        if(svif.wstrb[i]==1)begin
                            //reversed_index = (data_in_bytes - 1 - j) * 8;
    				        mem[wr_tx[svif.wid].awaddr+w_count] = svif.wdata[i*8 +: 8];
                           //$display("data in mem %0h | data address=%0d | time=%0t",  mem[wr_tx[svif.wid].awaddr+w_count],  wr_tx[svif.wid].awaddr+w_count,  $time);
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

            //wrap transaction
            if(wr_tx[svif.wid].awburst==2)begin

                
                
                //1.check for aligned and unaligned address
                if(wr_tx[svif.wid].awaddr % 2** wr_tx[svif.wid].awsize == 0)begin
                    //2.find out the number of transfers (only 2 ,4 ,8, 16 are allowed)
                    if(wr_tx[svif.wid].awlen==1 || wr_tx[svif.wid].awlen==3 || wr_tx[svif.wid].awlen==7 || wr_tx[svif.wid].awlen==15 ) begin
                        //3.find out the wrap boundry
                        j = wr_tx[svif.wid].awaddr / ((wr_tx[svif.wid].awlen+1) * (2 ** wr_tx[svif.wid].awsize));
                        //$display("j=%0d",j);
                        wrap_boundry_addr = j * (wr_tx[svif.wid].awlen+1 * (2 ** wr_tx[svif.wid].awsize));
                        //4.find out the upper boundry
                        upper_boundry_addr = wrap_boundry_addr + ((wr_tx[svif.wid].awlen+1) * (2 ** wr_tx[svif.wid].awsize));
                        //$display("wrap_boundry addr = %0d || upper_boundry_addr = %0d",wrap_boundry_addr,upper_boundry_addr);
                        @(posedge svif.aclk);
                        
                        for(int i=0; i<=wr_tx[svif.wid].awlen; i++)begin
                            //$display("slave bfm WRAP TRANSACTION numbber_transfer=%d start_Addr=%d wdata=%h time=%t",i,wr_tx[svif.wid].awaddr,svif.wdata,$time);
                            w_count=0;
                            for(int j=0; j<data_in_bytes; j++)begin
                                if(svif.wstrb[i]==1)begin
                                    mem[wr_tx[svif.wid].awaddr+w_count] = svif.wdata[j*8 +: 8];
                                    //$display("mem_addr = %0d | svif.wdata = %0h| w_count=%0d",wr_tx[svif.wid].awaddr+w_count,mem[wr_tx[svif.wid].awaddr+w_count],w_count);
                                    w_count = w_count+1;
                                end
                            end

                        wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr - (wr_tx[svif.wid].awaddr % 2 ** wr_tx[svif.wid].awsize );

                        wr_tx[svif.wid].awaddr = wr_tx[svif.wid].awaddr + 2**wr_tx[svif.wid].awsize;


                        if(wr_tx[svif.wid].awaddr == upper_boundry_addr )begin
                            wr_tx[svif.wid].awaddr = wrap_boundry_addr;

                        end

                        @(posedge svif.aclk);

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

                    if(svif.bready==1)begin
                        if(svif.wlast==1)begin
                            svif.bvalid<=1;
                            svif.bid<=svif.wid;
                            svif.bresp<=0;
                        end
                    end
                end   
                end
                else begin
                     if(svif.wlast==1)begin
                            svif.bvalid<=1;
                            svif.bid<=svif.wid;
                            svif.bresp<='b10;
                        end
                end
                
                end
                else begin
                     if(svif.wlast==1)begin
                            svif.bvalid<=1;
                            svif.bid<=svif.wid;
                            svif.bresp<='b10;
                        end
                end
            end


            //fixed transaction
            if(wr_tx[svif.wid].awburst == 0)begin
                @(posedge svif.aclk);

                for(int i=0; i<=wr_tx[svif.wid].awlen; i++)begin
                    w_count=0;
                    for(int j=0; j<data_in_bytes; j++)begin
                        mem[wr_ptr + w_count] = svif.wdata[j*8 +: 8];
                        //$display("fixed write data in mem=%0h",mem[wr_ptr + w_count]);
                        w_count = w_count+1;
                    end

                     wr_ptr = wr_ptr + data_in_bytes;
                    //$display("entering the response channel");
                    @(posedge svif.aclk);

                if(svif.awvalid ==1 )begin
                    svif.awready<=1;
                    wr_tx[svif.awid]=new();
                    wr_tx[svif.awid].awaddr =svif.awaddr;
                    wr_tx[svif.awid].awlen =svif.awlen;
                    wr_tx[svif.awid].awsize = svif.awsize;
                    wr_tx[svif.awid].awburst = svif.awburst;
                    wr_tx[svif.awid].awcache = svif.awcache;
                    wr_tx[svif.awid].awid = svif.awid;
                    wr_tx[svif.awid].awprot = svif.awprot;
                    wr_tx[svif.awid].awlock = svif.awlock;
                end

                if(svif.bready==1)begin
                    if(svif.wlast==1)begin
                        svif.bvalid<=1;
                        svif.bid<=svif.wid;
                        svif.bresp<='b00;
                    end
                end
                end

            end
        end//end of wvalid loop




        //read address channel
        if(svif.arvalid ==1)begin
            svif.arready =1;
            rd_tx[svif.arid] = new();
            rd_tx[svif.arid].araddr = svif.araddr;
            rd_tx[svif.arid].arlen = svif.arlen;
            rd_tx[svif.arid].arsize = svif.arsize;
            rd_tx[svif.arid].arburst = svif.arburst;
            rd_tx[svif.arid].arprot = svif.arprot;
            rd_tx[svif.arid].arcache = svif.arcache;
            rd_tx[svif.arid].arlock = svif.arlock;
            rd_tx[svif.arid].arid = svif.arid;
            //$display("rid=%0d arburst=%0d",svif.arid, rd_tx[svif.arid].arburst);
        end

        //read data channel from slave
        if(svif.rready==1)begin
            svif.rvalid =1;
            rd_tx.first(temp_id);
            //$display("temp_id=%0d time=%0t ",temp_id,$time());
            //$display("arburst=%0d time=%0t",rd_tx[temp_id].arburst,$time());
            
            
            

            


            //increment read transaction
            if(rd_tx[temp_id].arburst==1)begin //burst==1 indicates the transfer is the increment type
                
                for(int i=0; i<=rd_tx[temp_id].arlen; i++)begin
                   r_count = 0;
                    //unaligned address to aligned address
                    
                     data_size_in_bytes  = $size(svif.rdata)/8;
                    each_beat_active_bytes = 2**rd_tx[temp_id].arsize;
                    offset_addr = rd_tx[temp_id].araddr % data_size_in_bytes;
                    aligned_addr = rd_tx[temp_id].araddr - (rd_tx[temp_id].araddr %(2** rd_tx[temp_id].arsize));
                   

                    svif.rdata = 0; 

                    //aligned
                    if((rd_tx[temp_id].araddr % data_size_in_bytes) ==0)begin
                        for(int j=0; j<each_beat_active_bytes; j++)begin
                            svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                            
                            r_count = r_count+1;
                           // $display("aligned read data= %0h | read address=%0d | time=%0t",   mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                        end
                    end


                    //unaligned
                    if((rd_tx[temp_id].araddr % data_size_in_bytes) !=0)begin
                        for(int j=offset_addr; j<(each_beat_active_bytes + offset_addr); j++)begin
                            svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                            r_count = r_count+1;
                            //$display("unaligned read data= %0h | read address=%0d | time=%0t",  mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                        end
                    end


                   
                    rd_tx[temp_id].araddr = aligned_addr + 2** rd_tx[temp_id].arsize;
                    svif.rid = temp_id;
                    svif.rresp = 'b00;
                    if(i==rd_tx[temp_id].arlen)
                        svif.rlast<=1;
                    @(posedge svif.aclk);
                    //read address channel
                    if(svif.arvalid==1)begin
                        svif.arready=1;
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
                    svif.rlast<=0;
                end
                rd_tx.delete(temp_id);
            end

            //wrap transaction of read
            if(rd_tx[temp_id].arburst==2)begin
                //$display("araddr=%0d  arsize=%0d",rd_tx[temp_id].araddr,rd_tx[temp_id].arsize);
                //1.check for aligned and unaligned address
                if(rd_tx[temp_id].araddr % (2** rd_tx[temp_id].arsize) == 0)begin
                    //2.find out the number of transfers (only 2 ,4 ,8, 16 are allowed)
                    if(rd_tx[temp_id].arlen==1 || rd_tx[temp_id].arlen==3 || rd_tx[temp_id].arlen==7 || rd_tx[temp_id].arlen==15 ) begin
                        //3.find out the wrap boundry
                        rd_j = rd_tx[temp_id].araddr / ((rd_tx[temp_id].arlen+1) * (2 ** rd_tx[temp_id].arsize));
                        //$display("j=%0d",j);
                        rd_wrap_boundry_addr = rd_j * ((rd_tx[temp_id].arlen+1) * (2 ** rd_tx[temp_id].arsize));
                        //4.find out the upper boundry
                        rd_upper_boundry_addr = rd_wrap_boundry_addr + ((rd_tx[temp_id].arlen+1) * (2 ** rd_tx[temp_id].arsize));
                        //$display("wrap_boundry addr = %0d || upper_boundry_addr = %0d",rd_wrap_boundry_addr,rd_upper_boundry_addr);
                        @(posedge svif.aclk);
                        
                    for(int i=0; i<=rd_tx[temp_id].arlen; i++)begin
                   
                    r_count = 0;
                    //unaligned address to aligned address
                    
                    data_size_in_bytes  = $size(svif.rdata)/8;
                    each_beat_active_bytes = 2**rd_tx[temp_id].arsize;
                    offset_addr = rd_tx[temp_id].araddr % data_size_in_bytes;
                    aligned_addr = rd_tx[temp_id].araddr - (rd_tx[temp_id].araddr %(2** rd_tx[temp_id].arsize));
                   

                    svif.rdata = 0; 

                    //aligned
                    if((rd_tx[temp_id].araddr % data_size_in_bytes) ==0)begin
                        for(int j=0; j<each_beat_active_bytes; j++)begin
                            svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                            
                            r_count = r_count+1;
                            //$display("aligned read data= %0h | read address=%0d | time=%0t",   mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                        end
                    end


                    //unaligned
                    if((rd_tx[temp_id].araddr % data_size_in_bytes) !=0)begin
                        for(int j=offset_addr; j<(each_beat_active_bytes + offset_addr); j++)begin
                            svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                            r_count = r_count+1;
                            //$display("unaligned read data= %0h | read address=%0d | time=%0t",  mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                        end
                    end
                     //$display("slave bfm WRAP TRANSACTION numbber_transfer=%d start_Addr=%d wdata=%h time=%t",i,rd_tx[temp_id].araddr,svif.rdata,$time);


                   
                    rd_tx[temp_id].araddr = aligned_addr + 2** rd_tx[temp_id].arsize;
                    if(rd_tx[temp_id].araddr == rd_upper_boundry_addr)begin
                        rd_tx[temp_id].araddr = rd_wrap_boundry_addr;
                    end
                    svif.rid = temp_id;
                    svif.rresp = 'b00;
                    if(i==rd_tx[temp_id].arlen)
                        svif.rlast<=1;
                    @(posedge svif.aclk);
                    //read address channel
                    if(svif.arvalid==1)begin
                        svif.arready=1;
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
                    svif.rlast<=0;
                end
                end
                else begin
                     if(svif.wlast==1)begin
                            svif.bvalid<=1;
                            svif.bid<=svif.wid;
                            svif.bresp<='b10;
                        end
                end
                
                end
                else begin
                     if(svif.wlast==1)begin
                            svif.bvalid<=1;
                            svif.bid<=svif.wid;
                            svif.bresp<='b10;
                        end
                end
                rd_tx.delete(temp_id);
            end

            //fixed read transaction
            if(rd_tx[temp_id].arburst==0)begin
	      //number of transfers of rdata slave need to send 
	      for(int i=0; i<=rd_tx[temp_id].arlen; i++)begin 
                 	//slave need to send rdata from memory
			data_size_in_bytes= $size(svif.rdata) /8;
			//$display("data size in bytes=%h read", data_size_in_bytes);
			r_count=0;
		       for(int i=0; i< data_size_in_bytes; i++)begin//wstrb=4'b1100 awsize=2 wdata size 32
			     svif.rdata[i*8 +:8]=mem[rd_ptr+r_count];
                 //$display("fixed read data in mem=%0h",mem[rd_ptr+r_count]);
		             r_count=r_count+1;  //count=1	  count=2	   
		             end  
			                        
	                  		       //next beat start address 
		       rd_ptr= rd_ptr + data_size_in_bytes;//2
			       
			 		  svif.rid<=temp_id;
		  svif.rresp<=2'b00;//ok response 

		  if(i==rd_tx[temp_id].arlen)//last transfer only this conditon will true 
			  svif.rlast<=1;

		  @(posedge svif.aclk);
		  //read address channel 
		  if(svif.arvalid==1)begin  //address check missed in 4th and 5th clock
				    svif.arready<=1;//am ready to recive the addresss & control inf                   
				    rd_tx[svif.arid]=new();//wr_tx[5]=new();  wr_tx[10]=new() wr_tx[7]
				    rd_tx[svif.arid].araddr= svif.araddr;//wr_tx[5].awaddr=4 
				    rd_tx[svif.arid].arlen= svif.arlen;//wr_tx[5].awlen=1
				    rd_tx[svif.arid].arsize= svif.arsize;
				    rd_tx[svif.arid].arburst= svif.arburst;
				    rd_tx[svif.arid].arcache= svif.arcache;
				    rd_tx[svif.arid].arprot= svif.arprot;
				    rd_tx[svif.arid].arlock= svif.arlock;
				    rd_tx[svif.arid].arid= svif.arid;

	                          //rd_tx[5]
				  //rd_tx[7]
				  //rd_tx[2]			    
			         end


	      end //for 
            rd_tx.delete(temp_id);
      end//arburst 
            
            //rd_tx.delete(temp_id);
        end
    end
end
endtask
endclass
