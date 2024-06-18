defmodule Split.TreatmentTest do
  use ExUnit.Case

  alias Split.Treatment

  describe "build_from_daemon_response/1" do
    test "builds a treatment struct from a daemon response" do
      treatment_payload = %{
        "t" => "treatment",
        "c" => nil,
        "l" => %{
          "l" => "label",
          "c" => 1,
          "m" => 2
        }
      }

      expected = %Treatment{
        treatment: "treatment",
        label: "label",
        config: nil,
        change_number: 1,
        timestamp: 2
      }

      assert expected == Treatment.build_from_daemon_response(treatment_payload)
    end

    test "builds a treatment struct with nil values" do
      treatment_payload = %{
        "t" => "treatment"
      }

      expected = %Treatment{
        treatment: "treatment",
        label: nil,
        config: nil,
        change_number: nil,
        timestamp: nil
      }

      assert expected == Treatment.build_from_daemon_response(treatment_payload)
    end
  end
end
