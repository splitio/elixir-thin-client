defmodule Split.ImpressionTest do
  use ExUnit.Case

  alias Split.Impression

  describe "build_from_daemon_response/1" do
    test "builds an impression struct from a daemon response" do
      treatment_payload = %{
        "t" => "treatment",
        "c" => "{\"field\": \"value\"}",
        "l" => %{
          "l" => "label",
          "c" => 1,
          "m" => 2
        }
      }

      expected = %Impression{
        key: "user_key",
        bucketing_key: "bucketing_key",
        feature: "feature_name",
        treatment: "treatment",
        label: "label",
        config: "{\"field\": \"value\"}",
        change_number: 1,
        timestamp: 2
      }

      assert expected ==
               Impression.build_from_daemon_response(
                 treatment_payload,
                 "user_key",
                 "bucketing_key",
                 "feature_name"
               )
    end

    test "builds an impression struct with nil values" do
      treatment_payload = %{
        "t" => "treatment"
      }

      expected = %Impression{
        key: "user_key",
        bucketing_key: nil,
        feature: "feature_name",
        treatment: "treatment",
        label: nil,
        config: nil,
        change_number: nil,
        timestamp: nil
      }

      assert expected ==
               Impression.build_from_daemon_response(
                 treatment_payload,
                 "user_key",
                 nil,
                 "feature_name"
               )
    end
  end
end
