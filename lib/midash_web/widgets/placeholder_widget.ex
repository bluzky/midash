defmodule MidashWeb.Widgets.PlaceholderWidget do
  use MidashWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center h-full text-muted-foreground italic text-sm">
      {Map.get(assigns, :message, "Widget coming soon")}
    </div>
    """
  end
end
