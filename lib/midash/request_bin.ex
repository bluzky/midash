defmodule Midash.RequestBin do
  use GenServer

  @table :request_bin_store
  @max_requests 100
  @bin_ttl_ms :timer.hours(24)

  # --- Public API ---

  def start_link(_opts), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def create_bin do
    GenServer.call(__MODULE__, :create_bin)
  end

  def record_request(bin_id, attrs) do
    GenServer.call(__MODULE__, {:record_request, bin_id, attrs})
  end

  def get_requests(bin_id) do
    case :ets.lookup(@table, {:bin, bin_id}) do
      [{_, bin}] -> {:ok, bin.requests}
      [] -> {:error, :not_found}
    end
  end

  def list_bins do
    :ets.match_object(@table, {{:bin, :_}, :_})
    |> Enum.map(fn {{:bin, id}, bin} ->
      %{id: id, count: length(bin.requests), created_at: bin.created_at}
    end)
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
  end

  def delete_bin(bin_id) do
    GenServer.call(__MODULE__, {:delete_bin, bin_id})
  end

  # --- GenServer callbacks ---

  @impl true
  def init(_) do
    table = :ets.new(@table, [:named_table, :public, read_concurrency: true])
    schedule_cleanup()
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call(:create_bin, _from, state) do
    id = generate_id()
    bin = %{id: id, requests: [], created_at: DateTime.utc_now()}
    :ets.insert(@table, {{:bin, id}, bin})
    {:reply, id, state}
  end

  @impl true
  def handle_call({:record_request, bin_id, attrs}, _from, state) do
    case :ets.lookup(@table, {:bin, bin_id}) do
      [{key, bin}] ->
        req = Map.put(attrs, :id, generate_id()) |> Map.put(:inserted_at, DateTime.utc_now())
        requests = [req | bin.requests] |> Enum.take(@max_requests)
        updated = %{bin | requests: requests}
        :ets.insert(@table, {key, updated})
        Phoenix.PubSub.broadcast(Midash.PubSub, "bin:#{bin_id}", {:new_request, req})
        {:reply, :ok, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:delete_bin, bin_id}, _from, state) do
    :ets.delete(@table, {:bin, bin_id})
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cutoff = DateTime.add(DateTime.utc_now(), -@bin_ttl_ms, :millisecond)

    :ets.match_object(@table, {{:bin, :_}, :_})
    |> Enum.each(fn {{:bin, id}, bin} ->
      if DateTime.before?(bin.created_at, cutoff) do
        :ets.delete(@table, {:bin, id})
      end
    end)

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup, do: Process.send_after(self(), :cleanup, :timer.hours(1))

  defp generate_id do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end
end
