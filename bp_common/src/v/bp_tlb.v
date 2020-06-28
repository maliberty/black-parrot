
module bp_tlb
  import bp_common_pkg::*;
  import bp_common_aviary_pkg::*;
 #(parameter bp_params_e bp_params_p = e_bp_inv_cfg
   `declare_bp_proc_params(bp_params_p)
   ,parameter tlb_els_p       = "inv"
   
   ,localparam lg_els_lp      = `BSG_SAFE_CLOG2(tlb_els_p)
   ,localparam entry_width_lp = `bp_pte_entry_leaf_width(paddr_width_p)
 )
 (input                               clk_i
  , input                             reset_i
  , input                             flush_i
  , input                             translation_en_i
  
  , input                             v_i
  , input                             w_i
  , input [vtag_width_p-1:0]          vtag_i
  , input [entry_width_lp-1:0]        entry_i
    
  , output logic                      v_o
  , output logic                      miss_v_o
  , output logic [entry_width_lp-1:0] entry_o
 );

`declare_bp_fe_be_if(vaddr_width_p, paddr_width_p, asid_width_p, branch_metadata_fwd_width_p);

logic r_v_r;
bsg_dff_reset #(.width_p(1))
  r_v_reg
  (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.data_i(v_i & ~w_i)
   ,.data_o(r_v_r)
  );

logic [vtag_width_p-1:0] vtag_r;
bsg_dff_reset #(.width_p(vtag_width_p))
  vtag_reg
  (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.data_i(vtag_i)
   ,.data_o(vtag_r)
  );
 
bp_pte_entry_leaf_s r_entry, passthrough_entry;
logic r_v_lo;
bsg_cam_1r1w_sync
 #(.els_p(tlb_els_p)
   ,.tag_width_p(vtag_width_p)
   ,.data_width_p(entry_width_lp)
   )
 cam
  (.clk_i(clk_i)
   ,.reset_i(reset_i)

   ,.w_v_i(v_i & w_i)
   ,.w_nuke_i(flush_i)
   ,.w_tag_i(vtag_i)
   ,.w_data_i(entry_i)

   ,.r_v_i(v_i & ~w_i)
   ,.r_tag_i(vtag_i)

   ,.r_data_o(entry_o)
   ,.r_v_o(r_v_lo)
   );

assign v_o        = r_v_r & r_v_lo;
assign miss_v_o   = r_v_r & ~v_o;

endmodule
