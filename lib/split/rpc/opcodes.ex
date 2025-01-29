defmodule Split.RPC.Opcodes do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @register_opcode 0x00
      @get_treatment_opcode 0x11
      @get_treatments_opcode 0x12
      @get_treatment_with_config_opcode 0x13
      @get_treatments_with_config_opcode 0x14
      @get_treatments_by_flag_set_opcode 0x15
      @get_treatments_with_config_by_flag_set_opcode 0x16
      @get_treatments_by_flag_sets_opcode 0x17
      @get_treatments_with_config_by_flag_sets_opcode 0x18
      @split_opcode 0xA1
      @splits_opcode 0xA2
      @split_names_opcode 0xA0
      @track_opcode 0x80

      @opcodes [
        @register_opcode,
        @get_treatment_opcode,
        @get_treatment_with_config_opcode,
        @get_treatments_opcode,
        @get_treatments_with_config_opcode,
        @get_treatments_by_flag_set_opcode,
        @get_treatments_with_config_by_flag_set_opcode,
        @get_treatments_by_flag_sets_opcode,
        @get_treatments_with_config_by_flag_sets_opcode,
        @split_opcode,
        @splits_opcode,
        @split_names_opcode,
        @track_opcode
      ]

      @status_ok 0x01
      @status_error 0x10
    end
  end
end
