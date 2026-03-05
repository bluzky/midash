defmodule MidashWeb.Widgets.QuickNoteWidget do
  use MidashWeb, :live_component

  @store_key :content

  @impl true
  def mount(socket) do
    {:ok, assign(socket, editing: false, content: "", draft: "")}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Only load from store on first mount, not on subsequent re-renders,
    # so in-progress edits and saved state are not overwritten.
    socket =
      if socket.assigns[:loaded] do
        socket
      else
        content = Midash.Store.get(store_id(socket.assigns.id), @store_key, "")
        assign(socket, loaded: true, content: content, draft: content)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    {:noreply, assign(socket, editing: true, draft: socket.assigns.content)}
  end

  def handle_event("update_draft", %{"draft" => value}, socket) do
    {:noreply, assign(socket, draft: value)}
  end

  def handle_event("save", _params, socket) do
    Midash.Store.put(store_id(socket.assigns.id), @store_key, socket.assigns.draft)
    {:noreply, assign(socket, editing: false, content: socket.assigns.draft)}
  end

  def handle_event("clear", _params, socket) do
    Midash.Store.delete(store_id(socket.assigns.id), @store_key)
    {:noreply, assign(socket, editing: false, content: "", draft: "")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full min-h-[120px] relative">
      <%= if @editing do %>
        <form phx-change="update_draft" phx-target={@myself}>
          <textarea
            id={"#{@id}-textarea"}
            phx-hook="FocusOnMount"
            name="draft"
            phx-target={@myself}
            phx-blur="save"
            rows="8"
            class="w-full bg-transparent text-sm text-foreground placeholder-muted-foreground resize-none outline-none border-0 ring-0 focus:ring-0 focus:border-0 leading-relaxed p-0"
            placeholder="Type a note..."
          ><%= @draft %></textarea>
        </form>
      <% else %>
        <div
          phx-click="edit"
          phx-target={@myself}
          class="cursor-pointer"
        >
          <%= if @content == "" do %>
            <p class="text-sm text-muted-foreground italic">click to add a note...</p>
          <% else %>
            <p class="text-sm text-foreground whitespace-pre-wrap leading-relaxed pb-6">{@content}</p>
          <% end %>
        </div>
        <button
          :if={@content != ""}
          phx-click="clear"
          phx-target={@myself}
          class="absolute bottom-0 right-0 text-xs text-muted-foreground hover:text-destructive transition-colors"
        >
          clear
        </button>
      <% end %>
    </div>
    """
  end

  defp store_id(id), do: :"quick_note_#{id}"
end
