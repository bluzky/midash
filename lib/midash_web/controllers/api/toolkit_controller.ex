defmodule MidashWeb.API.ToolkitController do
  use MidashWeb, :controller

  def execute(conn, params) do
    code = Map.get(params, "code", "")
    input = Map.get(params, "input", "")

    case run_elixir(input, code) do
      {:ok, output} -> json(conn, %{output: output})
      {:error, message} -> json(conn, %{error: message})
    end
  end

  def barcode(conn, params) do
    codes = Map.get(params, "codes", [])

    results =
      Enum.map(codes, fn value ->
        case Barlix.Code128.encode(value) do
          {:ok, code} ->
            {:ok, svg} = Barlix.SVG.print(code, xdim: 2, height: 80)
            %{value: value, svg: svg, error: nil}

          {:error, reason} ->
            %{value: value, svg: nil, error: inspect(reason)}
        end
      end)

    json(conn, %{data: results})
  end

  def mau(conn, params) do
    template = Map.get(params, "template", "")
    raw_params = Map.get(params, "params", "{}")

    case Jason.decode(raw_params) do
      {:ok, context} ->
        case Mau.render(template, context) do
          {:ok, output} -> json(conn, %{output: output})
          {:error, err} -> json(conn, %{error: inspect(err)})
        end

      {:error, err} ->
        json(conn, %{error: "Invalid JSON: #{Exception.message(err)}"})
    end
  end

  def map_to_json(conn, params) do
    input = Map.get(params, "input", "")

    case eval_map(input) do
      {:ok, value} ->
        case Jason.encode(value, pretty: true) do
          {:ok, json_str} -> json(conn, %{output: json_str})
          {:error, err} -> json(conn, %{error: "JSON encode error: #{inspect(err)}"})
        end

      {:error, msg} ->
        json(conn, %{error: msg})
    end
  end

  defp run_elixir(input, code) do
    binding = [input: input]
    {result, _} = Code.eval_string(code, binding)
    {:ok, Kernel.inspect(result)}
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp eval_map(input) do
    {value, _} = Code.eval_string(input, [])
    {:ok, value}
  rescue
    e -> {:error, Exception.message(e)}
  end
end
