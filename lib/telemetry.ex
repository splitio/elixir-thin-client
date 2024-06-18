defmodule Split.Telemetry do
  alias Split.Treatment

  def send_impression(user_key, feature_name, %Treatment{} = treatment) do
    :telemetry.execute([:split, :impression], %{}, %{
      impression: %Split.Impression{
        key: user_key,
        feature: feature_name,
        treatment: treatment.treatment,
        label: treatment.label,
        change_number: treatment.change_number,
        timestamp: treatment.timestamp
      }
    })
  end
end
