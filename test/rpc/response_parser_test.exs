defmodule Split.RPC.ResponseParserTest do
  use ExUnit.Case, async: false
  use Split.RPC.Opcodes

  alias Split.RPC.ResponseParser
  alias Split.RPC.Message
  alias Split.Treatment

  import ExUnit.CaptureLog

  describe "parse_response/2" do
    test "parses get_treatment RPC response" do
      message = %Message{
        o: @get_treatment_opcode,
        a: ["user_key", "bucketing_key", "feature_name"]
      }

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{"t" => "on", "l" => %{"l" => "test label", "c" => 123, "m" => 1_723_742_604}}
         }}

      assert ResponseParser.parse_response(response, message) ==
               {:ok,
                %Treatment{
                  change_number: 123,
                  config: nil,
                  label: "test label",
                  timestamp: 1_723_742_604,
                  treatment: "on"
                }}
    end

    test "parses get_treatment_with_config RPC response" do
      message = %Message{
        o: @get_treatment_with_config_opcode,
        a: ["user_key", "bucketing_key", "feature_name"]
      }

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "t" => "on",
             "l" => %{"l" => "test label", "c" => 123, "m" => 1_723_742_604},
             "c" => "{\"foo\": \"bar\"}"
           }
         }}

      assert ResponseParser.parse_response(response, message) ==
               {:ok,
                %Treatment{
                  change_number: 123,
                  config: "{\"foo\": \"bar\"}",
                  label: "test label",
                  timestamp: 1_723_742_604,
                  treatment: "on"
                }}
    end

    test "parses get_treatments RPC response" do
      message = %Message{
        o: @get_treatments_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"]]
      }

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "r" => [
               %{"t" => "on", "l" => %{"l" => "test label 1", "c" => 123, "m" => 1_723_742_604}},
               %{"t" => "off", "l" => %{"l" => "test label 2", "c" => 456, "m" => 1_723_742_604}}
             ]
           }
         }}

      assert ResponseParser.parse_response(response, message) ==
               {:ok,
                %{
                  "feature_name1" => %Split.Treatment{
                    treatment: "on",
                    label: "test label 1",
                    config: nil,
                    change_number: 123,
                    timestamp: 1_723_742_604
                  },
                  "feature_name2" => %Split.Treatment{
                    treatment: "off",
                    label: "test label 2",
                    config: nil,
                    change_number: 456,
                    timestamp: 1_723_742_604
                  }
                }}
    end

    test "parses get_treatments_with_config RPC response" do
      message = %Message{
        o: @get_treatments_with_config_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"]]
      }

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "r" => [
               %{
                 "t" => "on",
                 "l" => %{"l" => "test label 1", "c" => 123, "m" => 1_723_742_604},
                 "c" => "{\"foo\": \"bar\"}"
               },
               %{
                 "t" => "off",
                 "l" => %{"l" => "test label 2", "c" => 456, "m" => 1_723_742_604},
                 "c" => "{\"baz\": \"qux\"}"
               }
             ]
           }
         }}

      assert ResponseParser.parse_response(response, message) ==
               {:ok,
                %{
                  "feature_name1" => %Split.Treatment{
                    treatment: "on",
                    label: "test label 1",
                    config: "{\"foo\": \"bar\"}",
                    change_number: 123,
                    timestamp: 1_723_742_604
                  },
                  "feature_name2" => %Split.Treatment{
                    treatment: "off",
                    label: "test label 2",
                    config: "{\"baz\": \"qux\"}",
                    change_number: 456,
                    timestamp: 1_723_742_604
                  }
                }}
    end

    test "parses split RPC call" do
      message = %Message{o: @split_opcode, a: []}

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "n" => "feature_name",
             "t" => "user",
             "k" => false,
             "s" => [
               "treatment_a",
               "treatment_b",
               "treatment_c"
             ],
             "c" => 1_499_375_079_065,
             "f" => %{},
             "d" => "treatment_a",
             "e" => []
           }
         }}

      assert ResponseParser.parse_response(response, message) ==
               {:ok,
                %Split{
                  name: "feature_name",
                  traffic_type: "user",
                  killed: false,
                  treatments: ["treatment_a", "treatment_b", "treatment_c"],
                  change_number: 1_499_375_079_065,
                  configurations: %{},
                  default_treatment: "treatment_a",
                  flag_sets: []
                }}
    end

    test "parses splits RPC call" do
      message = %Message{o: @splits_opcode, a: []}

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "s" => [
               %{
                 "n" => "feature_a",
                 "t" => "user",
                 "k" => false,
                 "s" => [
                   "treatment_a",
                   "treatment_b",
                   "treatment_c"
                 ],
                 "c" => 1_499_375_079_065,
                 "f" => %{},
                 "d" => "treatment_a",
                 "e" => []
               },
               %{
                 "n" => "feature_b",
                 "t" => "user",
                 "k" => false,
                 "s" => [
                   "on",
                   "off"
                 ],
                 "c" => 1_499_375_079_066,
                 "f" => %{},
                 "d" => "off",
                 "e" => []
               }
             ]
           }
         }}

      # Order of splits is not guaranteed
      assert ResponseParser.parse_response(response, message) |> sorted_by(& &1.name) ==
               {:ok,
                [
                  %Split{
                    name: "feature_a",
                    traffic_type: "user",
                    killed: false,
                    treatments: ["treatment_a", "treatment_b", "treatment_c"],
                    change_number: 1_499_375_079_065,
                    configurations: %{},
                    default_treatment: "treatment_a",
                    flag_sets: []
                  },
                  %Split{
                    name: "feature_b",
                    traffic_type: "user",
                    killed: false,
                    treatments: ["on", "off"],
                    change_number: 1_499_375_079_066,
                    configurations: %{},
                    default_treatment: "off",
                    flag_sets: []
                  }
                ]}
    end

    test "parses split_names RPC call" do
      message = %Message{o: @split_names_opcode, a: []}

      response =
        {:ok,
         %{
           "s" => 1,
           "p" => %{
             "n" => [
               "feature_a",
               "feature_b"
             ]
           }
         }}

      assert ResponseParser.parse_response(response, message) ==
               {:ok, %{split_names: ["feature_a", "feature_b"]}}
    end

    test "parses successful track RPC call" do
      message = %Message{o: @track_opcode, a: []}

      response = {:ok, %{"s" => 1, "p" => %{"s" => true}}}

      assert ResponseParser.parse_response(response, message) == :ok
    end

    test "parses failed track RPC call" do
      message = %Message{o: @track_opcode, a: []}

      response = {:ok, %{"s" => 1, "p" => %{"s" => false}}}

      assert ResponseParser.parse_response(response, message) == :error
    end

    test "handles splitd internal error" do
      message = %Message{
        o: @get_treatments_with_config_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"]]
      }

      response = {:ok, %{"s" => 0x10, "p" => %{"m" => "Some bad error"}}}

      assert capture_log(fn ->
               assert ResponseParser.parse_response(response, message) ==
                        {:error, :splitd_internal_error}
             end) =~ "Error response received from Splitd"
    end

    test "handles unknow/unparsable payload" do
      message = %Message{
        o: @get_treatments_with_config_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"]]
      }

      response = {:ok, "some bad payload"}

      assert capture_log(fn ->
               assert ResponseParser.parse_response(response, message) ==
                        {:error, :splitd_parse_error}
             end) =~ "Unable to parse Splitd response"
    end

    test "handles socket errors" do
      message = %Message{
        o: @get_treatments_with_config_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1", "feature_name2"]]
      }

      response = {:error, :enoent}

      assert capture_log(fn ->
               assert ResponseParser.parse_response(response, message) ==
                        {:error, :enoent}
             end) =~ "Error while communicating with Splitd"
    end
  end

  describe "parse_response/2 with fallback enabled" do
    setup do
      old_value = :persistent_term.get(:splitd_fallback_enabled)
      :persistent_term.put(:splitd_fallback_enabled, true)
      on_exit(fn -> :persistent_term.put(:splitd_fallback_enabled, old_value) end)
    end

    test "returns fallback for the sent message on invalid splitd response" do
      message = %Message{o: @split_opcode, a: []}

      response = {:ok, "some bad payload"}

      assert capture_log(fn ->
               assert ResponseParser.parse_response(response, message) ==
                        {:ok, nil}
             end) =~ "Unable to parse Splitd response"
    end

    test "returns fallback for the sent message on splitd internal error" do
      message = %Message{
        o: @get_treatment_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1"]]
      }

      response = {:ok, %{"s" => 0x10, "p" => %{"m" => "Some bad error"}}}

      assert capture_log(fn ->
               assert ResponseParser.parse_response(response, message) ==
                        {:ok,
                         %Split.Treatment{
                           change_number: nil,
                           config: nil,
                           label: nil,
                           timestamp: nil,
                           treatment: "control"
                         }}
             end) =~ "Error response received from Splitd"
    end

    test "returns fallback for the sent message on socket error" do
      message = %Message{
        o: @get_treatments_with_config_opcode,
        a: ["user_key", "bucketing_key", ["feature_name1"]]
      }

      response = {:error, :enoent}

      assert capture_log(fn ->
               assert ResponseParser.parse_response(response, message) ==
                        {:ok,
                         %{
                           "feature_name1" => %Split.Treatment{
                             treatment: "control",
                             label: nil,
                             config: nil,
                             change_number: nil,
                             timestamp: nil
                           }
                         }}
             end) =~ "Error while communicating with Splitd"
    end
  end

  defp sorted_by(response, fun) do
    response
    |> elem(1)
    |> Enum.sort_by(fun)
    |> then(&{:ok, &1})
  end
end
