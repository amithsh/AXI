    class axi_scoreboard;

        axi_tx tx;
        axi_tx wr_tx[int];
        axi_tx rd_tx[int];
        int temp_wdata;
        int w_count;
        int r_count;
        reg[3:0]temp_id;
        int temp_start_addr;
        virtual axi_interface vif; 

        reg [7:0] expected_data[1000];
        reg [7:0] actual_data[1000];

        int data_size_in_bytes;
        int each_beat_active_bytes;
        int offset_addr;
        int aligned_addr;

        task run();
        vif = common::vif;
            forever begin
                common::mon2sco.get(tx);
                //write address channel
                
                if(vif.awvalid==1 && vif.awready==1)begin
                    wr_tx[tx.awid] = new();
                    wr_tx[tx.awid].awaddr = tx.awaddr;
                    wr_tx[tx.awid].awsize = tx.awsize;
                    wr_tx[tx.awid].awburst = tx.awburst;
                    //temp_start_addr = wr_tx[tx.awid].awaddr;
                end

                //write data channel
                
                if(vif.wvalid==1 && vif.wready==1)begin
                    
                    //$display("write data address=%0h",wr_tx[tx.awid].awaddr);
                    w_count = 0;
                    temp_wdata = tx.wdata.pop_back();
                        //$display("inside for loop");
                        
                    for(int i=0; i<$size(tx.rdata)/8; i++)begin
                        if(tx.wstrb[i]==1)begin
                            expected_data[ wr_tx[tx.wid].awaddr+w_count] = temp_wdata[i*8 +: 8];
                            $display("expected data=%0h address=%0d",expected_data[wr_tx[tx.wid].awaddr+w_count],wr_tx[tx.wid].awaddr+w_count);
                            w_count = w_count +1;
                        end
                    end
                    wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr - (wr_tx[tx.wid].awaddr %  2**wr_tx[tx.wid].awsize);

                    wr_tx[tx.wid].awaddr = wr_tx[tx.wid].awaddr + 2** wr_tx[tx.wid].awsize;
                    //$display("next transfer start address=%0d",wr_tx[tx.wid].awaddr);


                end


                //read address
                if(vif.arvalid==1 && vif.arready==1)begin

                    rd_tx[tx.arid] = new();
                    rd_tx[tx.arid].araddr = tx.araddr;
                    rd_tx[tx.arid].arsize = tx.arsize;
                    rd_tx[tx.arid].arburst = tx.arburst;

                end

                if(vif.rvalid ==1 && vif.rready==1)begin
                    
                    rd_tx.first(temp_id);
                    if(rd_tx[temp_id].arburst ==1) begin

                        r_count = 0;
                        //unaligned address to aligned address
                        
                        data_size_in_bytes  = $size(tx.rdata)/8;
                        each_beat_active_bytes = 2**rd_tx[temp_id].arsize;
                        offset_addr = rd_tx[temp_id].araddr % data_size_in_bytes;
                        aligned_addr = rd_tx[temp_id].araddr - (rd_tx[temp_id].araddr %(2** rd_tx[temp_id].arsize));

                        //aligned
                        if((rd_tx[temp_id].araddr % data_size_in_bytes) ==0)begin
                            for(int j=0; j<each_beat_active_bytes; j++)begin
                                //svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                                actual_data[rd_tx[temp_id].araddr+r_count] <= tx.rdata[rd_tx[temp_id].araddr +r_count];
                                r_count = r_count+1;
                                //$display("aligned read data= %0h | read address=%0d | time=%0t",   mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);

                                if(expected_data[rd_tx[temp_id].araddr+r_count] == actual_data[rd_tx[temp_id].araddr+r_count])begin
                                    $display("SCOREBOARD PASS");
                                end
                            end
                        end


                        //unaligned
                        if((rd_tx[temp_id].araddr % data_size_in_bytes) !=0)begin
                            for(int j=offset_addr; j<(each_beat_active_bytes + offset_addr); j++)begin
                                //svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                                actual_data[rd_tx[temp_id].araddr+r_count] <= tx.rdata[rd_tx[temp_id].araddr +r_count];
                                r_count = r_count+1;
                               // $display("unaligned read data= %0h | read address=%0d | time=%0t",  mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                                if(expected_data[rd_tx[temp_id].araddr+r_count] == actual_data[rd_tx[temp_id].araddr+r_count])begin
                                    $display("SCOREBOARD PASS");
                                end
                            end
                        end


                    
                        rd_tx[temp_id].araddr = aligned_addr + 2** rd_tx[temp_id].arsize;


                    end
                end

            end

            
        endtask

    endclass