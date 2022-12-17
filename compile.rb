include_directory '.'

[
  'rggen_or_reducer.v',
  'rggen_mux.v',
  'rggen_bit_field.v',
  'rggen_bit_field_w01trg.v',
  'rggen_address_decoder.v',
  'rggen_register_common.v',
  'rggen_default_register.v',
  'rggen_external_register.v',
  'rggen_indirect_register.v',
  'rggen_adapter_common.v',
  'rggen_apb_adapter.v',
  'rggen_apb_bridge.v',
  'rggen_axi4lite_skid_buffer.v',
  'rggen_axi4lite_adapter.v',
  'rggen_axi4lite_bridge.v',
  'rggen_wishbone_adapter.v',
  'rggen_wishbone_bridge.v'
].each { |file| source_file file }
