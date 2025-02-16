    class axi_scoreboard;

        axi_tx tx;
        axi_tx wr_tx[int];
        axi_tx rd_tx[int];
        int temp_wdata;
        int temp_rdata;
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

        //fixed transaction related variables
        int wr_ptr;
        int rd_ptr;


        task run();
        vif = common::vif;
            forever begin
                common::mon2sco.get(tx);
                //write address channel
                
                if(tx.awvalid==1 && tx.awready==1)begin
                    wr_tx[tx.awid] = new();
                    wr_tx[tx.awid].awaddr = tx.awaddr;
                    wr_tx[tx.awid].awsize = tx.awsize;
                    wr_tx[tx.awid].awburst = tx.awburst;
                    //temp_start_addr = wr_tx[tx.awid].awaddr;
                end

                //write data channel
                
                if(tx.wvalid==1 && tx.wready==1)begin
                    
                    w_count = 0;
                    temp_wdata = tx.wdata.pop_back();
                    //increment transaction
                    if(wr_tx[tx.wid].awburst==1)begin
                    //$display("write data address=%0h",wr_tx[tx.awid].awaddr);
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

                    //fixed transaction write
                    if(wr_tx[tx.wid].awburst==0)begin

                        //$display("intial wr_ptr=%0d",wr_ptr);
                        for(int i=0; i<$size(tx.rdata)/8; i++)begin
                            if(tx.wstrb[i]==1)begin
                                expected_data[wr_ptr + w_count] = temp_wdata[i*8 +: 8];
                                //$display("fixed expected data=%0h address=%0d",expected_data[wr_ptr + w_count],wr_ptr+w_count);
                                w_count = w_count+1;
                            end
                        end
                        wr_ptr = wr_ptr + $size(tx.rdata)/8;
                        //$display("after wr_ptr=%0d",wr_ptr);
                    end
                end


                //read address
                if(tx.arvalid==1 && tx.arready==1)begin
                    rd_tx[tx.arid] = new();
                    rd_tx[tx.arid].araddr = tx.araddr;
                    rd_tx[tx.arid].arsize = tx.arsize;
                    rd_tx[tx.arid].arburst = tx.arburst;
                    //$display("SCOREBOARD entering the read address and got the read address");
                    

                end

                if(tx.rvalid ==1 && tx.rready==1)begin
                    //$display("SCOREBOARD entering the read data and got the read data");
                    rd_tx.first(temp_id);
                    //$display("araddr=%0d", rd_tx[temp_id].araddr);
                    r_count = 0;
                    
                    if(rd_tx[temp_id].arburst ==1) begin

                        //unaligned address to aligned address
                        
                        aligned_addr = rd_tx[temp_id].araddr - (rd_tx[temp_id].araddr %(2** rd_tx[temp_id].arsize));
                        data_size_in_bytes  = $size(tx.rdata)/8;
                        each_beat_active_bytes = 2**rd_tx[temp_id].arsize;
                        offset_addr = rd_tx[temp_id].araddr % data_size_in_bytes;
                        //$display("rdata =%0h time=%0t",tx.rdata,$time() );

                        //aligned
                        if((rd_tx[temp_id].araddr % data_size_in_bytes) == 0)begin
                            
                            for(int j=0; j<each_beat_active_bytes; j++)begin
                                //svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                                $display("aligned addr=%0d",rd_tx[temp_id].araddr);
                                actual_data[rd_tx[temp_id].araddr+r_count] = tx.rdata[j*8 +:8];
                                //$display("aligned read data= %0h | read address=%0d | time=%0t",   mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                                $display("aligned expected data=%0h || address=%0d || actual_data=%0h time=%0t",expected_data[rd_tx[temp_id].araddr+r_count],rd_tx[temp_id].araddr+r_count, tx.rdata[j*8 +:8],$time());

                                if(expected_data[rd_tx[temp_id].araddr+r_count] == actual_data[rd_tx[temp_id].araddr+r_count])begin
                                    $display("SCOREBOARD PASS || time=%0d",$time());
                                end
                                else begin
                                    $display("SCOREBOARD FAIL || time=%0d",$time());
                                end
                                r_count = r_count+1;
                            end
                        end



                        
                        //unaligned
                        if((rd_tx[temp_id].araddr % data_size_in_bytes) !=0)begin
                            for(int j=offset_addr; j<(each_beat_active_bytes ); j++)begin
                                //svif.rdata[j*8 +: 8] <= mem[rd_tx[temp_id].araddr+r_count];
                               
                                actual_data[rd_tx[temp_id].araddr+r_count] <= tx.rdata[j*8 +:8];
                               // $display("unaligned read data= %0h | read address=%0d | time=%0t",  mem[rd_tx[temp_id].araddr+r_count],  rd_tx[temp_id].araddr+r_count,  $time);
                                $display("unaligned expected data=%0h || address=%0d || actual_data=%0h time=%0t",expected_data[rd_tx[temp_id].araddr+r_count],rd_tx[temp_id].araddr+r_count, tx.rdata[j*8 +:8],$time());
                                if(expected_data[rd_tx[temp_id].araddr+r_count] == actual_data[rd_tx[temp_id].araddr+r_count])begin
                                    $display("SCOREBOARD PASS|| time=%0d",$time());
                                end
                                else begin
                                    $display("SCOREBOARD FAIL|| time=%0d",$time());
                                end
                                r_count = r_count+1;
                            end
                        end


                    
                        rd_tx[temp_id].araddr = aligned_addr + 2** rd_tx[temp_id].arsize;
                    end

                    //fixed transaction
                    if(rd_tx[temp_id].arburst==0)begin

                        
                        for(int i=0; i<$size(tx.rdata)/8; i++)begin
                            if(tx.wstrb[i]==1)begin
                                actual_data[rd_ptr + r_count] = tx.rdata[i*8 +: 8];
                                //$display(" expected data = %0h  || address=%0d || actual data=%0h ",expected_data[rd_ptr + r_count],rd_ptr+r_count,actual_data[rd_ptr + r_count]);
                                if(expected_data[rd_ptr + r_count] == actual_data[rd_ptr + r_count])begin
                                    $display("SCOREBOARD PASS || expected data = %0h  || address=%0d || actual data=%0h",expected_data[rd_ptr + r_count],rd_ptr+r_count,actual_data[rd_ptr + r_count]);
                                end
                                else begin
                                    $display("SCOREBOARD FAIL || expected data = %0h  || address=%0d || actual data=%0h",expected_data[rd_ptr + r_count],rd_ptr+r_count,actual_data[rd_ptr + r_count]);
                                end
                                r_count = r_count+1;
                            end
                        end
                        rd_ptr = rd_ptr + $size(tx.rdata)/8;
                        
                    end
                end

            end

            
        endtask

    endclass